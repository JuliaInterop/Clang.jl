include(joinpath(Pkg.dir(), "Clang", "deps", "ext.jl"))

module Clang
    export cindex
    export wrap_c
    export wrap_cpp

    include("cindex.jl")
    include("wrap_c.jl")
    include("wrap_cpp.jl")
end
