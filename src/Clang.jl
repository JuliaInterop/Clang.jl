module Clang

include("LibClang.jl")
using .LibClang

using DataStructures

include("index.jl")
export Index

include("translation_unit.jl")
export TranslationUnit, spelling, getcursor, parse_header

include("cursor.jl")
export isnull, isdecl, isref, isexpr, isstat, isattr, hasattr, isdef
export ispreprocessing, isunexposed, is_translation_unit, isfunctionlike, isbuiltin
export isinlined, isbit, isdef, isvariadic
export get_translation_unit, get_semantic_parent, get_lexical_parent, get_included_file
export getref, getdef
export kind, name, spelling, type, extent, value, location, filename
export canonical, underlying_type, integer_type, result_type, return_type, typedef_type
export bitwidth, argnum, argument, function_args
export search, children

include("type.jl")
export isvalid, isvolatile, isrestrict, isvariadic, is_plain_old_data
export address_space, typedef_name, typedecl
export pointee_type, argtype, element_type, element_num
export resolve_type

include("token.jl")
export tokenize

include("show.jl")

include("constants.jl")
include("wrap_c.jl")
export wrap_c_headers
export WrapContext, init

function version()
    cxstr = clang_getClangVersion()
    ptr = clang_getCString(cxstr)
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    return s
end

export version

end
