using Test

# Tests for cxx/CxxMacros.jl -- macro translation via clang's C++ API.
#
# These MUST run in a subprocess. Clang.jl loads libclang from Clang_unified_jll and
# ClangCompiler.jl loads clang-cpp via libclangex; both statically register LLVM's global
# CommandLine options, so importing the second into a process that has the first aborts with
#
#     julia: CommandLine Error: Option 'sanitizer-early-opt-ep' registered more than once!
#
# in either order. Since this test file is included by runtests.jl, which has already loaded
# Clang, the only way to exercise CxxMacros is to shell out.
#
# Set CLANG_JL_CXX_PROJECT to a project path that has ClangCompiler to enable them:
#
#     CLANG_JL_CXX_PROJECT=/path/to/ClangCompiler julia --project -e 'using Pkg; Pkg.test()'

const CXX_PROJECT = get(ENV, "CLANG_JL_CXX_PROJECT", "")

@testset "CxxMacros (clang C++ API)" begin
    if isempty(CXX_PROJECT)
        @info """Skipping CxxMacros tests: set CLANG_JL_CXX_PROJECT to a project with
                 ClangCompiler installed to run them. They cannot share this process with
                 Clang.jl -- see the comment at the top of test/cxx_macros.jl."""
        @test_skip false
    else
        script = """
        include(joinpath($(repr(dirname(@__DIR__))), "cxx", "CxxMacros.jl"))
        using .CxxMacros
        res = translate_macros([$(repr(joinpath(@__DIR__, "include", "large-integer-literals.h")))])
        byname = Dict(String(r.name) => r for r in res)
        # C11 6.4.4.1p5 typing, deduced by clang rather than reimplemented
        @assert byname["TEST"].folded == 2147483649        "TEST: \$(byname["TEST"])"
        @assert byname["TEST_2"].folded == 2147483649      "TEST_2"
        @assert byname["TEST_SIGNED"].folded == 1          "TEST_SIGNED"
        @assert byname["TEST_SIGNED_2"].folded == 2147483646 "TEST_SIGNED_2"

        res2 = translate_macros([$(repr(joinpath(@__DIR__, "include", "macro.h")))])
        n2 = Dict(String(r.name) => r for r in res2)
        # clang refuses these, which is the correct outcome and needs no heuristic of ours
        @assert n2["GINTBIG_MAX"] isa MacroSkipped         "GINTBIG_MAX should be skipped"
        @assert n2["UCS_EMPTY_STATEMENT"] isa MacroSkipped "brace body should be skipped"
        @assert n2["__cdecl"] isa MacroSkipped             "empty macro should be skipped"
        @assert n2["foo"] isa MacroSkipped                 "self-referential macro should be skipped"
        # ...and translates these
        @assert n2["S"].expr == "abcdef"                   "adjacent string literals"
        @assert n2["EL"].expr == "DCAP_NONSPATIAL"         "string literal"
        println("CXXMACROS_OK")
        """
        out = try
            read(`$(Base.julia_cmd()) --project=$CXX_PROJECT -e $script`, String)
        catch err
            "SUBPROCESS FAILED: $err"
        end
        @test occursin("CXXMACROS_OK", out)
    end
end
