# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Clang.jl is two things stacked on one another, and almost every question about this repo is
really a question about which of the two you are in:

1. **A libclang binding** — `lib/<llvm_major>/LibClang.jl` (generated) plus a hand-written
   object layer in `src/*.jl` that turns libclang's flat `CXCursorKind`/`CXTypeKind` enums into
   Julia types (`CLFunctionDecl`, `CLPointer`, …).
2. **The `Generators` module** (`src/generator/`) — a C-header-to-Julia binding generator built
   on top of (1). This is what the package is actually used for: `create_context(headers, args,
   options)` then `build!(ctx)` emits a `.jl` file of `ccall` wrappers, structs, enums and
   constants. It is what produces `LibClang.jl` in this very repo, and what
   ClangCompiler.jl uses to produce its own bindings.

The generator is a **pass pipeline over a mutable expression DAG**. Everything in
`src/generator/` exists to serve that pipeline, and the pipeline's shape is dictated by one
constraint that is worth understanding before you change anything: libclang gives you N
*independent* translation units and no way to ask whether a cursor in TU 1 and a cursor in TU 2
are the same C entity. See [Cross-translation-unit analysis](#cross-translation-unit-analysis-the-tax-libclang-charges)
below, and [GENERATORS-REWORK.md](GENERATORS-REWORK.md) for the plan to remove that constraint.

## Commands

```bash
# Run the full test suite (this is what CI runs)
julia --project -e 'using Pkg; Pkg.test()'

# Regenerate this package's own libclang bindings into lib/<llvm_major>/LibClang.jl.
# The driver loops over (llvm_version, julia_version) pairs — currently one active pair with
# six earlier ones commented out (gen/generator.jl:61-67). Uncomment to regenerate an older set.
julia --project=gen gen/generator.jl

# Build the docs
julia --project=docs docs/make.jl
```

There is no formatter configuration and nothing in CI runs one; match the surrounding file.

### Running one test file

Test files are not self-contained — `test/generators.jl` does its own `using` but relies on the
test environment (`Test`, `TOML`, `CMake_jll`, `CEnum`, `REPL` are in `test/Project.toml`, not
in the main project). Use TestEnv:

```bash
julia --project -e 'using TestEnv; TestEnv.activate(); include("test/generators.jl")'
```

Two traps when triaging a run:

- **Piping hides failures.** `julia ... 2>&1 | tail -20; echo $?` reports *tail's* status.
  Redirect to a file (`julia ... > log 2>&1; echo $?`) and grep the log.
- **A generator failure is often an `error()` deep in a pass, not a `@test` failure.**
  `resolve_dependency!` calls `error("There is no definition for ...")`
  ([src/generator/resolve_deps.jl:47](src/generator/resolve_deps.jl:47)) and
  `RemoveCircularReference` calls `error("Could not remove circular reference ...")`
  ([src/generator/passes.jl:448](src/generator/passes.jl:448)). Grep the log for `ERROR` and
  `There is no definition`, not just `Fail`.

## Architecture

### Layer 1 — `lib/` (generated, never hand-edit)

`lib/16/` … `lib/21/`, one `LibClang.jl` per LLVM major. Which one loads is decided at module
init from `Base.libllvm_version`, clamped at both ends
([src/Clang.jl:11-21](src/Clang.jl:11)) — below 17 it loads `16`, at 21 or above it loads `21`.
The six directories exist to span the Julia versions the package supports (1.11 ships LLVM 16;
1.12 ships LLVM 18).

Note the seam: the *directory* is chosen from Julia's own LLVM version, but the library actually
loaded is whatever `Clang_unified_jll` ships. These agree in practice because the JLL tracks
Julia's LLVM, but nothing enforces it, and a mismatch would be an ABI mismatch on `CXCursor`,
not a load error.

`LLVM_VERSION`, `LLVM_LIBDIR`, `LLVM_INCLUDE` and `CLANG_INCLUDE` are derived from
`clang_getClangVersion()` and the JLL's artifact dir ([src/Clang.jl:84-91](src/Clang.jl:84)) —
i.e. from the *running libclang*, not from `Base`.

### Layer 2 — `src/*.jl` (the libclang object layer)

- `src/cltypes.jl` — builds the Julia type hierarchies. For each of `CXCursorKind`,
  `CXTypeKind`, `CXTokenKind` and `CXCommentKind` it `@eval`s one struct per enumerator
  (`CLFunctionDecl <: CLCursor`, `CLPointer <: CLType`, …) and a `Dict` from enum value to
  struct. The hierarchies are **flat**: `CLCursor` has ~304 direct subtypes and no intermediate
  abstract layer, so "is this any kind of record decl" is a `Union` or an `in`, never a
  subtype test. Range markers (`CXCursor_FirstDecl` and friends) are filtered by a
  case-insensitive `r"first|last"i` regex over the enumerator *name*
  ([src/cltypes.jl:7-11](src/cltypes.jl:7)), and the value-keyed dicts silently collapse
  aliased enumerators (`CXCursor_MacroExpansion` and `CXCursor_MacroInstantiation` are both 50).
- `src/cursor.jl` (857 lines) — cursor accessors, `children()`, `search()`, equality/hashing.
  `children` builds a fresh `@cfunction` trampoline per call.
- `src/type.jl` (455 lines) — `CLType` accessors, `fields()`, and the four hand-rolled
  type-structure walks (`has_elaborated_reference`, `has_elaborated_tag_reference`,
  `has_function_reference`, `get_elaborated_cursor`).
- `src/trans_unit.jl`, `src/index.jl`, `src/token.jl`, `src/file.jl`, `src/module.jl`,
  `src/string.jl`, `src/compiledb.jl`, `src/dump.jl` — TU parsing, tokenization, file/module
  queries, `CXString` marshalling, compilation databases.
- `src/platform/` — `JLLEnvs`: resolves cross-compilation shard artifacts out of the top-level
  `Artifacts.toml` (137 KB of it) into `-isystem` flags and a `--target`. This is what
  `get_default_args()` returns, and it is why the generator runs with `-nostdinc` and
  JLL-provided includes rather than the host toolchain's.

**CXString discipline**: every accessor returning a `CXString` must dispose it.
`_cxstring_to_string` ([src/string.jl](src/string.jl)) is the funnel; it skips
`clang_disposeString` on the NULL-data path, and a handful of accessors
(`getDeclObjCTypeEncoding`) return an undisposed live string.

### Layer 3 — `src/generator/` (the Generators module)

The data model is two types in [src/generator/types.jl](src/generator/types.jl):

```julia
struct ExprNode{T<:AbstractExprNodeType,S<:CLCursor}
    id::Symbol            # the C name, or a gensym'd "##Ctag###" for anonymous tags
    type::T               # the node-type marker: StructDefinition, FunctionProto, Skip, ...
    cursor::S             # the libclang cursor it came from
    exprs::Vector{Expr}   # what codegen emitted
    premature_exprs::Vector{Expr}
    adj::Vector{Int}      # dependency edges, as INDICES into dag.nodes
end

Base.@kwdef struct ExprDAG
    nodes::Vector{ExprNode}          # abstract eltype -> every access is dynamic dispatch
    partially_emitted_nodes::Dict{Symbol,ExprNode}
    sys::Vector{ExprNode}            # nodes seen only in -isystem headers
    tags::Dict{Symbol,Int}           # tag namespace   -> index into nodes
    ids::Dict{Symbol,Int}            # ident namespace -> index into nodes
    ids_extra::Dict{Symbol,AbstractJuliaType}
end
```

The **node-type marker** is the whole classification system: `StructDefinition`,
`StructForwardDecl`, `StructOpaqueDecl`, `StructAnonymous`, `StructMutualRef`,
`StructDuplicated`, `StructLayout{Attribute,NestedAnonymous,Bitfield}`, and the parallel
families for unions, enums, typedefs, functions, macros and ObjC. Passes rewrite a node by
constructing a *new* `ExprNode` at the same index with a different marker. Note the
five-argument outer constructor silently resets `premature_exprs` to a fresh empty vector
([types.jl:187-188](src/generator/types.jl:187)), so any premature exprs are lost across a
rewrite.

Everything else in the module is either a pass, or a helper a pass calls:

| File | Role |
| --- | --- |
| `passes.jl` (1251) | all 21 pass types |
| `context.jl` (308) | `Context`, `create_context`, `add_default_passes!`, `build!`, `get_default_args`, `detect_headers` |
| `codegen.jl` (987) | `emit!` — node marker → Julia `Expr` |
| `macro.jl` (403) | `#define` → Julia, by token-text rewriting |
| `documentation.jl` (402) | doxygen comments → Markdown docstrings |
| `types.jl` (314) | `ExprNode`, `ExprDAG`, the node-type taxonomy |
| `print.jl` (303) | `pretty_print` — `Expr` → text |
| `jltypes.jl` (291) | the `AbstractJuliaType` lattice and `tojulia(::CLType)` |
| `resolve_deps.jl` (264) | `resolve_dependency!` — populate `node.adj` |
| `top_level.jl` (260) | `collect_top_level_nodes!` — cursor → `ExprNode` |
| `translate.jl` (195) | `AbstractJuliaType` → Julia `Expr`/`Symbol` |
| `preprocessing.jl` (168) | despite the name, the codegen *classifiers* (`skip_check`, `attribute_check`, `nested_anonymous_check`, `bitfield_check`) |
| `system_deps.jl` (158) | pulling `-isystem` nodes into the main list |
| `audit.jl` (121) | pre-codegen sanity checks |
| `mutability.jl` (89) | `TweakMutability` support |
| `utils.jl` (54) | `is_same`, `is_same_loc`, the deterministic-gensym counter |
| `definitions.jl` (52) | `@add_def` and the extra-definitions table |
| `nested.jl` (43) | `collect_nested_record!` |
| `option.jl` (2) | `load_options` = `TOML.parse`, no schema, no validation |

## The pass pipeline

`add_default_passes!` ([context.jl:96-157](src/generator/context.jl:96)) installs this exact
sequence. The order is load-bearing and mostly undocumented, so it is written out here:

```
CollectTopLevelNode                  # all TUs' top-level cursors -> one dag.nodes vector
LinkTypedefToAnonymousTagType        # on dag.nodes  — needs raw source order, so it runs first
LinkTypedefToAnonymousTagType(sys)   # on dag.sys
IndexDefinition                      # build tags/ids; mark duplicates; CLEARS every node.adj
CollectDependentSystemNode           # prepend! system nodes  -> invalidates all indices
IndexDefinition                      # ...so rebuild them
CollectNestedRecord                  # discover anonymous/nested records, push! new nodes
FindOpaques                          # forward decls with no definition -> Opaque
ResolveDependency                    # populate node.adj
RemoveCircularReference              # break cycles so a topo sort exists
TopologicalSort                      # reorders dag.nodes -> invalidates all indices
IndexDefinition                      # ...so rebuild them
ResolveDependency                    # ...and re-resolve
CatchDuplicatedAnonymousTags         # the duplicates IndexDefinition cannot see
CodegenPreprocessing                 # skip/attribute/nested-anonymous/bitfield classification
[DeAnonymize]                        # if general.smart_de_anonymize (default true)
[LinkEnumAlias | Audit]              # LinkEnumAlias only in no_audit mode
Codegen                              # emit! into node.exprs
CodegenMacro
[AddFPtrMethods]                     # if general.add_fptr_methods (default false)
[TweakMutability]                    # if general.auto_mutability (default false)
<printers>
```

`IndexDefinition` appearing three times and `ResolveDependency` twice is not redundancy — it
is the cost of `node.adj` holding **integer indices into `dag.nodes`**. Any pass that inserts
(`CollectDependentSystemNode`'s `prepend!`) or reorders (`TopologicalSort`) invalidates every
edge in the graph, so the index has to be rebuilt and the edges recomputed.

`CodegenPostprocessing` exists but is never installed — the `push!` is commented out and the
body is an empty `# TODO: find a use case`.

`build!` ignores every pass's return value and only filters by stage:
`BUILDSTAGE_NO_PRINTING` skips `AbstractPrinter` passes, `BUILDSTAGE_PRINTING_ONLY` skips
everything else. That two-stage split is the documented rewriter workflow
([docs/src/generator.md:53-75](docs/src/generator.md:53)).

## Cross-translation-unit analysis: the tax libclang charges

`create_context` parses **each header into its own `TranslationUnit`**
([context.jl:91](src/generator/context.jl:91)). `a.h` included by both `b.h` and `c.h` therefore
yields *three* unrelated `CXCursor`s for the same `struct Widget`, and libclang offers no
primitive that says they are one entity. Everything below exists to re-derive that fact:

- **`is_same` / `is_same_loc`** ([utils.jl:5-41](src/generator/utils.jl:5)) — compares
  `normpath(file)` + line + column, and failing that **compares the two cursors' token text**.
- **`IndexDefinition`** — re-keys the whole DAG on `Symbol` names, first-wins, and rewrites every
  later colliding node to a `*Duplicated` marker. The comment at
  [types.jl:279](src/generator/types.jl:279) is explicit: *"tag-types are possiblely duplicated
  because we are doing CTU analysis"*. Identifier duplicates get no `is_same` check at all.
- **`CatchDuplicatedAnonymousTags`** — anonymous tags get a fresh `gensym("Ctag")` per TU, so
  they never collide by name; this pass finds them by string-prefix sniffing `##Ctag` /
  `__JL_Ctag` and then comparing source locations. It is an O(|nodes| × |tags|) scan.
- **`dag.sys` + `CollectDependentSystemNode`** — a fixed-point loop that resolves unsatisfied
  leaf symbols by **linear scan over `dag.sys`, matched purely by name**.

Three more places where the ceiling shows:

- **Anonymity** is decided by `occursin("(anonymous", spelling(x))` — string-sniffing clang's
  pretty printer. The markers are defined at
  [Generators.jl:41-42](src/generator/Generators.jl:41) and the sniff is repeated in
  `top_level.jl`, `nested.jl`, `resolve_deps.jl`, `preprocessing.jl` and `system_deps.jl`.
- **Attributes**: `attribute_check` can only ask `hasAttrs(cursor)`
  ([preprocessing.jl:119](src/generator/preprocessing.jl:119)). libclang never says *which*
  attribute, so any attributed record degrades to an opaque padded-bytes layout.
- **Layout**: field offsets come from `getOffsetOf(type, name)` — a **by-name** API
  ([codegen.jl:311](src/generator/codegen.jl:311)) — which cannot address an unnamed field, hence
  the recursive descent around it. `getAlignOf` is imported into the module
  ([Generators.jl:14](src/generator/Generators.jl:14)) and **called nowhere**; alignment is never
  queried. Bitfields are capped at `@assert w <= 32`.

`Symbol`-keyed name resolution is the through-line. `resolve_dependency!` resolves a field's
type by looking a `Symbol` up in `dag.tags` then `dag.ids` then `dag.ids_extra`, with a
`# FIXME: in some cases, this system-header symbol is in dag.tags` fallback repeated in three
methods ([resolve_deps.jl:33](src/generator/resolve_deps.jl:33), `:69`, `:155`).

**This is the subject of [GENERATORS-REWORK.md](GENERATORS-REWORK.md)** — parsing all headers
into one shared `ASTContext` via ClangCompiler.jl makes every one of these problems disappear
rather than be solved better.

## The option contract

`load_options` is `TOML.parse` with **no schema and no validation**
([option.jl:1-2](src/generator/option.jl:1)), so a misspelled key is silently inert.
`test/test.toml:5` sets `extract_c_comment`, which nothing reads — the real key is
`extract_c_comment_style` — and the self-hosting test therefore generates no docstrings while
appearing to ask for them.

Options are read at exactly three nesting levels: `options["general"]`, `options["codegen"]`,
and `options["codegen"]["macro"]`. [gen/generator.toml](gen/generator.toml) is the de-facto
reference (~45 keys) and the docs point at it.

Three things to know before touching option handling:

1. **The options dict doubles as inter-pass scratch storage.** `ResolveDependency` writes then
   deletes `general["nested_tags"]`; `Codegen` writes then deletes `codegen["DAG_tags"]`,
   `"DAG_ids"`, `"DAG_ids_extra"`, `"nested_tags"`; `GeneralPrinter` writes then deletes
   `general["DAG_ids"]`; `Audit` writes `general["log"]["Audit_log"]` and never removes it.
   These share a namespace with user keys.
2. **Three keys have silent legacy aliases**: `output_ignorelist` ← `printer_blacklist`,
   `auto_mutability_ignorelist` ← `auto_mutability_blacklist`, `auto_mutability_includelist` ←
   `auto_mutability_whitelist`.
3. **Some defaults are not uniform across call sites.** `use_ccall_macro` defaults `false` for
   `FunctionProto`/`FunctionNoProto`/`AddFPtrMethods` but `true` for `FunctionVariadic`
   ([codegen.jl:87,127,153](src/generator/codegen.jl:87), [passes.jl:877](src/generator/passes.jl:877)).
   `minimum_macos_supported` is read from **both** `[general]` and `[codegen]`.

There is also an undocumented `[general.log]` sub-table of 23 per-pass booleans named
`<PassName>_log`, each defaulting to that pass's constructor `info=` value.

Options implemented but documented nowhere: `no_audit`, `link_enum_alias`,
`union_single_constructor`, `generate_isystem_symbols`, `output_exclusivelist`.

## Tests: what is actually pinned

`test/runtests.jl` runs `jllenvs.jl`, `file.jl`, `generators.jl`, `module.jl`, `test_mpi.jl`,
`test_bitfield.jl`. `test/ClangTests.jl` is a ReTest wrapper that is commented out and whose
dependency is not in `test/Project.toml` — dead code.

The regression bar is a corpus of ~30 small headers under `test/include/`, each attached to a
testset added in response to one GitHub issue or PR. **Most testsets assert only that the
pipeline completes** — `@test_logs (:info, "Done!") match_mode=:any build!(ctx)`. The ones that
pin real behaviour are worth knowing because they are what a refactor must not break:

- **Self-hosting**: the top-level `"Generators"` testset runs `detect_headers` over
  `Clang_unified_jll`'s `include/clang-c`, builds, applies `test/rewriter.jl`, and prints.
- **Exact `Expr` equality**: `large-integer-literals.h` pins `:(const TEST = Culong(0x80000001))`.
- **Exact emitted text**: `elaborateEnum.h` (`PR 522`) and `objectiveC.h` (macOS-only).
- **Node markers at fixed DAG positions**: `ctx.dag.nodes[6]`, `nodes[end]`, `nodes[end-1]` in
  the `#529`/`#535`/`#536` testsets. **These pin node *ordering*, which is precisely what a
  pipeline rework changes** — expect to re-express them by id rather than by index.
- **Behaviour of the loaded module**: `propertynames`, record constructors, docstrings.
- **A real compiled C library**: `test_bitfield.jl` CMake-builds `test/bitfield/bitfield.c` and
  round-trips a bitfield struct. Note it swallows failures with a `@warn` unless `ENV["CI"]` is
  set.
- **Duplicate handling across headers**: `a.h` and `dup_a.h` are byte-identical (`Issue 392`).
- **Audit as a hard failure**: `enum.h` pins `@test_throws Exception build!(ctx)`.

Four testsets bypass `Generators` entirely and drive raw libclang (`void-type.h`,
`return-funcptr.h`, the `parse_headers()` lifetime contract).

Known-broken and recorded as such: `nested-declaration.h` (`@test_broken` around a `try/catch`),
three record-constructor assertions, two ObjC assertions.

CI runs Julia 1.11 / 1 / pre / nightly × {ubuntu, macOS, windows} × {x64, x86}, plus macOS
aarch64. An assertion on anything the *runner* decides — pointer width, `Clong`, path
separators — is invisible locally and red on CI.

## Conventions

- The generator uses **libclang's camelCase names** for anything wrapping a C function
  (`getCursorType`, `isCursorDefinition`) and snake_case for its own helpers
  (`collect_top_level_nodes!`, `resolve_dependency!`).
- Passes are **callable structs**: `mutable struct Foo <: AbstractPass` with a
  `(x::Foo)(dag::ExprDAG, options::Dict)` method, a keyword constructor taking `info=`, and a
  `show_info` field read back out of `options["general"]["log"]["Foo_log"]`. Four passes
  (`CatchDuplicatedAnonymousTags`, `LinkEnumAlias`, `AddFPtrMethods`, `CodegenPostprocessing`)
  do not return `dag`; `build!` discards return values, so this is currently harmless.
- `Generators` uses `export`, not `public` — it exports 60+ names including every pass type.
- New node-type markers go in `types.jl` beside their family, with the matching
  `is_*`/`dup_type`/`default_type` methods.

## Notes

- `gen/generator.jl` cannot express its own needs in TOML: it splits the build into
  `BUILDSTAGE_NO_PRINTING`, hand-rewrites the DAG to inject a deprecation `@warn` into two
  functions, and stores a Julia `Function` under `options["general"]["callback_documentation"]`
  in the same dict as TOML scalars. ClangCompiler's driver does the same kind of thing — it
  re-reads the 43k-line generated file and regex-rewrites `mutable struct (CX\w+Impl) end` to
  add a supertype. Both are signals that the option surface is under-expressive.
- `src/generator/preprocessing.jl` contains no preprocessing. It is the codegen classifier.
- `MAX_CIRCIR_DETECTION_COUNT` ([passes.jl:372](src/generator/passes.jl:372)) is misspelled and
  is a real 100000-iteration budget: `RemoveCircularReference` restarts its DFS from scratch
  every time it breaks a single cycle.
