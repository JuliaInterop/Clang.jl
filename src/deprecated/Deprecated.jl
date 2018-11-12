module Deprecated

include("../../deps/deps.jl")

include("cindex.jl")
include("wrap_c.jl")
include("wrap_cpp.jl")

export cindex
export wrap_c
export wrap_cpp

end
