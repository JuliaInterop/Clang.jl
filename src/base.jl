## Index
"""
    Index(excludeDeclsFromPCH, displayDiagnostics)
Provide a shared context for creating translation units.

# Arguments
- `excludeDeclsFromPCH`: whether to allow enumeration of "local" declarations.
- `displayDiagnostics`: whether to display diagnostics.
"""
mutable struct Index
    ptr::CXIndex
    excludeDeclsFromPCH::Cint
    displayDiagnostics::Cint
    function Index(excludeDeclsFromPCH, displayDiagnostics)
        ptr = clang_createIndex(excludeDeclsFromPCH, displayDiagnostics)
        @assert ptr != C_NULL
        obj = new(ptr, excludeDeclsFromPCH, displayDiagnostics)
        finalizer(obj) do x
            if x.ptr != C_NULL
                clang_disposeIndex(x.ptr)
                x.ptr = C_NULL
            end
        end
        return obj
    end
end
Index() = Index(false, true)


## TranslationUnit
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
            ptr = clang_parseTranslationUnit(idx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options)
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
TranslationUnit(idx, source, args, unsavedFiles, options) = TranslationUnit(cidx, source, args, length(args), unsavedFiles, length(unsavedFiles), options)
TranslationUnit(idx, source, args) = TranslationUnit(cidx, source, args, length(args), C_NULL, 0, CXTranslationUnit_None)

"""
    getcursor(tu) -> CXCursor
    getcursor(tu::TranslationUnit) -> CXCursor
Return the cursor that represents the given translation unit.
"""
getcursor(tu) = clang_getTranslationUnitCursor(tu)
getcursor(tu::TranslationUnit) = getcursor(tu.ptr)

"""
    name(tu::TranslationUnit) -> String
Return the original translation unit source file name.
"""
function name(tu::TranslationUnit)
    GC.@preserve tu begin
        cxstr = clang_getTranslationUnitSpelling(tu.ptr)
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end


## Cursor
"""
    isnull(c::CXCursor) -> Bool
Return true if cursor is null.
"""
isnull(c::CXCursor) = clang_Cursor_isNull(c) != 0

"""
    type(c::CXCursor) -> CXType
Return the type of a CXCursor (if any).
"""
type(c::CXCursor) = clang_getCursorType(c)

"""
    result_type(c::CXCursor) -> CXType
Return the return type associated with a given cursor. This only returns a valid type if
the cursor refers to a function or method.
"""
result_type(c::CXCursor) = clang_getCursorResultType(c)

"""
    kind(c::CXCursor) -> CXCursorKind
Return the kind of the given cursor.
"""
kind(c::CXCursor) = clang_getCursorKind(c)

"""
    location(c::CXCursor) -> CXSourceLocation
Return the physical location of the source constructor referenced by the given cursor.
"""
location(c::CXCursor) = clang_getCursorLocation(c)

"""
    filename(c::CXCursor) -> String
Return the complete file and path name of the given file.
"""
function filename(c::CXCursor)
    file = Ref{CXFile}(C_NULL)
    line = Ref{Cuint}(0)
    column = Ref{Cuint}(0)
    offset = Ref{Cuint}(0)
    GC.@preserve c begin
        location = clang_getCursorLocation(cursor)
        clang_getExpansionLocation(location, file, line, column, offset)
        cxstr = clang_getFileName(file[])
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end

"""
    name(c::CXCursor) -> String
Return the display name for the entity referenced by this cursor.
"""
function name(c::CXCursor)
    GC.@preserve c begin
        cxstr = clang_getCursorDisplayName(c)
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end

"""
    spelling(c::CXCursor) -> String
Return a name for the entity referenced by this cursor.
"""
function spelling(c::CXCursor)
    GC.@preserve c begin
        cxstr = clang_getCursorSpelling(c)
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end


## Type
"""
    pointee_type(t::CXType) -> CXType
Return the type of the pointee for pointer types.
"""
pointee_type(t::CXType) = clang_getPointeeType(t)

"""
    kind(t::CXType) -> CXTypeKind
Return the kind of the given type.
"""
kind(t::CXType) = CXTypeKind(t.kind)

"""
    isvalid(t::CXType) -> Bool
Return true if the type is a valid type.
"""
isvalid(t::CXType) = kind(t) != CXType_Invalid

"""
    spelling(kind::CXTypeKind) -> String
Return the spelling of a given CXTypeKind.
"""
function spelling(kind::CXTypeKind)
    GC.@preserve kind begin
        cxstr = clang_getTypeKindSpelling(kind)
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end

name(t::CXType) = spelling(kind(t))

"""
    typedecl(t::CXType) -> CXCursor
Return the cursor for the declaration of the given type.
"""
typedecl(t::CXType) = clang_getTypeDeclaration(t)


## Token
struct TokenList
    ptr::Ptr{CXToken}
    size::Cuint
    tu::TranslationUnit
    function TokenList(tu::TranslationUnit, sr::CXSourceRange)
        GC.@preserve tu sr begin
            ptr = Ref{Ptr{CXToken}}(C_NULL)
            num = Ref{Cuint}(0)
            clang_tokenize(tu.ptr, sr, ptr, num)
            @assert ptr != C_NULL
            obj = new(ptr, num[], tu)
        end
        finalizer(obj) do x
            if x.ptr != C_NULL
                clang_disposeTokens(x.tu.ptr, x.ptr, x.size)
                x.ptr = C_NULL
            end
        end
        return obj
    end
end

Base.firstindex(x::TokenList) = 1
Base.lastindex(x::TokenList) = length(x)
Base.length(x::TokenList) = x.size
Base.iterate(x::TokenList, state=1) = state > x.size ? nothing : (x[state], state+1)

function Base.getindex(x::TokenList, i::Integer)
    checkindex(Bool, 1:length(x), i) && throw(ArgumentError("BoundsError: TokenList miss at index $i"))
    GC.@preserve x begin
        token = unsafe_load(x.ptr, i)
    end
    return token
end

"""
    tokenize(c::CXCursor) -> TokenList
Return a TokenList from the given cursor.
"""
function tokenize(c::CXCursor)
    tu = clang_Cursor_getTranslationUnit(c)
    sourcerange = clang_getCursorExtent(c)
    return TokenList(tu, sourcerange)
end

"""
    kind(token::CXToken) -> CXTokenKind
Return the kind of the given token.
"""
kind(token::CXToken) = clang_getTokenKind(token)

"""
    spelling(tu::TranslationUnit, token::CXToken) -> String
Return the spelling of the given token. The spelling of a token is the textual
representation of that token, e.g., the text of an identifier or keyword.
"""
function spelling(tu::TranslationUnit, token::CXToken)
    GC.@preserve c begin
        cxstr = clang_getTokenSpelling(tu, token)
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end



###############################################################################
# Container types
#   for now we use these as the element type of the target array
###############################################################################

# Generate container types
#for st in Any[
#        :CXTUResourceUsageEntry, :CXTUResourceUsage ]
#    sz_name = Symbol(st, "_size")
#    st_base = Symbol("_", st)
#    @eval begin
#        const $sz_name = get_sz($("$st"))
#        struct $(st)
#            data::Array{$st_base,1}
#            $st(d) = new(d)
#        end
#        $st() = $st(Array($st_base, 1))
#        $st(d::$st_base) = $st([d])
#    end
#end
