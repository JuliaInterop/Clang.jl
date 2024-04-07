module Clang

include("platform/JLLEnvs.jl")
using .JLLEnvs

llvm_version = if Base.libllvm_version < v"13"
    "12"
elseif Base.libllvm_version.major == 13
    "13"
elseif Base.libllvm_version.major == 14
    "14"
elseif Base.libllvm_version.major == 15
    "15"
elseif Base.libllvm_version.major == 16
    "16"
else
    "16"
end

libdir = joinpath(@__DIR__, "..", "lib")

include(joinpath(libdir, llvm_version, "LibClang.jl"))
using .LibClang

include("cltypes.jl")
export CLCursor, CLType, CLToken
foreach(names(@__MODULE__; all=true)) do s
    x = getfield(@__MODULE__, s)
    if x isa DataType && supertype(x) in [CLCursor, CLType, CLToken]
        @eval export $s
    end
end

include("string.jl")

include("index.jl")
export Index

include("trans_unit.jl")
export TranslationUnit, spelling, parse_header, parse_headers

include("cursor.jl")
export kind, name, spelling, value
export get_filename, get_file_line_column, get_function_args
export is_typedef_anon, is_forward_declaration, is_inclusion_directive
export search, children

include("type.jl")
export has_elaborated_reference, has_elaborated_tag_reference, get_elaborated_cursor
export has_function_reference
export fields

include("token.jl")
export TokenList, tokenize

include("dump.jl")
export dumpobj

include("compiledb.jl")
export CLCompilationDatabase

function version()
    cxstr = clang_getClangVersion()
    ptr = clang_getCString(cxstr)
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    return s
end

const LLVM_VERSION = match(r"[0-9]+.[0-9]+.[0-9]+", version()).match
const LLVM_DIR = normpath(joinpath(dirname(LibClang.Clang_jll.libclang_path), ".."))
const LLVM_LIBDIR = joinpath(LLVM_DIR, "lib")
const LLVM_INCLUDE = joinpath(LLVM_LIBDIR, "clang", LLVM_VERSION, "include")
const CLANG_INCLUDE = LLVM_INCLUDE

export LLVM_VERSION, LLVM_LIBDIR, LLVM_INCLUDE, CLANG_INCLUDE

include("generator/Generators.jl")
using .Generators

end
