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
export isinlined, isbit, isdef, isvariadic, is_typedef_anon
export get_translation_unit, get_semantic_parent, get_lexical_parent, get_included_file
export getref, getdef
export kind, name, spelling, type, extent, value, location, filename
export canonical, underlying_type, integer_type, result_type, return_type, typedef_type
export bitwidth, argnum, argument, function_args
export search, children

include("type.jl")
export isvolatile, isrestrict, isvariadic, is_plain_old_data
export address_space, typedef_name, typedecl
export pointee_type, argtype, element_type, element_num
export resolve_type, get_named_type

include("token.jl")
export tokenize

include("show.jl")

include("constants.jl")
export RESERVED_WORDS, CLANG_JULIA_TYPEMAP, INT_CONVERSION

include("clang2julia.jl")
export CLANG_JULIA_TYPEMAP, INT_CONVERSION
export clang2julia, target_type, typesize

include("wrap_c.jl")
export wrap_header
export WrapContext, init

function version()
    GC.@preserve begin
        cxstr = clang_getClangVersion()
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end

const LLVM_VERSION = match(r"[0-9]+.[0-9]+.[0-9]+", version()).match
const LLVM_LIBDIR = joinpath(@__DIR__, "..", "deps", "usr", "lib") |> normpath
const LLVM_INCLUDE = joinpath(LLVM_LIBDIR, "clang", LLVM_VERSION, "include")

export LLVM_VERSION, LLVM_LIBDIR, LLVM_INCLUDE

end
