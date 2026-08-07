using Test
using Clang

# Temporary hack to make @doc work in 1.11 for the documentation tests. See:
# https://github.com/JuliaLang/julia/issues/54664
using REPL

@testset verbose=true "Clang.jl" begin
    @testset "JLLEnvs" begin
        include("jllenvs.jl")
    end
    @testset "Generators" begin
        include("generators.jl")
    end
    @testset "Ordering" begin
        include("ordering.jl")
    end
    @testset "Macros" begin
        include("macros.jl")
    end
    @testset "Options" begin
        include("options.jl")
    end
    # The strongest check in the suite: every emitted type against the `ASTRecordLayout` clang
    # computed for the same declaration. Third-party corpora run only where their artifacts
    # exist, and say so out loud when they do not.
    @testset "ABI" begin
        include("abi.jl")
    end
    @testset "MPI" begin
        include("test_mpi.jl")
    end
    @testset "Bitfields" begin
        include("test_bitfield.jl")
    end
end
