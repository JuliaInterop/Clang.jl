# cxx/ — the ClangCompiler-backed generator

Staging area for the new pipeline. These modules depend only on ClangCompiler and are tested by
standalone scripts, because ClangCompiler and Clang.jl cannot share a process until libclang is
removed from `src/` (GENERATORS-REWORK.md §3.4).

    CxxFacts.jl    extract   — one reachability walk over the AST -> nodes of FACTS + edges
    CxxOrder.jl    order     — emission order + a cut set (edge and degraded field, together)
    CxxCodegen.jl  codegen   — facts -> Julia
    CxxMacros.jl   macros    — clang parses each macro body; the typed AST is translated

## Running the validators

Needs an environment with ClangCompiler **and** CEnum, carrying ClangCompiler's
`LocalPreferences.toml` — without it the released `libclangex_jll` loads instead of the local
build and symbols fail at call time:

    mkdir -p /tmp/cxxenv && cd /tmp/cxxenv
    julia --project=. -e 'using Pkg; Pkg.develop(path="/path/to/ClangCompiler"); Pkg.add("CEnum")'
    cp /path/to/ClangCompiler/LocalPreferences.toml .

    julia --project=/tmp/cxxenv cxx/validate_facts.jl          # extraction vs the ABI baseline
    julia --project=/tmp/cxxenv cxx/validate_order.jl          # ordering on the cycle fixtures
    julia --project=/tmp/cxxenv cxx/validate_order_libxml2.jl  # ordering at scale
    julia --project=/tmp/cxxenv cxx/validate_e2e.jl            # generate + load + ABI compare
