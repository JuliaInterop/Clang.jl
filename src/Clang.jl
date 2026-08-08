"""
    Clang

A C-header-to-Julia binding generator, built on Clang's C++ API through ClangCompiler.jl.

    ctx = create_context(headers, get_default_args(), load_options("generator.toml"))
    build!(ctx)

## What changed in this version

The package used to be two things: a libclang binding (`CXCursor`/`CXType` plus a hand-written
object layer of ~300 `CLCursor` subtypes) and a generator built on top of it. The libclang layer
is gone. Everything the generator needed from it — record layouts, canonical declarations,
anonymity, comments, macro definitions — Clang's C++ API answers directly, and most of the old
pipeline existed only to reconstruct those answers from what libclang could express.

The two cannot coexist in one process: libclang and clang-cpp each register LLVM's global
command-line options statically, so loading the second aborts with
`Option 'sanitizer-early-opt-ep' registered more than once!`. Dropping libclang is what makes
the C++ frontend usable at all, not a tidy-up.

`Clang.LibClang`, `CLCursor`, `CLType`, `parse_headers`, `children`, `spelling` and the rest of
the object layer no longer exist. Code that used Clang.jl to *walk an AST* rather than to
generate bindings should pin `Clang@0.19` or move to ClangCompiler.jl directly.
"""
module Clang

# The GCC-shard environment comes from ClangCompiler rather than a copy here. Both packages
# carried the same `platform/` directory and the same 262-entry `Artifacts.toml`; the only
# difference that had accumulated was comma spacing in `system.jl`. Re-exported so `Clang.JLLEnvs`
# keeps resolving.
using ClangCompiler: JLLEnvs

include("generator/Generators.jl")
using .Generators

end # module
