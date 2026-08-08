# Reworking `Generators` on Clang's C++ API

**Status**: libclang is being dropped entirely — see §0, which supersedes §3. The macro slice is
implemented ([MACRO-HANDLING.md](MACRO-HANDLING.md)); the ordering design is settled
([ORDERING-DESIGN.md](ORDERING-DESIGN.md)).
**Companion**: [CLAUDE.md](CLAUDE.md) describes the pipeline as it stands today.

---

## 0. DECISION: libclang is dropped; ClangCompiler is the only backend

Taken 2026-08-07. **Clang.jl depends on ClangCompiler exclusively.** There is no second
frontend, no package extension, no package split, and no out-of-process arrangement.

This retires most of §3 below, which was written to reconcile two coexisting backends:

| section | status |
| --- | --- |
| §3.1 version reach | **accepted as a cost**, not a constraint to design around |
| §3.2 bootstrap relationship | still real, but simpler — see below |
| §3.3 package extension | already retracted; now moot |
| §3.4 one LLVM per process | **resolved** — only ClangCompiler loads an LLVM |
| §3.5 why this is a refactor not a repackaging | moot; there is nothing to separate |

### What it resolves

The blocking constraint was that Clang.jl and ClangCompiler cannot share a process, because
both statically register LLVM's global CommandLine options. With libclang gone there is one
LLVM in the process and the conflict disappears. ClangCompiler's own `gen/` environment then
loads `Clang` → `ClangCompiler`, a single LLVM, and works.

The bootstrap relationship survives in a milder form: regenerating ClangCompiler's bindings
needs Clang.jl, which needs a *released* ClangCompiler. Routine, but a simultaneous breaking
change in both packages is a two-step release.

### What it costs — accepted, not solved

1. **LLVM 18 only.** Clang.jl currently spans LLVM 16–21 through six `lib/` directories and
   `Clang_unified_jll`'s own libclang. ClangCompiler is pinned to the LLVM Julia itself is built
   against. Users lose the ability to choose the parsing clang version independently of their
   Julia.
2. **Julia 1.12+**, up from 1.11.
3. **The exported libclang API goes.** Not just the generator: 44 exported names —
   `CLCursor`, `CLType`, `CLToken`, `Index`, `TranslationUnit`, `parse_header`, `parse_headers`,
   `tokenize`, `TokenList`, `CLCompilationDatabase`, `children`, `search`, `spelling`, `kind`,
   `fields`, … — are public surface today. Anyone using Clang.jl *as a libclang binding* rather
   than as a generator is broken by this. It is a major version bump.
