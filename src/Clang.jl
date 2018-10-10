module Clang

include("LibClang.jl")
using .LibClang

using DataStructures

# visitor
function cu_children_visitor(cursor::CXCursor, parent::CXCursor, client_data::Ptr{Cvoid})
    list = unsafe_pointer_to_objref(client_data)
    push!(list, cursor)
    return CXChildVisit_Continue
end

# Module initialization function
function __init__()
    global cu_visitor_cb = @cfunction(cu_children_visitor, Cuint, (CXCursor, CXCursor, Ptr{Cvoid}))
end

include("index.jl")
include("translation_unit.jl")
include("cursor.jl")
include("type.jl")
include("token.jl")
include("show.jl")

# include("constants.jl")
# include("wrap_c.jl")
# export wrap_c_headers
# export WrapContext

function version()
    cxstr = clang_getClangVersion()
    ptr = clang_getCString(cxstr)
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    return s
end


end
