module Clang
    export cindex
    export wrap_c
    export wrap_cpp

    include(joinpath("..", "deps", "ext.jl"))
    include("cindex.jl")
    include("wrap_c.jl")
    include("wrap_cpp.jl")
end