4. **Objective-C stops working** until [ClangCompiler#49](https://github.com/Gnimuc/ClangCompiler.jl/issues/49).
   `clang/AST/DeclObjC.h` is unwrapped in full — no ObjC `Decl` carriers exist at all, and
   `src/clang/DeclKindMap.jl:3` says so. The macOS-only ObjC testset must be disabled in the
   interim.

### What it deletes

| | lines |
| --- | --- |
| hand-written libclang object layer (`cursor.jl`, `type.jl`, `cltypes.jl`, `trans_unit.jl`, `token.jl`, `index.jl`, `file.jl`, `module.jl`, `compiledb.jl`, `dump.jl`, `string.jl`) | ~2,060 |
| generated bindings `lib/16…21/LibClang.jl` | ~45,600 |

### What it does to the pipeline

Passes 2–8 of [ORDERING-DESIGN.md](ORDERING-DESIGN.md) §3.2b exist only to reconstruct, by name,
what libclang cannot hand over: the typedef↔anonymous-tag link, a Symbol index, cross-TU
duplicate marking, dependent system nodes, nested-record discovery, and opaque detection. Every
one is answered directly by the AST — demonstrated by a reachability walk that finds a nested
`struct Inner`, an anonymous record named by its typedef, and an undefined forward declaration,
keyed on `decl_id` with no index and no duplicates.

**The pipeline becomes roughly five passes:**

```
1  Extract    one reachability walk over the AST -> nodes (facts) + edges (decl_id)
2  Order      DFS -> emission order + cut set          (ORDERING-DESIGN.md §3.2)
3  Codegen    + CodegenMacro, AddFPtrMethods, TweakMutability
4  Verify     definition-time symbol check             (ORDERING-DESIGN.md §3.4)
5  Print
```

`decl_id` **is** the stable key ORDERING-DESIGN.md §3.2b asks for, so that design converges
rather than being replaced. What does *not* carry over is anything libclang-specific: the
15→11 pass reduction, the splicing fix (§3.3 — the AST walk never appends), and the
`IndexDefinition` split. Those should not be built.

### §0.1 Switchover: what must land first

The new pipeline is ABI-correct on the fixture corpus but **not feature-equivalent**, and the
gap is breadth rather than depth. Switching `src/` over now would break both real consumers.

**Option surface — 0 of 40 implemented.** `gen/generator.toml` (Clang.jl's own) sets 40 keys;
ClangCompiler's `gen/option.toml` sets 10. The new emitter honours none: it hardcodes the
library name, always writes `using CEnum`, and has no module wrapper, prologue, epilogue,
ignorelist, export prefixes, record constructors or comment styles. This is the compatibility
contract and it is the bulk of the remaining work.

**Macros are not wired in.** `CxxMacros` works standalone; `generate` never calls it, so no
`#define` reaches the output.

**Skipped, not translated:** variadic functions, `static` functions, docstrings.

#### The bootstrap is not a gate — ClangCompiler pins the old generator

An earlier draft of this section claimed that regenerating ClangCompiler's own
`lib/18/LibClangEx.jl` was a release gate for the switchover, because the new Clang.jl depends
on ClangCompiler. **That was wrong.**

`ClangCompiler/gen/generator.jl` loads only `Clang.Generators` — never `ClangCompiler` itself —
and its `gen/Project.toml` has exactly two dependencies, `BinaryBuilderBase` and `Clang`. So
that environment can pin `Clang = "0.19"`, the last libclang-based release, indefinitely:

- the gen process loads libclang **alone**, so there is no LLVM CommandLine conflict (§3.4);
- ClangCompiler stays regenerable forever, independent of what Clang.jl does next;
- and there is no circularity to manage at release time.

The same reasoning removes Clang.jl's *own* self-hosting from the picture. That exists solely to
produce `lib/<n>/LibClang.jl` — its libclang bindings. Once libclang goes, those bindings go
with it, and `gen/generator.jl` and `gen/generator.toml` are deleted alongside `lib/16…21/`.
**Neither package needs the new generator to bootstrap itself.**

#### What that leaves as the acceptance test

Not self-hosting — there is nothing left to self-host. The question is whether the new pipeline
still serves *downstream* users' `generator.toml` files, and the only honest test is real
third-party header sets run end-to-end and loaded. libxml2 already orders (§ORDERING-DESIGN);
glib and pango are the other forward-declaration-heavy corpora available locally.

This also redirects the option work: its priority order should come from surveying what real
downstream generator scripts set, not from ClangCompiler's ten keys, which now gate nothing.

#### Sequence

| step | state | gate |
| --- | --- | --- |
| S-A | **done** — 32 keys | `test/options.jl`, 53 checks |
| S-B | **done** | `test/macros.jl`, 25 checks, including both `@test_broken`s |
| S-C | **done** — libxml2, glib, pango | `test/abi.jl`: 341 records, 1517 field offsets vs clang |
| S-D | **done** | full suite green — 170 tests |
| S-E | **done** — v0.20.0 | six-lens reference audit, 94 findings, 0 blockers; suite 170/170 after |

**The sequence is complete.** S-E removed `lib/16…21/` (45,605 generated lines), `gen/`, the
eleven `src/` object-layer files, and `test/test.toml`, the config the deleted self-hosting
testset used.

Unimplemented from the ~45-key surface, all deliberately: `output_exclusivelist`,
`function_argument_conflict_symbols` (subsumed — `argnames` renames on real collision, not from
a list), `union_single_constructor`, `link_enum_alias`, `no_audit`, and the `[general.log]`
sub-table of 23 per-pass booleans, which has no meaning once there are no passes.

S-E was the only irreversible step and it came last — the reason being narrower than the earlier
draft claimed. Not that bindings become unregenerable; simply that once the libclang path is gone
there is no fallback if S-C turned up something the fixtures missed. It did not.

#### S-E: what the audit checked before deleting

Six independent reference sweeps, each blind to the others: Julia source (`include`, `using`, and
every symbol the targets define); build and CI config; prose; the test suite and its fixtures; a
**symbol-level set difference** built by construction rather than by grep — 2,086 defined names
against 1,049 referenced ones, which is the only lens that can catch a collision on a name as
generic as `name`, `kind`, `file` or `fields`; and an empirical load check. Every claim that
deletion would break something was then handed to a separate agent told to refute it.

94 references found, **0 blockers**. The 20-name symbol intersection resolved entirely to
*independent definitions in the new code* — `UnknownRef.spelling`, `RecordFacts.file`,
`RecordFacts.fields` — not calls into the object layer.

The strongest evidence was a differential: the three groups were physically moved out of the
tree, the suite run, the groups moved back, the suite run again. The two logs are byte-identical
apart from a `dlopen` handle address. Deleting them is observationally null.

Two things the deletion made possible rather than merely permitted:

- **`CEnum` left `[deps]`.** Its only real importer was `src/cltypes.jl`. Surviving code never
  imports CEnum — it only *writes the string* `using CEnum: CEnum, @cenum` into generated
  output, which is the caller's `using` in the caller's environment.
- **`Downloads`** was already a dependency with zero uses anywhere in the repository.

#### S-C: done, and what it cost

All three corpora now generate, load, and match clang's layout:

| corpus | nodes | records checked | field offsets checked |
| --- | --- | --- | --- |
| synthetic + fixtures (27 headers) | — | 51 | 60 |
| libxml2 | 2015 | 58 | 684 |
| glib | 2788 | 65 | 197 |
| pango | 4349 | 167 | 576 |

The verifier is `cxx/validate_abi.jl`, and it is a different instrument from
`test/abi_baseline.jl`. The baseline compares against the **old generator's recorded output**,
which can only certify that we reproduce whatever libclang produced, bugs included — and it is
silent on any corpus the old generator cannot process, which is exactly the interesting set.
`validate_abi.jl` compares every emitted type against the `ASTRecordLayout` clang computed for
that same declaration: `sizeof`, `datatype_alignment`, and every `fieldoffset`. That needs no
recorded baseline, so it scales to any header set.

It found four defects that every other check passed:

1. **Every blobbed record was under-aligned.** `NTuple{N,UInt8}` reproduces clang's *size* but
   has alignment 1, and a Julia struct takes the maximum alignment of its fields. Fixed by
   storing the same bytes as a tuple of a wider unsigned (`blob_storage`). The libclang
   generator has the identical bug and structurally cannot see it: it never calls `getAlignOf`.
2. **`_Nullable` silently corrupted layouts.** clang wraps such a pointer in an `AttributedType`,
   which `typeref` did not unwrap, so the field became `UnknownRef` → `Cvoid` — and a `Cvoid`
   field is *zero-sized* in Julia. macOS's `FILE` came out 120 bytes instead of 152 with nine
   fields at the wrong offset. Fixed generically with one `getSingleStepDesugaredType` step,
   plus a safety net: a record with any unnameable field type now falls back to the blob form,
   so an unrecognised type can never again shift a layout silently.
3. **The dependency graph described C, not the Julia being emitted.** `deps` descended into
   function types, so `xmlDOMWrapAcquireNsFunction` claimed five dependencies for a line that
   reads `const xmlDOMWrapAcquireNsFunction = Ptr{Cvoid}` — one of which closed a cycle that
   then could not be broken, because there was no real edge there to cut. Every function type is
   emitted as `Ptr{Cvoid}`, so it constrains nothing.
4. **A parameter can shadow its own signature.** glib's `g_date_to_struct_tm(GDate*, struct tm*)`
   names its second parameter `tm`, giving `ccall(..., (Ptr{GDate}, Ptr{tm}), date, tm)` — Julia
   rejects the file. Parameters are now renamed only where they actually collide.

Defects 1–3 are ABI-silent: the file loads, every call type-checks, and the memory is wrong.
Nothing short of comparing against the compiler's own layout would have caught them, which is
the argument for keeping `validate_abi.jl` as the release gate rather than the baseline.

#### S-B: done

`CxxMacros` is wired into `generate` behind `macro_mode` (`"basic"` | `"disable"`), emitted after
every declaration — nothing declared can name a macro, since clang expands them before anything
reaches the AST, so that is the one position needing no ordering analysis. Two guards apply:
a macro naming something the file will not define is skipped (the `UndefVarError` class
`test/macros.jl` pins), and a macro is never emitted over a declaration of the same name.
Symbols are first rewritten through codegen's own name map, so a macro mentioning `uint32_t`
becomes `UInt32` rather than being dropped as unresolvable.

`cxx/validate_macros.jl` is `test/macros.jl` run through the new backend: 25 assertions, all
passing, **including the two `@test_broken`s**. `((INT) 4+1)` is 5 and `((MPI_Datatype)0x8c000000)`
is -1946157056, which is what `cc` gives. Those flip to Unexpected Pass in the suite at S-D.

Running it over the corpora found four more defects, three of them silent:

1. **`(const xmlChar *) "http://…"` became `Ptr{Cvoid}("http://…")`** — a `MethodError` at load,
   which took libxml2 down entirely. A string cast to a pointer is just the string.
2. **The verifier only ran when clang folded to an integer**, so every string- and pointer-valued
   macro went out unchecked — including the one above. It now evaluates every translation and
   rejects any that throws; a fold is extra evidence when available, not the precondition.
3. **Unary opcodes were compared as bare integers.** The values were right, but `getOpcode`
   returns a `CXUnaryOperatorKind` and a Julia `@enum` does not compare equal to an `Integer`,
   so *every negative constant in every corpus was silently skipped*. glib's `G_MININT`,
   `G_MINLONG`, `G_MININT64` all vanished with no symptom but a lower count.
4. **The fold was read at the wrong signedness.** `G_MAXUINT` translated correctly to 4294967295
   and was compared against a fold of -1, so the verifier rejected eight correct macros. Skipping
   a correct macro is the safe failure direction, which is precisely why it stayed invisible
   until the skip reasons were counted rather than just totalled.

Translation rates: libxml2 132/207, glib 268/629, pango 370/1214. The remainder is dominated by
two buckets that are correct to skip — availability/attribute macros that are not C expressions
at all (695 in pango), and macros that expand to a function call (165), which cannot be a `const`
without calling the library at load time.

#### S-D: done, and how the three architecture-pinned tests were re-expressed

`Generators` keeps `create_context`, `build!`, `get_default_args`, `detect_headers`,
`load_options` and the two-stage `BUILDSTAGE_*` split. What changed is `ctx.dag` → `ctx.nodes`,
a plain `Vector{Node}`. Three things in the old suite pinned the pass architecture rather than
the output; each was re-expressed, not kept:

- **Node markers at fixed DAG positions** — `ctx.dag.nodes[6]`, `nodes[end]`, `nodes[end-1]`.
  Now assertions about the loaded module: `union-in-struct.h` asserts `A` and `union_B` exist
  with clang's layout, which is what the marker was standing in for.
- **The two-stage rewriter workflow** — kept as-is, over `ctx.nodes`. A rewriter is `filter!`
  or `map` rather than surgery that has to keep index-valued edges consistent, and
  `test/generators.jl` exercises it by dropping a declaration and checking it is absent.
- **`Audit` as a hard failure** — dropped. `Audit` existed to catch what the libclang pipeline
  could produce but not detect (a missing definition, a default tag type). The reachability
  walk cannot reach a declaration it has no facts for, so the class is gone rather than
  unchecked; the replacement bar is that every fixture **generates and loads**.

The suite is 170 tests: JLLEnvs 2, Generators 53, Ordering 22, Macros 25, Options 53, ABI 5
(five corpora), MPI 3, Bitfields 7. The old suite's strongest assertions survive — the MPI
driver with its `callback_documentation` hook, and the bitfield round-trip through a real
compiled C library.

Four defects surfaced during the port, three of them in code written for this rework:
`detect_headers` counted the umbrella's own `#include` lines (and a `try/catch` then swallowed
the misspelled accessor in the fix, leaving only a silent symptom); `library_name` must be
`Meta.parse`d rather than `Symbol`ed, since a caller may pass a quoted path; blobbed records had
no by-value `getproperty` and no bit-field-aware `setproperty!`, so a record could be read
through a pointer but never built or written; and record constructors dropped bit-fields.

Still outstanding: **Objective-C**, blocked on ClangCompiler#49.

---

## 1. The thesis

The `Generators` module spends most of its complexity reconstructing facts that Clang's AST
already holds, because libclang cannot express them. Three in particular:

| The question | libclang's answer | Clang's C++ answer |
| --- | --- | --- |
| Are these two cursors the same C entity? | *No such primitive.* Compare file/line/column, then token text. | They are the same `Decl*`. |
| Is this record anonymous, and what typedef names it? | `occursin("(anonymous", spelling(ty))`, then a positional scan of neighbouring nodes. | `getIdentifier(d) == null` and `getTypedefNameForAnonDecl(d)`. |
| Where does this field live, and how wide is it? | `getOffsetOf(type, "name")` — by name, so unnamed fields are unaddressable; alignment unavailable. | `ASTRecordLayout::getFieldOffset(index)` in bits, plus size, alignment, data size, base offsets. |

ClangCompiler.jl wraps the C++ side of all three. The rework is therefore not "port the passes
to a new API" — it is **delete the passes that exist only to pay libclang's tax**, and keep the
ones that encode genuine Julia-codegen judgement.

---

## 2. What was verified, not assumed

Every claim below was checked by running Julia against the local ClangCompiler checkout
(Julia 1.12.6, LLVM 18.1.7, `arm64-apple-macosx11.0.0`). The probes live in this session's
scratchpad; the results are reproduced here because they are what the plan rests on.

### 2.1 One `ASTContext` for many headers — via an umbrella parse

Three headers, where `a.h` is `#include`d by **both** `b.h` and `c.h` (with header guards),
written into a temp dir and pulled in by a single `parse` of an umbrella source:

```
umbrella parse non-null                       true
errors                                        0
top-level decls (total / system / user)       7 / 0 / 7
      RecordDecl            Widget      a.h:3
      TypedefDecl           Widget_t    a.h:4
      RecordDecl            Holder      b.h:4
      FunctionDecl          use_widget  b.h:5
      RecordDecl                        b.h:6      <- the anonymous record
      TypedefDecl           Point       b.h:6
      FunctionDecl          widget_count c.h:4
distinct decl_ids == decl count               true
`struct Widget` top-level nodes               1
```

**`struct Widget` appears exactly once.** There are no duplicates to detect, so there is nothing
for `is_same`, `IndexDefinition`'s duplicate marking, `CatchDuplicatedAnonymousTags` or the seven
`*Duplicated` markers to do. Source-file attribution survives (`a.h:3`, `b.h:4`, `c.h:4`), so
per-header routing (`library_names`, `is_local_header_only`) still has a basis.

**The umbrella is not a convenience — it is required.** Incremental parsing does *not* accumulate
into the TU's direct decl list. After three separate `parse` calls, `decls_in(TU)` returned only
the **last** increment's decls (1 of 5). The AST is genuinely shared — the redeclaration chain
spans increments (`input_line_2` forward decl → `input_line_1` definition), and a field type in
increment 2 resolves to the definition from increment 1 — but *enumeration* is per-increment.
So: **all headers must go into one `parse` call.**

### 2.2 C stays C

`create_interpreter` always calls `CreateCpp`, so the default parses C headers as C++
(`Widget` came back as a `CXXRecordDecl`). Passing `-x c` fixes it completely:

```
A. default            Widget C-mode carrier   CXXRecordDecl
B. -x c               Widget C-mode carrier   RecordDecl
C. -x c -std=c11      Widget C-mode carrier   RecordDecl
```

The `is_cxx=false` keyword is a *different* switch — it selects the GCC shard and include set.
Both are needed.

One consequence, found the hard way: **in C mode `find_decl` cannot see `struct` tags.**
`DeclFinder` runs an ordinary C++ name lookup, and in C a tag lives in the tag namespace, so
`find_decl(I, "Widget")` returns `nothing` while `find_decl(I, "Point")` (a typedef, hence the
identifier namespace) succeeds. The frontend must therefore **enumerate** `decls_in(TU)` and
never fall back to lookup-by-name — which the umbrella design does anyway, but it rules out
using lookup as a shortcut anywhere in the pipeline.

### 2.3 The anonymous-typedef link is native

```
Point underlying record anonymous?            true
  getTypedefNameForAnonDecl round-trip        Point
```

Clang tracks the `typedef struct { … } Point;` link itself. That one accessor replaces
`LinkTypedefToAnonymousTagType` (both instances), `DeAnonymize`, the `gensym("Ctag")` naming
scheme, the `##Ctag` / `__JL_Ctag` prefix sniffing in four files, and the positional
"keep searching until we hit a non-typedef node" heuristic.

### 2.4 System headers, layout, macros, enum values

```
after #include <stdint.h>:  sys / user        105 / 1        # isInSystemHeader, from clang
enum underlying integer type                  unsigned int   # getIntegerType(EnumDecl)
   RED = 1   GREEN = 2   BLUE = 7                            # getInitVal
#define WIDGET_MAX    fnlike=false  body=[("64", 0x07)]
#define WIDGET_SCALE  fnlike=true   params=["x"]
                      body=[("(",0x15),("(",0x15),("x",0x05),(")",0x16),("*",0x1e),("2",0x07),(")",0x16)]
resolve(field type)                           ElaboratedType
getAsRecordDecl -> decl                       RecordDecl Widget    (same decl_id as the definition)
createPreprocessingRecord before parse        OK
```

Note three things in that block:

- `isInSystemHeader(sm, getBeginLoc(d))` partitions correctly. No `-isystem` string-prefix
  matching.
- Macro **token kinds are available** as raw `UInt32` (`0x07` numeric_constant, `0x15`/`0x16`
  parens, `0x1e` star). ClangCompiler does not mirror `tok::TokenKind` as a named enum, but the
  values are usable — this downgrades the macro gap from "blocking" to "vendor the names".
- Field types arrive as **sugar** (`ElaboratedType` for `struct Widget`). `getAsRecordDecl` /
  `getAsTagDecl` look through it. Any port must go through those rather than `getDecl`, which is
  declared on the canonical classes only.

---

## 3. Two hard constraints that decide the architecture

These are not solvable by writing better code, and they are why the recommendation below is
*additive*.

### 3.1 Version reach

| | Julia | LLVM / clang |
| --- | --- | --- |
| **Clang.jl** | ≥ 1.11 | 16, 17, 18, 19, 20, 21 — six `lib/` dirs, libclang from `Clang_unified_jll` |
| **ClangCompiler.jl** | ≥ 1.12 | **18 only** — `lib/18/`, chosen from `Base.libllvm_version` |

ClangCompiler is pinned to the LLVM that *Julia itself* is built against, because `libclangex`
links `clang-cpp` from that LLVM. Clang.jl is not: `Clang_unified_jll` ships its own libclang,
so a user can generate bindings with a clang version chosen to match the library they are
wrapping, independently of their Julia. `gen/generator.jl` in this repo is built around exactly
that (a loop over `(llvm_version, julia_version)` pairs).

**A ClangCompiler-backed generator gives that up.** For a binding generator, losing control of
the parsing clang version is a real regression, not a detail.

### 3.2 The bootstrap relationship

`ClangCompiler/gen/Project.toml` depends on `Clang`. ClangCompiler's own 43k-line bindings are
produced by *this* generator. If `Clang.Generators` gains a hard dependency on ClangCompiler,
then regenerating ClangCompiler requires a Clang.jl that requires ClangCompiler.

That resolves fine in normal operation (the `gen/` environment picks up the last released
ClangCompiler), but it makes any simultaneous breaking change in both packages a two-step dance,
and it drags ClangCompiler's `julia = "1.12"` floor onto everyone who installs Clang.jl.

### 3.3 ~~Recommendation: a package extension~~ — RETRACTED, see §3.4

> **This section is wrong and is kept only to record why.** A package extension loads into the
> *same process* as Clang.jl, and §3.4 shows that is exactly what cannot happen.

```toml
# Project.toml
[weakdeps]
ClangCompiler = "06fc9500-c033-43bc-8ca2-e20da63309d9"

[extensions]
ClangCompilerExt = "ClangCompiler"

[compat]
ClangCompiler = "0.1"
```

- Clang.jl keeps `julia = "1.11"` and its six LLVM directories. The libclang frontend is
  untouched and remains the default.
- `ext/ClangCompilerExt.jl` provides the C++ frontend. It loads only when the user has
  ClangCompiler installed — which on Julia 1.11 they cannot, so the extension simply never
  loads there.
- No bootstrap cycle: ClangCompiler's `gen/` env gets a Clang.jl whose extension may load, but
  the gen script uses the libclang path regardless.
- Selection is one option key: `[general] frontend = "libclang" | "clang-cpp"`.

The C++ frontend becomes the default only when ClangCompiler grows multi-LLVM `lib/` dirs, or
when the project decides pinning to Julia's LLVM is acceptable. That is a separate decision and
this plan does not presume it.

### 3.4 The constraint that decides packaging: one LLVM per process

**Clang.jl and ClangCompiler.jl cannot be loaded into the same Julia process.** Measured, in
both orders; each loads fine alone:

```
import ClangCompiler; using Clang   ->  CommandLine Error: Option 'sanitizer-early-opt-ep'
using Clang; import ClangCompiler   ->      registered more than once!
                                            ERROR: InitError: LLVM error: inconsistency in
                                            registered CommandLine options
```

Clang.jl loads libclang from `Clang_unified_jll`; ClangCompiler loads `clang-cpp` through
`libclangex`. Both statically register LLVM's **global** CommandLine option registry, and the
second registration aborts.

This is not a version-compat problem that a `[compat]` bound can express, and it rules out the
whole family of "both in one process" designs — a package extension above all, since an
extension is by definition loaded alongside its parent.

**What remains viable:**

| Option | Assessment |
| --- | --- |
| **Split the frontend-independent core into its own package** | The principled fix. `ExprDAG`, codegen, printers, `jltypes`/`translate` need no libclang once a frontend has produced nodes — which is exactly the Phase 0 seam. `Clang.jl` then provides the libclang frontend and a separate package provides the C++ one; neither process loads both LLVMs. **Recommended.** |
| **A wholly separate generator package** | Simplest to ship, but duplicates the DAG/codegen/printers or vendors them, and splits the test corpus that defines correctness. |
| **Out-of-process C++ frontend** | Clang.jl shells out; the subprocess emits a serialized node set. Keeps one package, costs a serialization format and per-run process startup. This is what `test/cxx_macros.jl` does today. |
| **Fix the double registration upstream** | Two independently-built LLVMs in one process is inherently fragile; not a path this project controls. |

### 3.5 Why this is a refactor and not a repackaging

Splitting packages only helps if the two halves can be separated, and today they cannot:

```julia
struct ExprNode{T<:AbstractExprNodeType,S<:CLCursor}   # <- the node type is PARAMETERIZED
    id::Symbol                                          #    on a libclang cursor
    type::T
    cursor::S
    ...
```

The DAG does not hold extracted data. It holds **pointers into libclang's AST**, and every
downstream pass re-queries through them. Occurrences of a cursor or `CL*` type per file:

| file | sites | | file | sites |
| --- | --- | --- | --- | --- |
| `codegen.jl` | 96 | | `documentation.jl` | 22 |
| `jltypes.jl` | 74 | | `audit.jl` | 21 |
| `passes.jl` | 53 | | `system_deps.jl` | 16 |
| `resolve_deps.jl` | 42 | | `print.jl` | 15 |
| `top_level.jl` | 39 | | `nested.jl` | 9 |
| `preprocessing.jl` | 23 | | `macro.jl` | 23 |

Only `translate.jl`, `option.jl` and `definitions.jl` are genuinely frontend-free. So the
frontend is not a seam at the front of the pipeline — it runs through all of it.

The good news is that the surface is **bounded and small**. Across the downstream passes
(`codegen`, `print`, `preprocessing`, `mutability`, `documentation`) there are just **34 distinct
questions**, dominated by:

```
 24 getCursorType     8 getTypedefDeclUnderlyingType    3 hasAttrs        2 isBitField
 21 children          8 fields                          3 getTypeDeclaration
 17 spelling          7 name                            3 getNumArguments / getArgType
```

Eight of the 34 are doxygen comment accessors, which is a separable slice.

This also explains a finding from the original triage: `fields(getCursorType(node.cursor))`
appears in five different files, with a `children()` fallback in four of them, because there is
no extracted representation for a pass to consult — each one re-derives from the AST and they
disagree about what a "field" is.

**Out-of-process is not an escape hatch.** A subprocess frontend must send something back across
the boundary, and a cursor is meaningless there — so it must send extracted facts, which is the
same IR. Phase 0 is therefore on the critical path for every option in the table above except
"don't build a second frontend at all".

### 3.6 Ordering: what the DAG is actually for, and one option ruled out

The `ExprDAG` exists for a single reason — Julia has no forward declarations, so a generated
single-file wrapper needs a strict definition order. Measured, order is required for exactly the
**definition-time type positions**:

| requires order | does NOT require order |
| --- | --- |
| `struct A; b::B; end` — field types | `g() = Foo` — ordinary body expressions |
| `f(a::Foo) = …` — method signatures | `g() = Foo(1)`, `g() = sizeof(Foo)` |
| `ccall((:f,l), Foo, (Bar,), x)` — **ccall type arguments** | `g() = h()` — calls to later functions |
| `const A = B` — const right-hand sides | docstrings |

The `ccall` row is the non-obvious one: those types are evaluated when the **method is defined**,
not when it is called.

**The lever this exposes: no type ever depends on a function.** Emitting all functions and all
method definitions (`getproperty`, `setproperty!`, `propertynames`, `unsafe_convert`,
constructors) in a **trailing section** removes them from the ordering problem entirely,
whatever they reference. On Clang.jl's own generated bindings (543 top-level forms) that is
**410 of them — 75.5%**. What remains is 46 structs, 53 enums (which have no edges beyond their
integer type) and 34 consts: roughly **80 nodes with non-trivial edges**, down from 543.

What is left is irreducible. With no forward declaration *and* no redefinition, a genuine cycle
(`struct A { B *b; }` / `struct B { A *a; }`) can only be broken by degrading one field to an
opaque pointer plus conversion methods — which is what the generator already does. The
*machinery* can shrink enormously (Tarjan SCC once, versus `RemoveCircularReference` restarting a
full DFS on every cycle it breaks, bounded at `MAX_CIRCIR_DETECTION_COUNT = 100000`), but the
sort itself cannot be dodged.

#### How much ordering is actually required — measured

Two measurements over the `clang-c` corpus (543 emitted declarations) settle the design.

**What the current pipeline costs in readability:**

```
pairs out of source order          22,304 / 147,153   (15.2%)
type/const nodes  n=136  moved=136  median |move| = 42 positions  max 542
functions         n=407  moved=407  median |move| = 42 positions  max 399
file-to-file switches                  15   (source order gives 14)
```

Every declaration moves, by a median of 42 positions. File blocking is preserved, so the output
is not interleaved chaos — but within that it is thoroughly shuffled, and **407 of the 543 moves
are functions, which never needed to move.**

**What ordering actually demands:**

```
dependency edges with both ends located:  287
edges source order ALREADY satisfies:     277
violations from FUNCTION nodes:             8   <- irrelevant; functions need not move
violations from TYPE/CONST nodes:           2   <- the only forced moves
     time_t     needs __darwin_time_t   (declared later)
     CXComment  needs CXTranslationUnit (declared later)
```

**The entire ordering problem on this corpus is two hoists.** The current design relocates all
543 declarations to solve something that requires moving two.

The reason is structural, not luck: **C itself forbids a non-pointer struct member of an
incomplete type**, so C source order is already a valid topological order for every non-pointer
edge. Only four things can violate it — a pointer to a type declared later, a typedef through a
pointer to an incomplete type, an anonymous record needing to be hoisted to its own definition,
and a macro constant referring to a later one (`dependency.h`'s `#define FIRST SECOND` before
`#define SECOND 1`).

> **§3.6 below contains an error, corrected in [ORDERING-DESIGN.md](ORDERING-DESIGN.md) §1:**
> "no type ever depends on a function" is FALSE. A `const` can name a function
> (`#define ALIAS c_func`, `#define V ENC(1,2)`), `@objcwrapper` expands to
> `abstract type P2 <: P1`, and `emit_constructor!` emits a definition-position `const` naming
> a union's field types. The correct band order is types → functions → **macros**, which is what
> today's printers already do. Read ORDERING-DESIGN.md for the settled design.

#### The design this implies

1. **Functions and methods never move.** They are order-free (fact 2 above), so they stay at
   their source position. That removes 75% of all displacement.
2. **Types and constants: stable, minimal-perturbation ordering.** Emit in source order; relocate
   a declaration only when an edge forces it, and as little as possible.
3. **Cycles are broken at a pointer edge, with a comment at the degraded field** saying why.
4. **Every relocation is reportable.** Today nothing explains why a declaration sits where it
   does; a minimal-perturbation pass can emit its reason.

Readability is a first-class acceptance criterion alongside ABI equivalence: the generated file
should read like the headers it came from.

**Ruled out: blob-everything.** The generator already emits `struct X; data::NTuple{N,UInt8}; end`
plus generated accessors for unions and for structs with attributes, bitfields or nested
anonymous members. Generalising that to *every* record would delete record-to-record edges and
make ordering trivial — and is **rejected**: it optimises the generator's internals at the
expense of every consumer of its output, losing named typed fields, `isbits`, native field
access and inference. Selective blobbing stays exactly as it is today; universal blobbing is off
the table. The consequence is that record-to-record edges remain, so the ordering machinery in
§3.6 is genuinely required rather than optional.

The macro work in [MACRO-HANDLING.md](MACRO-HANDLING.md) is unaffected — `cxx/CxxMacros.jl`
depends only on ClangCompiler and is written to be lifted into whichever package ends up
owning the C++ frontend. What changes is only *where that code lives*, and Phase 0 grows from
"extract a seam" to "extract a seam into a package".

---

## 4. What the rework deletes

Passes and helpers that exist *only* to pay libclang's tax, and have no counterpart in a
single-`ASTContext` world:

| Deleted | Why it existed | Replaced by |
| --- | --- | --- |
| `is_same`, `is_same_loc` | cross-TU entity identity | `decl_id(d)` / pointer equality |
| `IndexDefinition` ×3 | name→index tables, duplicate marking, `adj` clearing | a `Dict{UInt,Int}` keyed on `decl_id`, built once |
| `CatchDuplicatedAnonymousTags` | anonymous tags gensym'd per TU | nothing — there is one node |
| `LinkTypedefToAnonymousTagType` ×2 | positional typedef↔anon-tag linking | `getTypedefNameForAnonDecl` |
| `DeAnonymize` + `smart_de_anonymize` machinery | naming `typedef struct {…} X;` | same accessor, at collection time |
| `CollectDependentSystemNode` + `dag.sys` | pulling in `-isystem` decls by name-scan | the AST already points at them; `isInSystemHeader` classifies |
| `find_dependent_headers` | discovering transitively included headers by re-parsing each header | the umbrella parse pulls them in; `source_location` attributes them |
| the 7 `*Duplicated` markers | first-wins collision marking | — |
| `##Ctag` / `__JL_Ctag` prefix sniffing (4 files) | recovering "this is a synthesized anon tag" | `isAnonymousStructOrUnion` / null `getIdentifier` |
| `occursin("(anonymous", …)` (5 sites) | anonymity | same |
| `gensym_deterministic` + the global atomic counter | stable names for anon tags | ids derived from the naming typedef, or from `decl_id` |

Second-order deletions that follow: `TopologicalSort` no longer needs to invalidate the index
(nodes are keyed by `decl_id`, not position), so the second `ResolveDependency` goes too; and
`resolve_dependency!`'s three-table name lookup with its repeated
`# FIXME: in some cases, this system-header symbol is in dag.tags` fallback collapses into a
single pointer dereference.

**What survives, and should**: the `AbstractJuliaType` lattice and `translate` (Julia-side
judgement, and ClangCompiler deliberately has no `clty_to_jlty`); the node-type markers for
layout (`StructLayout{Attribute,NestedAnonymous,Bitfield}`); `codegen.jl`'s `Expr` emission;
`print.jl`; every printer; the entire option surface; `audit.jl`; `mutability.jl`;
`RemoveCircularReference` (mutual references are a real C phenomenon, not a libclang artifact).

---

## 5. The new shape

### 5.1 Frontend

```julia
# ext/ClangCompilerExt.jl
struct CxxFrontend
    interp::CC.CxxInterpreter
    ctx                 # ASTContext
    sm                  # SourceManager
    pp                  # Preprocessor
    headers::Vector{String}
end

function CxxFrontend(headers, args; is_cxx=false)
    # -x c unless the caller asked for C++; is_cxx selects the GCC shard/include env
    flags = is_cxx ? args : ["-x", "c", args...]
    I = CC.create_interpreter(flags; is_cxx)
    pp = CC.getPreprocessor(CC.get_instance(I))
    CC.createPreprocessingRecord(pp)          # must precede the parse
    umbrella = join(("#include \"$h\"" for h in headers), '\n') * '\n'
    ptu = CC.parse(I, umbrella)
    ptu.ptr == C_NULL && error(...)           # see §6.4 on diagnostics
    ...
end
```

### 5.2 The node table, keyed by identity

```julia
struct ExprNode{T<:AbstractExprNodeType,D}
    id::Symbol            # still the emitted Julia name
    type::T
    decl::D               # a resolved ClangCompiler carrier, not a CXCursor
    exprs::Vector{Expr}
    premature_exprs::Vector{Expr}
    adj::Vector{Int}
end

struct ExprDAG
    nodes::Vector{ExprNode}
    index::Dict{UInt,Int}            # decl_id  -> position.  THE index. One namespace.
    ids_extra::Dict{Symbol,AbstractJuliaType}
    ...
end
```

`dag.tags` and `dag.ids` merge into one `Dict{UInt,Int}` because C's two namespaces stop
mattering once edges are pointers rather than names. (`dag.ids_extra` stays name-keyed — it is a
user-facing table of hand-supplied types, and `@add_def` is part of the public API.)

### 5.3 Dependency resolution becomes a dereference

Today:

```julia
jlty = tojulia(ty); leaf = get_jl_leaf_type(jlty)
hasref = has_elaborated_tag_reference(ty)
if hasref && haskey(dag.tags, leaf.sym)      push!(node.adj, dag.tags[leaf.sym])
elseif !hasref && haskey(dag.ids, leaf.sym)  push!(node.adj, dag.ids[leaf.sym])
elseif haskey(dag.ids_extra, leaf.sym)       # pass
elseif !hasref && haskey(dag.tags, leaf.sym) # FIXME: system-header symbol in dag.tags
...
```

After:

```julia
d = CC.getAsTagDecl(strip_to_leaf(ty))       # looks through Elaborated/Typedef/Pointer/Array
d === nothing || push!(node.adj, dag.index[CC.decl_id(CC.resolve(d))])
```

No name, no namespace guess, no fallback chain, no `error("There is no definition for …")` —
a type either points at a decl or it does not, and if it does, that decl is in the table because
the AST is closed under reference.

### 5.4 The pipeline, after

```
CollectDecls          # one walk of decls_in(TU); classify; partition user/system by isInSystemHeader
ResolveDependency     # pointer edges
RemoveCircularReference
TopologicalSort
CodegenPreprocessing  # skip / attribute / nested-anonymous / bitfield  (see §6.1)
Audit
Codegen
CodegenMacro
<printers>
```

Fifteen unconditional passes become eight, and the ones that remain each run once.

### 5.5 Layout, properly

`codegen.jl`'s `_emit_getproperty_ptr!` currently walks fields recursively because
`getOffsetOf(type, name)` cannot address an unnamed one, and never asks about alignment. Against
`ASTRecordLayout` it is a flat loop:

```julia
layout = CC.get_record_layout(ctx, rd)
size   = Int(CC.getSize(layout))          # bytes
align  = Int(CC.getAlignment(layout))     # bytes  — currently never queried at all
for f in CC.getFields(rd)
    off = CC.getFieldOffset(layout, CC.getFieldIndex(f))     # BITS, unnamed fields included
    w   = CC.isBitField(f) ? Int(CC.getBitWidthValue(f, ctx)) : nothing
end
```

This also removes the `@assert w <= 32` bitfield cap: `getBitWidthValue` is exact, and the
storage-unit arithmetic can be driven from real offsets rather than assumed 32-bit words.

Attributes stop being a cliff. Today `hasAttrs` degrades any attributed record to padded bytes;
`hasAttrOfKind(d, CXAttrKind_Packed)` and `AlignedAttr`'s payload are precise — and mostly
unnecessary, because `ASTRecordLayout` has *already applied* them.

### 5.6 Macros, from the preprocessor rather than from text

> **Superseded in detail by [MACRO-HANDLING.md](MACRO-HANDLING.md)**, which triages all 41
> macro-tagged issues, gives the design, and reports a working prototype. The sketch below is
> kept because the rest of §5 refers to it. Two corrections it makes: a cast emits `%` but an
> integer *literal* must instead be typed by C11 6.4.4.1p5 against the target's widths (the two
> rules are different, and conflating them is a live trap); and filtering macro origins needs
> `isWrittenInBuiltinFile`/`isWrittenInCommandLineFile` as well as `isInSystemHeader`.

