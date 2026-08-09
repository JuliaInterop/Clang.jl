# Testing this branch

This branch rebuilds the generator on Clang's C++ API via
[ClangCompiler.jl](https://github.com/Gnimuc/ClangCompiler.jl) and removes the libclang binding.
It is **not merged** and is developed in parallel with `master`. Feedback from real
`generator.toml` files is the point of it.

## Install

`ClangCompiler` is not in the General registry yet, so it has to be added first — otherwise
resolution fails with `ClangCompiler [06fc9500] has no known versions!`.

```julia
using Pkg
Pkg.add(url="https://github.com/Gnimuc/ClangCompiler.jl", rev="claude/issues-39-51")  # PR #52
Pkg.add(url="https://github.com/JuliaInterop/Clang.jl", rev="claude/generators-clang-cpp-api-02c8e6")
```

**Until `libclangex_jll` is bumped past 0.4, a local native build is also required** — the
released binary lacks the symbols ClangCompiler #52 added (the incremental parse driver and the
Objective-C surface, both of which this branch now uses):

```julia
run(`julia --project=ClangCompiler/deps ClangCompiler/deps/build_local.jl`)
```

That writes a `LocalPreferences.toml` telling ClangCompiler to load the local build. Once the
jll is released, this step disappears.

Do this in the environment your generator script already uses — the usual `gen/Project.toml`,
not your package's own environment. Clang.jl is a build-time tool; the generated `.jl` file has
no dependency on it. That also means testing this branch cannot disturb anything that consumes
your bindings, and `Pkg.rm` plus a normal `Pkg.add("Clang")` puts you back.

Requires **Julia 1.12+**.

## What should just work

`create_context`, `build!`, `load_options`, `detect_headers`, `get_default_args` and the
`BUILDSTAGE_*` split are unchanged, and 32 `generator.toml` keys keep their existing names and
tables. Most scripts should run untouched. If yours does not, that is the bug worth reporting.

## What changed

| before | now |
| --- | --- |
| `ctx.dag`, `get_nodes(dag)`, `node.exprs` | `ctx.nodes` — a plain `Vector{Node}` of facts; rewriters are `filter!`/`map` |
| `@add_def time_t` and friends | nothing to do; `uint32_t`, `size_t`, `time_t` … map to Julia types automatically |
| `Clang.LibClang`, `CLCursor`, `parse_headers`, `children`, `spelling` | gone — use [LibClang.jl](https://github.com/Gnimuc/LibClang.jl), or pin `Clang = "0.19"` |
| LLVM 16–21, selectable | LLVM 18, whichever your Julia ships |
| Julia 1.11 | Julia 1.12 |

A rewriter now edits facts rather than expressions:

```julia
build!(ctx, BUILDSTAGE_NO_PRINTING)
filter!(n -> !occursin("internal", n.file), ctx.nodes)
build!(ctx, BUILDSTAGE_PRINTING_ONLY)
```

## Known gaps

- **Objective-C is supported again** (ClangCompiler #52 supplied the surface;
  [OBJC-REQUIREMENTS.md](OBJC-REQUIREMENTS.md) was the mapping): `@objcwrapper` /
  `@objcproperties` output with supertypes, protocol conformance, availability, and
  explicit getters/setters, requested the historical way — `push!(args, "-x", "objective-c")`.
  The output *text* is tested; loading it needs ObjectiveC.jl in your own environment.
  ObjC **generics** remain unsupported, as they were before (`NSArray<T> *` assertions were
  `broken=true` from the day they were written).
- Wide string literal macros (`#define SL L"…"`, issue #357) now translate instead of being
  skipped.
- A header set that does not parse cleanly now produces **one warning with the clang messages
  attached** instead of a stream of stderr noise — and the messages are real: the parse-failure
  signal was unusable before ClangCompiler #52.
- Unimplemented `generator.toml` keys: `output_exclusivelist`, `union_single_constructor`,
  `link_enum_alias`, `no_audit`, the `[general.log]` sub-table, and
  `function_argument_conflict_symbols` (subsumed — parameters are renamed on real collision
  rather than from a list).
- Every option is tested in isolation, so **no pair of options is known to compose**.
- Cross-target generation is verified for `x86_64-linux-gnu`, `x86_64-w64-mingw32` and
  `i686-linux-musl`: both the target ABI and — the part that was silently wrong until now —
  that typedefs resolve through the **target's** headers rather than the host's.
- `"doxygen"` comment rendering carries the same information as before but is not
  character-identical to the old pass.

## What is most useful to report

1. **Your `generator.toml` fails, or produces something that will not load.** Highest value.
2. **A layout differs from the old output.** Please say which type — this branch checks every
   emitted type against the `ASTRecordLayout` clang computed for it (`test/abi.jl`), so a
   disagreement is interesting either way: it found several layouts the *old* generator got
   silently wrong, including under-aligned bitfield structs and `_Nullable`/`const`-qualified
   fields that were being emitted as zero-sized.
3. **A macro that used to translate and no longer does** — or vice versa. Macros are now parsed
   as C by clang rather than re-lexed, so both directions are possible.
4. Readability regressions in the generated file. Output is not byte-identical to `master` by
   design, but it should not be *worse* to read.

To see what the suite already covers:

```bash
julia --project -e 'using Pkg; Pkg.test()'
```
