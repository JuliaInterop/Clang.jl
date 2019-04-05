"""
    TranslationUnit(idx, source, args)
    TranslationUnit(idx, source, args, unsavedFiles, options)
Parse the given source file and the translation unit corresponding to that file.
"""
mutable struct TranslationUnit
    ptr::CXTranslationUnit
    idx::Index
    function TranslationUnit(idx::Index, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options)
        ptr = clang_parseTranslationUnit(idx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options)
        @assert ptr != C_NULL "failed to parse file: $source_filename"
        obj = new(ptr, idx)
        finalizer(obj) do x
            if x.ptr != C_NULL
                clang_disposeTranslationUnit(x)
                x.ptr = C_NULL
            end
        end
        return obj
    end
end
TranslationUnit(idx, source, args, unsavedFiles, options) = TranslationUnit(idx, source, args, length(args), unsavedFiles, length(unsavedFiles), options)
TranslationUnit(idx, source, args, options) = TranslationUnit(idx, source, args, length(args), C_NULL, 0, options)
TranslationUnit(idx, source, args) = TranslationUnit(idx, source, args, length(args), C_NULL, 0, CXTranslationUnit_None)

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
    getcursor(tu::TranslationUnit) -> CLCursor
    getcursor(tu::CXTranslationUnit) -> CXCursor
Return the cursor that represents the given translation unit.
"""
getcursor(tu::CXTranslationUnit) = clang_getTranslationUnitCursor(tu)
getcursor(tu::TranslationUnit)::CLCursor = clang_getTranslationUnitCursor(tu)

## TODO:
# clang_parseTranslationUnit2
# clang_createTranslationUnit2
# clang_parseTranslationUnit2FullArgv
# clang_saveTranslationUnit
# clang_suspendTranslationUnit
# clang_defaultSaveOptions
# clang_defaultEditingTranslationUnitOptions
# clang_defaultReparseOptions
# clang_reparseTranslationUnit


# helper
"""
    parse_header(header::AbstractString; index::Index=Index(), args::Vector{String}=String[],
                 includes::Vector{String}=String[], flags=CXTranslationUnit_None) -> TranslationUnit
Return the TranslationUnit for a given header. This is the main entry point for parsing.
See also [`parse_headers`](@ref).

# Arguments
- `header::AbstractString`: the header file to parse.
- `index::Index`: CXIndex pointer (pass to avoid re-allocation).
- `args::Vector{String}`: compiler switches as string array, eg: ["-x", "c++", "-fno-elide-type"].
- `includes::Vector{String}`: vector of extra include directories to search.
- `flags`: bitwise OR of CXTranslationUnit_Flags.
"""
function parse_header(header::AbstractString; index::Index=Index(), args::Vector{String}=String[],
                      includes::Vector{String}=String[], flags=CXTranslationUnit_None)
    # TODO: support parsing in-memory with CXUnsavedFile arg
    #       to _parseTranslationUnit.jj
    #unsaved_file = CXUnsavedFile()
    !isfile(header) && throw(ArgumentError("$header not found."))

    !isempty(includes) && foreach(includes) do x
        push!(args, "-I", x)
    end

    return TranslationUnit(index, header, args, flags)
end

"""
    parse_headers(headers::Vector{String}; index::Index=Index(), args::Vector{String}=String[], includes::Vector{String}=String[],
        flags = CXTranslationUnit_DetailedPreprocessingRecord | CXTranslationUnit_SkipFunctionBodies) -> Vector{TranslationUnit}
Return a [`TranslationUnit`](@ref) vector for the given headers. See also [`parse_header`](@ref).
"""
parse_headers(headers::Vector{String}; index::Index=Index(), args::Vector{String}=String[],
    includes::Vector{String}=String[], flags=CXTranslationUnit_DetailedPreprocessingRecord |
    CXTranslationUnit_SkipFunctionBodies) = [parse_header(header; index=index, args=args,
                                                          includes=includes, flags=flags) for header in unique(headers)]