`macro.jl` today re-lexes token text: literal suffixes hand-parsed longest-first, `/` rewritten
to `÷` and `^` to `xor` unconditionally, casts detected by re-implementing C's typedef symbol
table, adjacent string literals merged by round-tripping through `Meta.parse`.

The replacement reads the preprocessor's own token list, which arrives **already classified**:

```julia
for ii in CC.getMacros(pp)
    mi = CC.getMacroInfo(pp, ii); mi.ptr == C_NULL && continue
    CC.isBuiltinMacro(mi) && continue
    toks = [(CC.getSpelling(pp, t), CC.getKind(t)) for t in replacement_tokens(mi)]
    params = CC.isFunctionLike(mi) ? [CC.getName(CC.getParam(mi,i)) for i in 0:CC.getNumParams(mi)-1] : String[]
end
```

A `numeric_constant` is tagged as one, so suffix handling becomes a small typed function instead
of an ordered suffix list; `##` (`hashhash`) and `#` (`hash`) are distinct kinds; a
`string_literal` is known to be one without a `Meta.parse` probe, and `wide_string_literal` is
its own kind rather than an `L"` regex. Verified on a 12-macro corpus (§6.1).

Header-guard detection stops being `endswith(id, "_H")` and becomes `isUsedForHeaderGuard(mi)`,
which clang tracks natively. Measured against two real guarded headers:

