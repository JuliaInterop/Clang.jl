"""
    TranslationUnit(idx, source, args)
    TranslationUnit(idx, source, args, unsavedFiles, options)
Parse the given source file and the translation unit corresponding to that file.
"""
mutable struct TranslationUnit
    ptr::CXTranslationUnit
    idx::Index
    
    function TranslationUnit(
        ptr::CXTranslationUnit,
        idx::Index,
    )
        @assert ptr != C_NULL 
        obj = new(ptr, idx)
        finalizer(obj) do x
            if x.ptr != C_NULL
                clang_disposeTranslationUnit(x)
                x.ptr = C_NULL
            end
        end
        return obj
    end

    function TranslationUnit(
        idx::Index,
        ast_filename::AbstractString,
    )
        ptr = clang_createTranslationUnit(
            idx,
            ast_filename)
        @assert ptr != C_NULL "failed to parse file: $ast_filename"
        return TranslationUnit(ptr, idx)
    end
            
    
    function TranslationUnit(
        idx::Index,
        source_filename,
        command_line_args,
        num_command_line_args,
        unsaved_files,
        num_unsaved_files,
        options,
    )
        ptr = clang_parseTranslationUnit(
            idx,
            source_filename,
            command_line_args,
            num_command_line_args,
            unsaved_files,
            num_unsaved_files,
            options,
        )
        @assert ptr != C_NULL "failed to parse file: $source_filename"
        return TranslationUnit(ptr, idx)
    end
end
function TranslationUnit(idx, source, args, unsavedFiles, options)
    return TranslationUnit(
        idx, source, args, length(args), unsavedFiles, length(unsavedFiles), options
    )
end
function TranslationUnit(idx, source, args, options)
    return TranslationUnit(idx, source, args, length(args), C_NULL, 0, options)
end
function TranslationUnit(idx, source, args)
    return TranslationUnit(
        idx, source, args, length(args), C_NULL, 0, CXTranslationUnit_None
    )
end

Base.unsafe_convert(::Type{CXTranslationUnit}, x::TranslationUnit) = x.ptr

"""
    spelling(tu::TranslationUnit) -> String
Return the original translation unit source file name.
"""
function spelling(tu::TranslationUnit)
    cxstr = clang_getTranslationUnitSpelling(tu)
    ptr = clang_getCString(cxstr)
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    return s
end

"""
    getTranslationUnitCursor(tu::TranslationUnit) -> CLCursor
    getTranslationUnitCursor(tu::CXTranslationUnit) -> CXCursor
Return the cursor that represents the given translation unit.
"""
getTranslationUnitCursor(tu::CXTranslationUnit) = clang_getTranslationUnitCursor(tu)
getTranslationUnitCursor(tu::TranslationUnit)::CLCursor = clang_getTranslationUnitCursor(tu)

## TODO:
# clang_createTranslationUnit
# clang_createTranslationUnit2
# clang_defaultEditingTranslationUnitOptions
# clang_parseTranslationUnit2
# clang_parseTranslationUnit2FullArgv
# clang_defaultSaveOptions
# clang_saveTranslationUnit
# clang_suspendTranslationUnit
# clang_defaultReparseOptions
# clang_reparseTranslationUnit
# clang_getTUResourceUsageName
# clang_getCXTUResourceUsage
# clang_disposeCXTUResourceUsage
# clang_getTranslationUnitTargetInfo
# clang_TargetInfo_dispose
# clang_TargetInfo_getTriple
# clang_TargetInfo_getPointerWidth

# helper
"""
    parse_header(
        index::Index,
        header::AbstractString,
        args::Vector{String}=[],
        flags=CXTranslationUnit_None,
    ) -> TranslationUnit
Return the TranslationUnit for a given header. This is the main entry point for parsing.

# Arguments
- `header::AbstractString`: the header file to parse.
- `index::Index`: CXIndex pointer (pass to avoid re-allocation).
- `args::Vector{String}`: compiler switches as string array, eg: ["-x", "c++", "-fno-elide-type"].
- `flags`: bitwise OR of CXTranslationUnit_Flags.

See also [`parse_headers`](@ref).
"""
function parse_header(
    index::Index,
    header::AbstractString,
    args::Vector{String}=String[],
    flags=CXTranslationUnit_None,
)
    # TODO: support parsing in-memory with CXUnsavedFile arg
    #       to _parseTranslationUnit.jj
    #unsaved_file = CXUnsavedFile()
    !isfile(header) && throw(ArgumentError("$header not found."))

    return TranslationUnit(index, header, args, flags)
end

"""
    parse_headers(
        index::Index,
        headers::Vector{String},
        args::Vector{String}=[],
        flags=CXTranslationUnit_None,
    ) -> Vector{TranslationUnit}
Return a [`TranslationUnit`](@ref) vector for the given headers.

See also [`parse_header`](@ref).
"""
function parse_headers(
    index::Index,
    headers::Vector{String},
    args::Vector{String}=[],
    flags=CXTranslationUnit_None,
)
    map(unique(headers)) do header
        parse_header(index, header, args, flags)
    end
end

"""
    load_ast(
        index::Index,
        ast_file::AbstractString,
    ) -> TranslationUnit
Return the [`TranslationUnit`](@ref) for a given precompiled header (aka an "ast file" in clang).

# Arguments
- `index::Index`: Index.
- `ast_file::AbstractString`: the ast file to load`.  
   Ast files can be generated using clang e.g. `clang t.h -emit-ast -o t.pch`
"""
function load_ast(
    index::Index,
    ast_file::AbstractString)
    TranslationUnit(index, ast_file)
end
