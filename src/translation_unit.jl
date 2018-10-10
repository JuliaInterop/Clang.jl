"""
    TranslationUnit(idx, source, args)
    TranslationUnit(idx, source, args, unsavedFiles, options)
Parse the given source file and the translation unit corresponding to that file.
"""
mutable struct TranslationUnit
    ptr::CXTranslationUnit
    idx::Index
    function TranslationUnit(idx::Index, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options)
        GC.@preserve idx begin
            ptr = clang_parseTranslationUnit(idx.ptr, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options)
            @assert ptr != C_NULL "failed to parse file: $source_filename"
            obj = new(ptr, idx)
        end
        finalizer(obj) do x
            if x.ptr != C_NULL
                clang_disposeTranslationUnit(x.ptr)
                x.ptr = C_NULL
            end
        end
        return obj
    end
end
TranslationUnit(idx, source, args, unsavedFiles, options) = TranslationUnit(idx, source, args, length(args), unsavedFiles, length(unsavedFiles), options)
TranslationUnit(idx, source, args) = TranslationUnit(idx, source, args, length(args), C_NULL, 0, CXTranslationUnit_None)

"""
    spelling(tu::TranslationUnit) -> String
Return the original translation unit source file name.
"""
function spelling(tu::TranslationUnit)
    GC.@preserve tu begin
        cxstr = clang_getTranslationUnitSpelling(tu.ptr)
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end


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
    parse_header(header::AbstractString; index=nothing, diagnostics=true, cplusplus=false,
                 args=String[], includes=String[], flags=CXTranslationUnit_None) -> TranslationUnit
Return the TranslationUnit for a given header. This is the main entry point for parsing.

# Arguments
- `header::AbstractString`: the header file to parse.
- `index::Union{Index,Nothing}`: CXIndex pointer (pass to avoid re-allocation).
- `diagnostics::Bool`: display Clang diagnostics.
- `cplusplus::Bool`: parse as C++.
- `args::Vector{String}`: compiler switches as string array, eg: ["-x", "c++", "-fno-elide-type"].
- `includes::Vector{String}`: vector of extra include directories to search.
- `flags::UInt32`: bitwise OR of CXTranslationUnit_Flags.
"""
function parse_header(header::AbstractString; index::Union{Index,Nothing}=nothing, diagnostics::Bool=true,
    cplusplus::Bool=false, args::Vector{String}=String[], includes::Vector{String}=String[], flags::UInt32=CXTranslationUnit_None)
    # TODO: support parsing in-memory with CXUnsavedFile arg
    #       to _parseTranslationUnit.jj
    #unsaved_file = CXUnsavedFile()
    !isfile(header) && throw(ArgumentError(header, " not found"))

    index == nothing && (index = CIndex(false, diagnostics);)

    cplusplus && append!(args, ["-x", "c++"])

    !isempty(includes) && foreach(includes) do x
        push!(args, "-I", x)
    end

    return TranslationUnit(index, header, args)
end
