# This is the test module for Clang.jl, intended for use by ReTest.jl. Note that
# it should be loaded with ReTest.load() instead of includet() because the files
# in the tests include() other files and that doesn't play well with
# Revise. See: https://juliatesting.github.io/ReTest.jl/stable/#Working-with-Revise
#
# Just adding test/ to LOAD_PATH doesn't work because of the Project.toml file,
# which makes Pkg treat the directory as a single package directory instead of a
# directory containing possibly multiple modules.

module ClangTests

__revise_mode__ = :eval

using ReTest

include("jllenvs.jl")
include("file.jl")
include("generators.jl")
include("module.jl")

include("test_mpi.jl")
include("test_bitfield.jl")

end
