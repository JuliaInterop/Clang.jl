using Test
import Clang

# Temporary hack to make @doc work in 1.11 for the documentation tests. See:
# https://github.com/JuliaLang/julia/issues/54664
using REPL

include("jllenvs.jl")
include("file.jl")
include("generators.jl")
include("module.jl")

include("test_mpi.jl")
include("test_bitfield.jl")

# ReTest.jl is disabled for now because it doesn't support Julia 1.13
# include("ClangTests.jl")
# retest(Clang, ClangTests; stats=true)