```
G_H                    isUsedForHeaderGuard=true   ntokens=0
REAL_CONST             isUsedForHeaderGuard=false  ntokens=1
HDR_NOT_SUFFIXED       isUsedForHeaderGuard=true   ntokens=0
```

`HDR_NOT_SUFFIXED` is the point: today's heuristic hard-codes the `_H` suffix plus a
user-supplied `ignore_header_guards_with_suffixes` list, so a guard named anything else leaks
into the output as a spurious `const`. Note the predicate needs the real `#ifndef/#define/#endif`
structure — a bare `#define G_H` in a snippet reports `false`.

### 5.7 What is allowed to change — and the rule that decides

**Decision taken: the C++ path may improve on the libclang path's output from the start.** It is
not held to byte-identical emission. That makes textual diffing useless as an acceptance test,
so acceptance moves to a stronger criterion:

> **The ABI is the contract, not the text.** For every emitted type, the generated Julia
> `sizeof`, field byte-offsets and bit-field extents must equal what **clang** reports for the
> same record on the same target. For every emitted function, the `ccall` signature must match
> the declaration's type. Anything else — names, ordering, formatting, which construct is chosen
> to express a layout — is free to differ.

This is checkable mechanically, because clang is *in process*: `get_record_layout` /
`getFieldOffset` / `getBitWidthValue` are the oracle, and Julia's own `sizeof` / `fieldoffset`
are the subject. ClangCompiler's `examples/04_record_layout.jl` already runs exactly this
cross-check and asserts on it.

