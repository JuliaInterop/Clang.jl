using Clang
using Test
using Pkg

include("generators.jl")

include("test_mpi.jl")
Pkg.build("CMake")
include("test_bitfield.jl")
