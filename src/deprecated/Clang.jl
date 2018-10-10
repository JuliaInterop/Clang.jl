module Clang

# Load in `deps.jl`, complaining if it does not exist
const depsjl_path = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(depsjl_path)
    error("Clang was not build properly. Please run Pkg.build(\"Clang\").")
end
include(depsjl_path)
# Module initialization function
function __init__()
    check_deps()
end

include("cindex.jl")
include("wrap_c.jl")
include("wrap_cpp.jl")

export cindex
export wrap_c
export wrap_cpp

end
