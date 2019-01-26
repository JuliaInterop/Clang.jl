module LibClang

import Libdl

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

using CEnum

include("ctypes.jl")
export Ctm, Ctime_t, Cclock_t

include(joinpath(@__DIR__, "..", "gen", "libclang_common.jl"))
include(joinpath(@__DIR__, "..", "gen", "libclang_api.jl"))

foreach(names(@__MODULE__, all=true)) do s
    if startswith(string(s), "CX") || startswith(string(s), "clang_")
        @eval export $s
    end
end

end # module