Triage for any diff between the two frontends then has a rule rather than a judgement:

| Diff touches | Verdict |
| --- | --- |
| a size, offset, alignment or bit-field extent | **bug**, unless it is on the register below |
| a `ccall` signature or return type | **bug** |
| an enum constant's value | **bug** |
| a name, an ordering, formatting, a docstring | **acceptable** — record it, move on |
| a construct choice that preserves the ABI | **acceptable** |

#### The register: improvements that *must* change, with pinned values

Each row was measured against clang (Julia 1.12.6, LLVM 18.1.7, `arm64-apple-macosx11.0.0`)
and is a case the current generator cannot express. These become test assertions in their own
right — they are what the C++ path is *for*.

```c
struct Wide     { unsigned long long lo : 40; unsigned long long hi : 24; };
struct Over     { char h; _Alignas(32) int payload; };
struct __attribute__((packed)) Packed { char c; int i; double d; };
struct Mixed    { char flag; union { float f; int i; }; unsigned : 0; unsigned tail : 5; };
```

| Case | clang says | today |
| --- | --- | --- |
| `Wide` | size 8, `lo` @ bit 0 w=40, `hi` @ bit 40 w=24 | **aborts** — `@assert w <= 32` ([codegen.jl:314](src/generator/codegen.jl:314)) |
| `Over` | **size 64, align 32**, `payload` @ byte 32 | alignment is never queried, so this cannot be emitted correctly by construction |
| `Packed` | **size 13, align 1**, fields @ 0, 1, 5; `hasAttrOfKind(d, Packed)` = `true` | `hasAttrs` only ⇒ degrades to an opaque padded-bytes struct |
| `Mixed` | anonymous union member flagged; `unsigned : 0` present as a width-0 field @ bit 64 | the unnamed field has no name for `getOffsetOf(type, name)` to key on |

