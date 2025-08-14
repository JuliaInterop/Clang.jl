"""
    TranslationUnit(idx, source, args)
    TranslationUnit(idx, source, args, unsavedFiles, options)
    TranslationUnit(f::Function, ...)

Parse the given source file and the translation unit corresponding to that
file. The function argument `f` for the do-constructor will be passed a single
`TranslationUnit` object that will not be GC'd while `f()` runs.

!!! warning
    This type is not memory safe. You *must* ensure that the object stays alive
    and is not garbage collected as long as you're using the translation
    unit, otherwise it may be GC'd and cause segfaults. Consider using the
    `TranslationUnit(f::Function, ...)` constructor for simplicity.
"""
mutable struct TranslationUnit
    ptr::CXTranslationUnit
    idx::Index
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

function TranslationUnit(f::Function, args...; kwargs...)
    tu = TranslationUnit(args...; kwargs...)
    GC.@preserve tu try
        f(tu)
    finally
        finalize(tu)
    end
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
Return the [`TranslationUnit`](@ref) for a given header. This is the main entry
point for parsing.

# Arguments
- `header::AbstractString`: the header file to parse.
- `index::Index`: CXIndex pointer (pass to avoid re-allocation).
- `args::Vector{String}`: compiler switches as string array, eg: ["-x", "c++", "-fno-elide-type"].
- `flags`: bitwise OR of CXTranslationUnit_Flags.

Consider using [`parse_header(::Function)`](@ref) to ensure that the
[`TranslationUnit`](@ref) is kept alive while in use.

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
    parse_header(f::Function, ...)

Do-method wrapper around [`parse_header(::Index)`](@ref) that will ensure that
the `TranslationUnit` object stays alive while `f()` is running, e.g.:
```julia
index = Index()
parse_header(index, "foo.h") do tu
    @show length(children(tu))
end
```
"""
function parse_header(f::Function, args...; kwargs...)
    tu = parse_header(args...; kwargs...)
    GC.@preserve tu try
        f(tu)
    finally
        finalize(tu)
    end
end

"""
    parse_headers(
        index::Index,
        headers::Vector{String},
        args::Vector{String}=[],
        flags=CXTranslationUnit_None,
    ) -> Vector{TranslationUnit}
Return a [`TranslationUnit`](@ref) vector for the given headers.

Consider using [`parse_headers(::Function)`](@ref) to ensure that the
[`TranslationUnit`](@ref)'s are kept alive while in use.

See also [`parse_header`](@ref).
"""
function parse_headers(
    index::Index,
    headers::Vector{String},
    args::Vector{String}=String[],
    flags=CXTranslationUnit_None,
)
    map(unique(headers)) do header
        parse_header(index, header, args, flags)
    end
end

"""
    parse_headers(f::Function, ...)

Do-method wrapper around [`parse_headers(::Index)`](@ref) that will ensure that
all the `TranslationUnit` objects stays alive while `f()` is running, e.g.:
```julia
index = Index()
parse_headers(index, ["foo.h", "bar.h"]) do tus
    @show length(tus)
end
```
"""
function parse_headers(f::Function, args...; kwargs...)
    tus = parse_headers(args...; kwargs...)
    GC.@preserve tus try
        f(tus)
    finally
        foreach(finalize, tus)
    end
end
