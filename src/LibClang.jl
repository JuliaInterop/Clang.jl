module LibClang

using Clang_jll
export Clang_jll

using CEnum

include("ctypes.jl")
export Ctm, Ctime_t, Cclock_t

include(joinpath(@__DIR__, "..", "gen", "libclang_common.jl"))
include(joinpath(@__DIR__, "..", "gen", "libclang_api.jl"))

foreach(names(@__MODULE__; all=true)) do s
    if startswith(string(s), "CX") || startswith(string(s), "clang_")
        @eval export $s
    end
end

end # module
