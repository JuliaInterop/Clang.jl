module Clang

import Libdl
using DataStructures

# Load in `deps.jl`, complaining if it does not exist
const depsjl_path = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(depsjl_path)
    error("Clang was not build properly. Please run Pkg.build(\"Clang\").")
end
include(depsjl_path)

include("CEnum.jl")
using .CEnum

include(joinpath(@__DIR__, "..", "gen", "libclang_common.jl"))
include(joinpath(@__DIR__, "..", "gen", "libclang_api.jl"))

## visitor
function cu_children_visitor(cursor::CXCursor, parent::CXCursor, client_data::Ptr{Cvoid})
    list = unsafe_pointer_to_objref(client_data)
    push!(list, cursor)
    return CXChildVisit_Continue
end

# Module initialization function
function __init__()
    check_deps()
    global cu_visitor_cb = @cfunction(cu_children_visitor, Cuint, (CXCursor, CXCursor, Ptr{Cvoid}))
end

include("base.jl")
include("cindex.jl")
export parse_header, search, resolve_type, return_type, typedef_type, value, function_args
export children, cu_visitor_cb

include("constants.jl")
include("wrap_c.jl")
export wrap_c_headers
export WrapContext

end