One more measured improvement, ABI-neutral but a correctness fix in its own right:

| Case | clang says | today |
| --- | --- | --- |
| a header guard not ending in `_H` | `isUsedForHeaderGuard` = `true` | leaks into the output as a spurious `const`, unless the user lists the suffix by hand |

Two further intended changes are user-visible but ABI-neutral, so they fall under "acceptable"
and should be *announced* rather than tested against the old output:

- **Anonymous tags get meaningful, stable names.** `getTypedefNameForAnonDecl` yields `Point`
  where the libclang path emits `##Ctag#347`. This makes `use_deterministic_symbol` obsolete on
  the C++ path — the names are stable because they come from the source, not from a counter.
- **Duplicate-suppression disappears from the output.** There is one canonical decl, so nothing
  is emitted-then-skipped.

---

## 6. Gaps to close first

Ordered by how much they block. Items marked **[CC]** need work in ClangCompiler; per its
`AGENTS.md`, C++ shim changes are out of scope for a Julia-side contributor and must be raised
as a dependency.

1. ~~**Token-kind names.**~~ **Not a gap — closed on inspection.** `getKind(::Token)` does return a
   bare `UInt32`, but `src/clang/api/Basic/TokenKinds.jl` already wraps the `clang::tok` free
   functions that consume one: `getTokenName`, `getPunctuatorSpelling`, `getKeywordSpelling`,
   `getPPKeywordSpelling`, `isLiteral`, `isAnyIdentifier`, `isStringLiteral`, `isAnnotation`,
   `isPragmaAnnotation`. Verified end-to-end against a macro corpus — `##` comes back
   `hashhash` and `#` comes back `hash`; `L"wide"` is `wide_string_literal`, distinct from
   `string_literal`; `1.5f`, `0xDEADul` and `64` are all `numeric_constant` with `isLiteral`
   true; keywords arrive named (`unsigned`, `long`). Nothing needs to be vendored and no
   ClangCompiler change is required.
