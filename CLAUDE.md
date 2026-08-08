# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## Overview

Clang.jl is a **C-header-to-Julia binding generator**. `create_context(headers, args, options)`
then `build!(ctx)` emits a `.jl` file of `ccall` wrappers, structs, enums, constants and macros.
That is the whole package.

It used to be two things stacked on one another — a libclang binding plus a generator built on
top of it — and most documentation you will find elsewhere still describes that. The libclang
layer is gone. See [the rework](#the-rework-what-changed-and-why) below, because a surprising
amount of the design only makes sense once you know what it replaced.

## Commands

```bash
# Run the full test suite (this is what CI runs)
julia --project -e 'using Pkg; Pkg.test()'

# Build the docs
julia --project=docs docs/make.jl
```

There is no formatter configuration and nothing in CI runs one; match the surrounding file.

### Running one test file

Test files are not self-contained — they rely on the test environment (`Test`, `TOML`,
`CMake_jll`, `CEnum`, `REPL`, `ClangCompiler` are in `test/Project.toml`, not the main project).
Use TestEnv:

```bash
julia --project -e 'using TestEnv; TestEnv.activate(); include("test/abi.jl")'
```

**Piping hides failures.** `julia ... 2>&1 | tail -20; echo $?` reports *tail's* status.
Redirect to a file and grep it.

## Architecture

Three stages over plain data, plus macros. Nothing downstream of the first holds a clang handle,
which is what lets the last two be tested without a compiler.

| File | Module | Role |
| --- | --- | --- |
| `src/generator/facts.jl` | `CxxFacts` | **extract** — one reachability walk over the AST → nodes of facts |
| `src/generator/order.jl` | `CxxOrder` | **order** — emission order + the cuts a genuine cycle forces |
| `src/generator/emit.jl` | `CxxEmit` | **emit** — facts → Julia |
| `src/generator/macros.jl` | `CxxMacros` | each `#define` probed as C; the typed AST is translated |
| `src/generator/Generators.jl` | `Generators` | the public API: `create_context`, `build!`, … |
| — | `JLLEnvs` | **ClangCompiler's internal module**, reached through a trampoline — see below |

### The platform trampoline

The GCC-shard machinery is `ClangCompiler.JLLEnvs`, which is *internal to that package* and
deliberately not public API. It is treated as stable. Clang.jl does not re-export it as its own
surface; it exposes a trampoline — `JLL_ENV_TRIPLES` and `get_pkg_include_dir` — so downstream
generator scripts depend on names this package promises. If `JLLEnvs` moves, only those lines
change.

Keep the trampoline **smaller than what is available**, and only promise what is true. Two
things were learned by writing it wrong first:

- `get_environment_info` is deliberately *not* trampolined. Its `version` defaults to
  `GCC_MIN_VER`, which is wrong for any target whose only shard is newer —
  `get_environment_info("aarch64-apple-darwin20")` throws `KeyError`. Promising it would mean
  promising a version-lookup rule we do not own.
- `get_pkg_include_dir` returns where headers *would* be, not a directory that exists: a JLL can
  ship an artifact with no `include/`, and `CMake_jll`'s linux build does. It validates the
  triple at the boundary, because upstream otherwise fails with `Unknown OS` from inside a
  platform parse.

`test/jllenvs.jl` exercises the trampoline rather than `JLLEnvs` directly — testing the
implementation would pass while the public surface was broken. It also avoids calling
`get_default_args` for all 14 triples: that materialises a GCC bootstrap shard each, and took
2m32s here with them already cached.

### The data model

```julia
struct Node
    key::Key              # clang's decl identity (getCanonicalDecl), stable for one ASTContext
    id::Symbol            # the C name
    facts::DeclFacts      # RecordFacts | EnumFacts | TypedefFacts | FunctionFacts
    file::String; line::Int
    system::Bool; anonymous::Bool; typedef_name::Symbol
    doc::String           # raw comment text, "" unless comments were requested
end
```

A `RecordFacts` carries clang's `ASTRecordLayout` — **field offsets in bits**, size and
alignment in bytes — so codegen never re-queries the AST. `TypeRef` is a small frontend-neutral
tree (`PointerRef`, `ArrayRef`, `RecordRef`, `TypedefRef`, …).

There is no DAG, no `node.adj`, no pass vector, and no node-type marker taxonomy. Ordering is
recomputed from the facts at emission time, so nothing is invalidated by inserting or reordering.

### Two invariants worth knowing before you change anything

1. **`deps` describes the Julia that will be emitted, not the C that was read.** Every function
   type is emitted as `Ptr{Cvoid}`, so `deps!` deliberately does not descend into a `FunctionRef`
   — doing so invented five dependencies for a line reading `const X = Ptr{Cvoid}`, one of which
   closed a cycle that then could not be broken. Anything looser and ordering invents constraints
   that no Julia expression has; anything tighter and it emits a name before its definition.

2. **A cut is decided and applied in one place.** `CxxOrder` records the broken edge *and* the
   field it degraded together (`Cut`), and `emit_record` is the only thing that realises it. In
   the old pipeline the edge was deleted in one pass and whether to erase the field was decided
   later by an index comparison, so the two could disagree.

### Blobbing

A record whose natural Julia layout matches clang's is emitted as a plain struct with named,
typed fields. Anything clang lays out differently — a bit-field, `packed`, an unnamed member, or
**a field whose type we could not name** — falls back to opaque bytes plus generated accessors.
Blobbing is a fallback, never the default.

The blob's storage is a tuple of the widest unsigned that divides the size (`blob_storage`), not
`NTuple{N,UInt8}`: Julia gives a struct the maximum alignment of its fields, so a byte tuple
silently under-aligns every blobbed record. The libclang generator has the same bug and cannot
see it — it never calls `getAlignOf`.

**The "clang lays it out differently" test replays clang's numbers; it does not look for an
attribute.** `naturally_laid_out` walks the fields with clang's own per-field size and alignment
and checks the result against clang's actual offsets and total size. The attribute route is a
trap: `packed` comes from `hasAttrOfKind(CXAttrKind_Packed)`, which sees
`__attribute__((packed))` and **not** `#pragma pack(n)` — clang models that as
`MaxFieldAlignmentAttr`. A `#pragma pack(1)` record was emitted as a plain struct at 8 bytes
where clang said 5. Replaying the numbers closes packed, `#pragma pack`, over-aligned members
and `aligned(N)` at once, with nothing to keep in sync with clang's attribute taxonomy.

## Testing: what is actually pinned

`test/runtests.jl` runs eight testsets, 170 tests.

- **`test/abi.jl` is the strongest and the one to run before claiming anything.** It compares
  every emitted type against the `ASTRecordLayout` clang computed for that same declaration —
  `sizeof`, `datatype_alignment`, every `fieldoffset`. No recorded baseline, so it works on any
  corpus. Five corpora: `synthetic`, `fixtures`, libxml2, glib, pango — 341 records and 1517
  field offsets. Third-party corpora skip loudly when their artifacts are absent.
- `test/generators.jl` — every fixture in `test/include/` **generates and loads**. Most old
  testsets asserted only that `build!` logged `"Done!"`, which cannot see a file that fails to
  load.
- `test/ordering.jl` — cycles are cut, and cut minimally.
- `test/macros.jl` — macro values against what a C compiler gives, including issues #510 and
  #382, which were `@test_broken` for the token-based translator.
- `test/options.jl` — each of the 32 options has an observable effect. **Each is checked in
  isolation, so no pair is known to compose.**
- `test/test_bitfield.jl` — CMake-builds `test/bitfield/bitfield.c` and round-trips a bitfield
  struct through the real compiled library. Swallows failures with a `@warn` unless `ENV["CI"]`
  is set, so run it with `CI=true` when you care.

An assertion on anything the *runner* decides — pointer width, `Clong`, path separators — is
invisible locally and red on CI.

**`ClangCompiler` is a test dependency on purpose.** Nothing under `test/` imports it directly —
it is reached through `Clang.Generators`. But `ClangCompiler.JLLShim.__init__` calls
`Preferences.has_preference("ClangCompiler", "libclangex")`, which resolves the package **by name
in the active load path**, and `Pkg.test` builds a temp environment where an indirect dependency
is not top-level. Drop the entry and `Pkg.test()` dies with `Cannot resolve package
'ClangCompiler' in load path` before a single test runs — verified by removing it. The real fix
is upstream (`@has_preference`, or the UUID form, consults no load path); until then the entry
stays.

## The option contract

`load_options` is `TOML.parse` with no schema and no validation, so a misspelled key is silently
inert. `Options(dict)` reads the 32 keys it knows from `[general]`, `[codegen]` and
`[codegen.macro]` and ignores everything else — see [CXX-FRONTEND.md](CXX-FRONTEND.md) for the
list and which table each lives in (they are not where you would guess: `skip_static_functions`
and `library_names` are `[general]`).

Three keys have silent legacy aliases: `output_ignorelist` ← `printer_blacklist`,
`auto_mutability_ignorelist` ← `auto_mutability_blacklist`, `auto_mutability_includelist` ←
`auto_mutability_whitelist`.

`callback_documentation` has no TOML spelling — it is a Julia `Function` a caller pokes into the
options dict beside the scalars. `test/test_mpi.jl` does this.

## The rework: what changed, and why

The full argument is in [GENERATORS-REWORK.md](GENERATORS-REWORK.md) and
[ORDERING-DESIGN.md](ORDERING-DESIGN.md); the short version:

libclang parses **each header into its own translation unit** and offers no primitive that says
a cursor in TU 1 and a cursor in TU 2 are the same C entity. Roughly two thirds of the old
21-pass pipeline existed to re-derive that by comparing file/line/column and then token text, to
re-key the graph on `Symbol` names, and to string-sniff `occursin("(anonymous", spelling(x))`.
Parsing all headers into one `ASTContext` and keying on `getCanonicalDecl` makes every one of
those questions a direct query, so the passes did not get better — they stopped existing.

**libclang and clang-cpp cannot share a process.** Both statically register LLVM's global
command-line options, so loading the second aborts with `Option 'sanitizer-early-opt-ep'
registered more than once!`, in either order. This is why the C++ frontend could not be a package
extension and why the libclang layer had to go rather than stay alongside.

The libclang layer is **gone from the tree**, not merely unreferenced: `lib/16…21/` (45,605
generated lines), `gen/`, and the eleven `src/` object-layer files (`cursor.jl`, `type.jl`,
`cltypes.jl`, `trans_unit.jl`, …). If you are looking for `CLCursor`, `parse_headers` or
`@add_def`, they were removed in v0.20 — `git log -- src/cursor.jl` still has them, and
`Clang@0.19` is the last release that shipped them.

### The platform environment is ClangCompiler's, not ours

`src/platform/` used to be a 436-line fork of ClangCompiler's `src/platform/`, beside a
byte-identical 137 KB `Artifacts.toml` (262 GCC shard entries). The only drift that had
accumulated in a year was comma spacing in `system.jl`. Both are gone; `Clang.JLLEnvs` is
`ClangCompiler.JLLEnvs`.

Two things not to "simplify" further:

- **`Generators.get_default_args` is ours and must stay.** ClangCompiler exports a function of
  the same name that is *not* a drop-in: it defaults to `is_cxx=true`, takes `triple` as a
  keyword rather than positionally, and appends `-nostdinc++ -nostdlib++ -nostdinc -nostdlib
  -xc++`. Swapping them would silently reparse every downstream generator run as C++ with the
  system include paths stripped.
- **`JLLEnvs` is not in `names(ClangCompiler)`.** It is reachable but undocumented, so this
  trades a maintained fork for a coupling to an internal submodule. That is the better trade —
  a fork of artifact hashes rots silently — but it should be marked public upstream.

Objective-C is unsupported, blocked on ClangCompiler#49.

## Conventions

- The frontend uses **clang's own C++ names** for anything wrapping a clang API
  (`getCanonicalDecl`, `getUnqualifiedType`, `isInSystemHeader`) and snake_case for its own
  helpers (`order_nodes`, `blob_storage`, `leaf_record`).
- Comments explain *why*, and especially what went wrong: several carry a specific defect
  (`_Nullable` making a field zero-sized, glib naming a parameter `tm`, a `const int` field
  missing the builtin table). Those are the comments most worth keeping accurate.
- When a check has never failed, make it fail on purpose before trusting it. Every check in
  `test/abi.jl` has been fault-injected.
