using Clang
using Test

# Temporary hack to make @doc work in 1.11 for the documentation tests. See:
# https://github.com/JuliaLang/julia/issues/52986
using REPL

include("file.jl")
include("generators.jl")

include("test_mpi.jl")
include("test_bitfield.jl")