2. **Array extents.** `getSize(::ConstantArrayType)` returns an `LLVMGenericValueRef` the caller
   must free via LLVM-C. An array extent is the single most common thing a generator asks for.
   *Mitigation*: a helper that round-trips and disposes. **[CC]** an `Int`-returning accessor.
3. **Enum constant values.** Same shape — `getInitVal` returns an owned `LLVMGenericValueRef`
   (verified working, values correct). Needs disposal per enumerator or it leaks. Same
   mitigation.
4. **Structured diagnostics.** On the interpreter route, failure is a NULL
   `PartialTranslationUnit` plus text on stderr; only `getNumErrors` is in-band. Today
   `find_dependent_headers` catches per-header parse failures and warns with the header name.
   With one umbrella parse, a single bad header fails everything with no attribution.
   *Mitigation*: pre-flight each header with its own throwaway interpreter (costly), or parse
   the umbrella and, on failure, bisect. **[CC]** wrap `TextDiagnosticBuffer`.
5. **`#pragma pack(n)`.** `MaxFieldAlignmentAttr` has a carrier and a cast but no payload
   accessor. Largely moot — the layout already reflects it — but it cannot be *reported*.
6. **Objective-C.** `clang::ObjCInterfaceType` and `ObjCTypeParamType` have **no carrier struct
   and no `TypeClassMap` entry** — only `ObjCObject` and `ObjCObjectPointer` are mapped
   (`src/TypeClassMap.jl:34-35`), so the two classes that actually *name* an interface resolve
   to `UnexposedType`. `AvailabilityAttr` has a carrier and a cast but no payload accessor, so
   `minimum_macos_supported` cannot be reproduced. **The ObjC path should stay on the libclang
   frontend** until **[CC]** closes this. The macOS-only ObjC testset pins exact emitted text,
   so this is a hard gate.
7. **Public API surface.** ClangCompiler declares 20 `public` lines and no `export`s; almost
   everything the generator needs (`getASTRecordLayout`, `getFields`, `getMacros`,
   `isInSystemHeader`, the carriers) is reached as `ClangCompiler.X` with no stability promise.
   Worth agreeing a `public` list with that package before depending on it.
8. **Per-node ccall cost.** `getNumParams` + `getParamDecl` per parameter; `getAttrs` one ccall
   per attribute; `getBases` per base. `getFields`/`getMethods`/`getEnumerators` already use
   count+fill. Fine at header scale; measure before optimising.
9. **`getName` aborts on non-identifier names**, and `resolve` is type-unstable
   (`Dict{<:Enum,Any}`). Use the null-`getIdentifier` guard everywhere (as the probe does) and
   expect dynamic dispatch on every node.

---

## 7. Phasing

Each phase ends green on the existing suite. The libclang frontend stays default throughout.

**Phase 0 — a frontend-neutral node IR.** *(This phase was originally described as "extract the
two places the pipeline touches libclang". That was wrong by two orders of magnitude — see
§3.5.)* `ExprNode` must carry **extracted facts** instead of a cursor: for a record, its fields
with their types, bit offsets, widths and anonymity, plus size, alignment and attributes; for a
function, its parameters, return type, variadic-ness and linkage. The surface is bounded — 34
distinct questions, listed in §3.5 — but it touches 12 of the 20 files in `src/generator`.
No behaviour change; the existing suite is the check.

**Phase 1 — identity.** Re-key `ExprDAG` on an opaque node identity instead of `Symbol`, keeping
the libclang frontend (where identity stays "file:line:col + tokens"). This is the disruptive
change and it is worth making *before* the frontend swap, so the two are independently
bisectable. Expect to re-express the position-anchored assertions (`ctx.dag.nodes[6]`,
`nodes[end]`) by id.

**Phase 2 — the C++ frontend package.** (Not an extension — see §3.4.) `CxxFrontend`:
umbrella parse, `-x c`, `decls_in` walk, `isInSystemHeader` partition, `decl_id` identity,
`getTypedefNameForAnonDecl` naming. Gate on `[general] frontend = "clang-cpp"`.

**Phase 3 — ABI-equivalence testing.** Since the output is allowed to improve (§5.7), the
acceptance test is not a text diff. Build a harness that, for each header in `test/include/`:

1. generates with the C++ frontend and `include`s the result into a fresh module;
2. asks clang, through the same interpreter, for each record's `getSize` / `getAlignment` /
   `getFieldOffset` / `getBitWidthValue`;
3. asserts Julia's `sizeof` and `fieldoffset` on the generated type agree, field for field.

That is a **stronger** test than the current suite, which mostly asserts `build!` reached
`"Done!"`. It also subsumes `test_bitfield.jl`'s round-trip against a real compiled library, and
unlike a text diff it does not need the libclang path to be correct — it checks against clang
itself.

Run the text diff too, but only as a *change report* for triage under §5.7's table, not as a
gate. The self-hosting run over `clang-c` is the large case; `test/include/` gives ~30 small
ones plus the four register cases, which should fail loudly on the libclang path and pass on the
C++ one.

**Phase 4 — layout and macros.** Switch `codegen.jl`'s layout queries to `ASTRecordLayout` and
rewrite `macro.jl` against `MacroInfo`. `test_bitfield.jl` (a real compiled C library) and the
`large-integer-literals.h` exact-`Expr` assertions are the bar.

**Phase 5 — delete.** Remove the passes from §4 *from the C++ path only*. The libclang path keeps
them for as long as it exists.

---

## 8. Risks

| Risk | Severity | Handling |
| --- | --- | --- |
| **Clang.jl and ClangCompiler cannot share a process** | **blocking** | measured, both orders; rules out a package extension. Split the frontend-independent core into its own package (§3.4) |
| LLVM 18 / Julia 1.12 only | **high** | separate package, not a dependency; libclang stays default (§3.4) |
| Single umbrella parse ⇒ one bad header kills the run | **high** | pre-flight or bisect; push for `TextDiagnosticBuffer` (§6.4) |
| ObjC regression | **high** | keep ObjC on libclang until §6.6 closes |
| Node ordering changes ⇒ position-anchored tests break | medium | re-express by id in Phase 1, before the frontend swap |
| `create_interpreter` starts a JIT for a parse-only job | low | one-time cost; measure |
| Bootstrap coupling with ClangCompiler | medium | extension keeps it a soft edge (§3.2) |
| ClangCompiler's surface is not `public` | medium | agree a list up front (§6.7) |

---

## 9. Decisions — all settled

1. **Packaging → package extension.** `[weakdeps] ClangCompiler` + `ext/ClangCompilerExt.jl`,
   selected by `[general] frontend = "libclang" | "clang-cpp"`. Rationale in §3.3: it keeps
   Clang.jl at `julia = "1.11"` with six LLVM directories, keeps libclang the default, and keeps
   the ClangCompiler bootstrap a soft edge. A separate `ClangGenerators.jl` was the alternative;
   it decouples version reach completely but costs a release channel and splits the test suite
   away from the corpus that defines correctness. Revisit only if the weakdep proves awkward in
   ClangCompiler's own `gen/` environment.
2. **Objective-C → stays on libclang for the first release.** `clang::ObjCInterfaceType` and
   `ObjCTypeParamType` have no carrier and no `TypeClassMap` entry, so they resolve to
   `UnexposedType`; `AvailabilityAttr` has no payload accessor, so `minimum_macos_supported`
   cannot be reproduced. The C++ frontend should **reject ObjC input with a clear diagnostic**
   naming the libclang frontend, rather than emitting quietly degraded wrappers. Filing 5 below
   is what lifts this.
3. **Output fidelity → allowed to improve.** Acceptance is ABI equivalence against clang, not
   text equivalence. Rule and register in §5.7; harness in §7 Phase 3.
4. **Filings → the five below.** §6.1 turned out not to be a gap at all (the `clang::tok` free
   functions are already wrapped), which removes the item that would have blocked the macro
   rewrite. Nothing remaining blocks Phase 0–2.

### Appendix: ClangCompiler filings

Ordered by effect. Each names the clang entity, so the shim work is specified rather than
described. Per `deps/ClangExtra/CLAUDE.md`, every one needs: a C shim entry point, regenerated
`lib/18/LibClangEx.jl`, a Julia wrapper in the matching `src/clang/api/` file, and a
`libclangex_jll` bump before release. Note that file's rule about checking the *pinned artifact
header* for access and partiality before writing a signature, and `nm -gU` against the shipped
`libclang-cpp` to confirm the symbol is actually exported.

**Filing 1 — `Int`-returning array extent.** `clang::ConstantArrayType::getSize()` returns an
`llvm::APInt`; the current wrapper hands back an `LLVMGenericValueRef` the caller must free
through LLVM-C. Add a narrowed accessor returning `uint64_t` (mirroring how
`getEnumConstantDeclValue` already narrows). *Effect*: array extents are the single most common
generator query; today every one costs an LLVM.jl round trip plus a manual dispose, and a missed
dispose leaks per array field.

**Filing 2 — `Int`-returning enumerator value.** `clang::EnumConstantDecl::getInitVal()` returns
`const llvm::APSInt&`; same `LLVMGenericValueRef` problem. Verified working but leak-prone
(§2.4 read `RED=1 GREEN=2 BLUE=7` correctly). Signedness matters here — an `int64_t` accessor
plus `isSigned` is the minimum; unsigned 64-bit enumerators need `uint64_t` too. Note the
existing `getInitVal` docstring points at a helper `get_enum_constant_decl_value` that does not
exist anywhere in `src/`.

**Filing 3 — `TextDiagnosticBuffer`.** Currently the available consumers are
`TextDiagnosticPrinter` (stderr) and `IgnoringDiagConsumer`, so on the interpreter route a
failure is a NULL `PartialTranslationUnit` plus text the Julia side never sees; only
`getNumErrors` is in-band. *Effect*: this decides whether a failed **umbrella** parse can be
attributed to a header at all — see Risk row 2. Without it the fallback is bisecting the
umbrella, which costs one full frontend run per bisection step.

**Filing 4 — `MaxFieldAlignmentAttr` payload.** The carrier, the checked cast and the kind-map
entry exist; `clang::MaxFieldAlignmentAttr::getAlignment()` is not exposed, so the `n` in
`#pragma pack(n)` is unreadable. Low urgency — `ASTRecordLayout` has already applied it, so this
is about *reporting* rather than *correctness*.

**Filing 5 — Objective-C carriers and `AvailabilityAttr` payload.** Two parts: (a) carriers plus
`TypeClassMap` entries for `clang::ObjCInterfaceType` and `clang::ObjCTypeParamType`, which today
fall through to `UnexposedType` (`src/TypeClassMap.jl:34-35` maps only `ObjCObject` and
`ObjCObjectPointer`); (b) accessors on `clang::AvailabilityAttr` for platform, introduced,
deprecated, obsoleted, unavailable. *Effect*: this is the whole of decision 2 — until it lands,
ObjC headers must go through the libclang frontend.

**Filing 6 (not a shim change) — agree a `public` surface.** ClangCompiler declares 20 `public`
lines and no `export`s, so the generator would reach `getASTRecordLayout`, `getFields`,
`getMacros`, `getFieldOffset`, `isInSystemHeader`, `getTypedefNameForAnonDecl`, `decls_in`,
`resolve` and every carrier type as `ClangCompiler.X` — names carrying no stability promise and
no lint coverage. Worth agreeing the list before Phase 2 rather than after.

### Consequences of decision 3 already folded in

- Acceptance harness is ABI-based (§7 Phase 3), which is strictly stronger than the current
  suite's "reached `Done!`" assertions.
- The four register cases in §5.7 become tests that *should* fail on the libclang path.
- `use_deterministic_symbol` becomes a no-op on the C++ path; anonymous tags take their names
  from `getTypedefNameForAnonDecl`.
- Position-anchored assertions (`ctx.dag.nodes[6]`, `nodes[end]`) are re-expressed by id in
  Phase 1 regardless — but with output free to change, there is no reason to preserve the old
  ordering at all.
