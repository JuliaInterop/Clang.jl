"""
    isnull(c::CXCursor) -> Bool
    isnull(c::CLCursor) -> Bool
Return true if cursor is null.
Wrapper for libclang's `clang_Cursor_isNull`.
"""
isnull(c::CXCursor) = clang_Cursor_isNull(c) != 0
isnull(c::CLCursor) = isnull(c.cursor)

"""
    getcursor() -> (NULL)CXCursor
Return the NULL CXCursor.
Wrapper for libclang's `clang_getNullCursor`.
"""
getcursor() = clang_getNullCursor()

# equality
Base.:(==)(c1::CXCursor, c2::CXCursor)::Bool = clang_equalCursors(c1, c2)
Base.hash(c::CXCursor) = clang_hashCursor(c)

"""
    kind(c::CXCursor) -> CXCursorKind
Return the kind of the given cursor.
Wrapper for libclang's `clang_getCursorKind`.
"""
kind(c::CXCursor) = clang_getCursorKind(c)

"""
    kind(c::CLCursor) -> CXCursorKind
Return the kind of the given cursor.
Note this method directly reads CXCursor's `kind` field, which won't invoke additional
`clang_getCursorKind` function calls.
"""
kind(c::CLCursor) = c.cursor.kind

"""
    isdecl(k::CXcursorKind) -> Bool
    isdecl(c::CLCursor) -> Bool
Return true if the given cursor kind represents a declaration.
Wrapper for libclang's `clang_isDeclaration`.
"""
isdecl(k::CXCursorKind)::Bool = clang_isDeclaration(k)
isdecl(c::CLCursor) = isdecal(kind(c))

"""
    isref(k::CXcursorKind) -> Bool
    isref(c::CLCursor) -> Bool
Return true if the given cursor kind represents a simple reference. Note that other kinds of
cursors (such as expressions) can also refer to other cursors. Use [`getref`](@ref) to determine
whether a particular cursor refers to another entity.
Wrapper for libclang's `clang_isReference`.
"""
isref(k::CXCursorKind)::Bool = clang_isReference(k)
isref(c::CLCursor) = isref(kind(c))

"""
    isexpr(k::CXcursorKind) -> Bool
    isexpr(c::CLCursor) -> Bool
Return true if the given cursor kind represents an expression.
Wrapper for libclang's `clang_isExpression`.
"""
isexpr(k::CXCursorKind)::Bool = clang_isExpression(k)
isexpr(c::CLCursor) = isexpr(kind(c))

"""
    isstat(k::CXcursorKind) -> Bool
    isstat(c::CLCursor) -> Bool
Return true if the given cursor kind represents a statement.
Wrapper for libclang's `clang_isStatement`.
"""
isstat(k::CXCursorKind)::Bool = clang_isStatement(k)
isstat(c::CLCursor) = isstat(kind(c))

"""
    isattr(k::CXcursorKind) -> Bool
    isattr(c::CLCursor) -> Bool
Return true if the given cursor kind represents an attribute.
Wrapper for libclang's `clang_isAttribute`.
"""
isattr(k::CXCursorKind)::Bool = clang_isAttribute(k)
isattr(c::CLCursor) = isattr(kind(c))

"""
    hasattr(c::CXCursor) -> Bool
    hasattr(c::CLCursor) -> Bool
Determine whether the given cursor has any attributes.
Wrapper for libclang's `clang_Cursor_hasAttrs`.
"""
hasattr(c::CXCursor)::Bool = clang_Cursor_hasAttrs(c)
hasattr(c::CLCursor) = hasattr(c.cursor)

"""
    isvalid(k::CXcursorKind) -> Bool
    isvalid(c::CLCursor) -> Bool
Return true if the given cursor kind represents an valid cursor.
Wrapper for libclang's `clang_isInvalid`.
"""
Base.isvalid(k::CXCursorKind) = !(Bool(clang_isInvalid(k)))
Base.isvalid(c::CLCursor) = isvalid(kind(c))

"""
    is_translation_unit(k::CXcursorKind) -> Bool
    is_translation_unit(c::CLCursor) -> Bool
Return true if the given cursor kind represents a translation unit.
Wrapper for libclang's `clang_isTranslationUnit`.
"""
is_translation_unit(k::CXCursorKind)::Bool = clang_isTranslationUnit(k)
is_translation_unit(c::CLCursor) = is_translation_unit(kind(c))

"""
    ispreprocessing(k::CXcursorKind) -> Bool
    ispreprocessing(c::CLCursor) -> Bool
Return true if the given cursor kind represents a preprocessing element, such as a
preprocessor directive or macro instantiation.
Wrapper for libclang's `clang_isPreprocessing`.
"""
ispreprocessing(k::CXCursorKind)::Bool = clang_isPreprocessing(k)
ispreprocessing(c::CLCursor) = ispreprocessing(kind(c))

"""
    isunexposed(k::CXcursorKind) -> Bool
Return true if the given cursor kind represents a currently unexposed piece of the AST
(e.g., CXCursor_UnexposedStmt).
Wrapper for libclang's `clang_isUnexposed`.
"""
isunexposed(k::CXCursorKind)::Bool = clang_isUnexposed(k)
isunexposed(c::CLCursor) = isunexposed(kind(c))

"""
    linkage(c::CXCursor) -> CXLinkageKind
    linkage(c::CLCursor) -> CXLinkageKind
Return the linkage of the entity referred to by a given cursor.
Wrapper for libclang's `clang_getCursorLinkage`.
"""
linkage(c::CXCursor)::CXLinkageKind = clang_getCursorLinkage(c)
linkage(c::CLCursor) = linkage(c.cursor)

## TODO:
# clang_getCursorVisibility
# clang_getCursorAvailability
# clang_getCursorPlatformAvailability
# clang_disposeCXPlatformAvailability
# clang_getCursorLanguage
# clang_getCursorTLSKind

"""
    get_translation_unit(c::CXCursor) -> CXTranslationUnit
    get_translation_unit(c::CLCursor) -> CXTranslationUnit
Returns the translation unit that a cursor originated from.
Wrapper for libclang's `clang_Cursor_getTranslationUnit`.
"""
get_translation_unit(c::CXCursor) = clang_Cursor_getTranslationUnit(c)
get_translation_unit(c::CLCursor) = get_translation_unit(c.cursor)

## TODO: this is mainly for internal debugging?
# clang_createCXCursorSet
# clang_disposeCXCursorSet
# clang_CXCursorSet_contains
# clang_CXCursorSet_insert

"""
    get_semantic_parent(c::CXCursor) -> CXCursor
    get_semantic_parent(c::CLCursor) -> CLCursor
Return the semantic parent of the given cursor. Please checkout libclang's doc to know more.
Wrapper for libclang's `clang_getCursorSemanticParent`.
"""
get_semantic_parent(c::CXCursor) = clang_getCursorSemanticParent(c)
get_semantic_parent(c::CLCursor)::CLCursor = get_semantic_parent(c.cursor)

"""
    get_lexical_parent(c::CXCursor) -> CXCursor
    get_lexical_parent(c::CLCursor) -> CLCursor
Return the lexical parent of the given cursor. Please checkout libclang's doc to know more.
Wrapper for libclang's `clang_getCursorLexicalParent`.
"""
get_lexical_parent(c::CXCursor) = clang_getCursorLexicalParent(c)
get_lexical_parent(c::CLCursor)::CLCursor = get_lexical_parent(c.cursor)

## TODO:
# clang_getOverriddenCursors
# clang_disposeOverriddenCursors

"""
    get_included_file(c::CXCursor) -> CXFile
    get_included_file(c::CLCursor) -> CXFile
Return the file that is included by the given inclusion directive cursor.
Wrapper for libclang's `clang_getIncludedFile`.
"""
get_included_file(c::CXCursor) = clang_getIncludedFile(c)
get_included_file(c::CLCursor) = get_included_file(c.cursor)

"""
    location(c::CXCursor) -> CXSourceLocation
    location(c::CLCursor) -> CXSourceLocation
Return the physical location of the source constructor referenced by the given cursor.
Wrapper for libclang's `clang_getCursorLocation`.
"""
location(c::CXCursor) = clang_getCursorLocation(c)
location(c::CLCursor) = location(c.cursor)

"""
    extent(c::CXCursor) -> CXSourceRange
    extent(c::CLCursor) -> CXSourceRange
Return the physical extent of the source construct referenced by the given cursor.

The extent of a cursor starts with the file/line/column pointing at the first character
within the source construct that the cursor refers to and ends with the last character
within that source construct. For a declaration, the extent covers the declaration itself.
For a reference, the extent covers the location of the reference (e.g., where the referenced
entity was actually used).
Wrapper for libclang's `clang_getCursorExtent`.
"""
extent(c::CXCursor) = clang_getCursorExtent(c)
extent(c::CLCursor) = extent(c.cursor)

"""
    type(c::CXCursor) -> CXType
    type(c::CLCursor) -> CLType
Return the type of a CXCursor (if any). To get the cursor from a type, see [`typedecl`](@ref).
Wrapper for libclang's `clang_getCursorType`.
"""
type(c::CXCursor) = clang_getCursorType(c)
type(c::CLCursor)::CLType = type(c.cursor)

"""
    underlying_type(c::CLTypedefDecl) -> CLType
Return the underlying type of a typedef declaration.
Wrapper for libclang's `clang_getTypedefDeclUnderlyingType`.
"""
underlying_type(c::CXCursor) = clang_getTypedefDeclUnderlyingType(c)
underlying_type(c::CLTypedefDecl)::CLType = underlying_type(c.cursor)

"""
    integer_type(c::CLEnumDecl) -> CLType
Retrieve the integer type of an enum declaration.
Wrapper for libclang's `clang_getEnumDeclIntegerType`.
"""
integer_type(c::CXCursor) = clang_getEnumDeclIntegerType(c)
integer_type(c::CLEnumDecl)::CLType = integer_type(c.cursor)

"""
    value(c::CLCursor) -> Int
Return the integer value of an enum constant declaration.
"""
function value(c::CLEnumConstantDecl)::Int
    typeKind = kind(type(c))
    if typeKind == CXType_Int || typeKind == CXType_Long || typeKind == CXType_LongLong
        return clang_getEnumConstantDeclValue(c.cursor)
    elseif typeKind == CXType_UInt || typeKind == CXType_ULong || typeKind == CXType_ULongLong
        return clang_getEnumConstantDeclUnsignedValue(c.cursor)
    end
    error("Unknown EnumConstantDecl type: ", typeKind, " cursor: ", kind(c))
end

"""
    bitwidth(c::CLFieldDecl) -> Int
Return the bit width of a bit field declaration as an integer.
Wrapper for libclang's `clang_getFieldDeclBitWidth`.
"""
bitwidth(c::CXCursor)::Int = clang_getFieldDeclBitWidth(c)
bitwidth(c::CLFieldDecl) = bitwidth(c.cursor)

"""
    argnum(c::CXCursor) -> Int
    argnum(c::CLCXXMethod) -> Int
    argnum(c::CLFunctionDecl) -> Int
Return the number of non-variadic arguments associated with a given cursor.
Wrapper for libclang's `clang_Cursor_getNumArguments`.
"""
argnum(c::CXCursor)::Int = clang_Cursor_getNumArguments(c)
argnum(c::CLFunctionDecl) = argnum(c.cursor)
argnum(c::CLCXXMethod) = argnum(c.cursor)

"""
    argument(c::CXCursor, i::Unsigned) -> CXCursor
    argument(c::CLFunctionDecl, i::Integer) -> CLCursor
    argument(c::CLCXXMethod, i::Integer) -> CLCursor
Return the argument cursor of a function or method.
Wrapper for libclang's `clang_Cursor_getArgument`.
"""
argument(c::CXCursor, i::Unsigned) = clang_Cursor_getArgument(c, i)
argument(c::CLFunctionDecl, i::Integer)::CLCursor = argument(c, Unsigned(i))
argument(c::CLCXXMethod, i::Integer)::CLCursor = argument(c, Unsigned(i))

## TODO:
# clang_Cursor_getNumTemplateArguments
# clang_Cursor_getTemplateArgumentKind
# clang_Cursor_getTemplateArgumentType
# clang_Cursor_getTemplateArgumentValue
# clang_Cursor_getTemplateArgumentUnsignedValue

"""
    isfunctionlike(c::CXCursor) -> Bool
    isfunctionlike(c::CLCursor) -> Bool
Determine whether a CXCursor that is a macro, is function like.
Wrapper for libclang's `clang_Cursor_isMacroFunctionLike`.
"""
isfunctionlike(c::CXCursor)::Bool = clang_Cursor_isMacroFunctionLike(c)
isfunctionlike(c::CLCursor) = isfunctionlike(c.cursor)

"""
    isbuiltin(c::CXCursor) -> Bool
    isbuiltin(c::CLCursor) -> Bool
Determine whether a  CXCursor that is a macro, is a builtin one.
Wrapper for libclang's `clang_Cursor_isMacroBuiltin`.
"""
isbuiltin(c::CXCursor)::Bool = clang_Cursor_isMacroBuiltin(c)
isbuiltin(c::CLCursor) = isbuiltin(c.cursor)

"""
    isinlined(c::CXCursor) -> Bool
    isinlined(c::CLCursor) -> Bool
Determine whether a CXCursor that is a function declaration, is an inline declaration.
Wrapper for libclang's `clang_Cursor_isFunctionInlined`.
"""
isinlined(c::CXCursor)::Bool = clang_Cursor_isFunctionInlined(c)
isinlined(c::CLCursor) = isinlined(c.cursor)

"""
    result_type(c::CXCursor) -> CXType
    result_type(c::CLFunctionDecl) -> CLType
    result_type(c::CLCXXMethod) -> CLType
Return the return type associated with a given cursor. This only returns a valid type if
the cursor refers to a function or method.
Wrapper for libclang's `clang_getCursorResultType`.
"""
result_type(c::CXCursor) = clang_getCursorResultType(c)
result_type(c::CLFunctionDecl)::CLType = result_type(c.cursor)
result_type(c::CLCXXMethod)::CLType = result_type(c.cursor)

## TODO:
# clang_getCursorExceptionSpecificationType
# clang_Cursor_getOffsetOfField
#

"""
    isanonymous(c::CXCursor) -> Bool
    isanonymous(c::CLCursor) -> Bool
Return true if the given cursor represents an anonymous record declaration(C++).
Wrapper for libclang's `clang_Cursor_isAnonymous`.
"""
isanonymous(c::CXCursor)::Bool = clang_Cursor_isAnonymous(c)
isanonymous(c::CLCursor) = isanonymous(c.cursor)

"""
    isbit(c::CXCursor) -> Bool
    isbit(c::CLCursor) -> Bool
Return true if the cursor specifies a Record member that is a bitfield.
Wrapper for libclang's `clang_Cursor_isBitField`.
"""
isbit(c::CXCursor) = clang_Cursor_isBitField(c) != 0
isbit(c::CLCursor) = isbit(c.cursor)

"""
    isvirtual(c::CXCursor) -> Bool
    isvirtual(c::CLCursor) -> Bool
Return true if the base class specified by the cursor with kind CX_CXXBaseSpecifier is virtual.
Wrapper for libclang's `clang_isVirtualBase`.
"""
isvirtual(c::CXCursor)::Bool = clang_isVirtualBase(c)
isvirtual(c::CLCursor) = isvirtual(c.cursor)

## TODO:
# clang_getCXXAccessSpecifier
# clang_Cursor_getStorageClass
# clang_getNumOverloadedDecls
# clang_getOverloadedDecl
# clang_getIBOutletCollectionType
#

"""
    spelling(c::CXCursor) -> String
    spelling(c::CLCursor) -> String
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
spelling(c::CLCursor) = spelling(c.cursor)

# clang_Cursor_getSpellingNameRange

"""
    name(c::CXCursor) -> String
    name(c::CLCursor) -> String
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
name(c::CLCursor) = name(c.cursor)

"""
    getref(c::CXCursor) -> CXCursor
    getref(c::CLCursor) -> CLCursor
For a cursor that is a reference, retrieve a cursor representing the entity that it references.
Wrapper for libclang's `clang_getCursorReferenced`.
"""
getref(c::CXCursor) = clang_getCursorReferenced(c)
getref(c::CLCursor)::CLCursor = getref(c.cursor)

"""
    getdef(c::CXCursor) -> CXCursor
    getdef(c::CLCursor) -> CLCursor
For a cursor that is either a reference to or a declaration of some entity, retrieve a cursor
that describes the definition of that entity.
Wrapper for libclang's `clang_getCursorDefinition`.
"""
getdef(c::CXCursor) = clang_getCursorDefinition(c)
getdef(c::CLCursor)::CLCursor = getdef(c.cursor)

"""
    isdef(c::Cursor) -> Bool
    isdef(c::CLCursor) -> Bool
Return true if the declaration pointed to by this cursor is also a definition of that entity.
Wrapper for libclang's `clang_isCursorDefinition`.
"""
isdef(c::CXCursor)::Bool = clang_isCursorDefinition(c)
isdef(c::CLCursor) = isdef(c.cursor)

"""
    canonical(c::CXCursor) -> CXCursor
    canonical(c::CLCursor) -> CLCursor
Return the canonical cursor corresponding to the given cursor.
Wrapper for libclang's `clang_getCanonicalCursor`.
"""
canonical(c::CXCursor) = clang_getCanonicalCursor(c)
canonical(c::CLCursor)::CLCursor = canonical(c.cursor)

## TODO:
# clang_Cursor_getObjCSelectorIndex
# clang_Cursor_isDynamicCall
# clang_Cursor_getReceiverType

"""
    isvariadic(c::CXCursor) -> Bool
    isvariadic(c::CLCursor) -> Bool
Return true if the given cursor is a variadic function or method.
Wrapper for libclang's `clang_Cursor_isVariadic`.
"""
isvariadic(c::CXCursor) = clang_Cursor_isVariadic(c) != 0
isvariadic(c::CLCursor) = isvariadic(c.cursor)

# clang_Cursor_isExternalSymbol
# clang_Cursor_getCommentRange
# clang_Cursor_getRawCommentText
# clang_Cursor_getBriefCommentText

function spelling(k::CXCursorKind)
    GC.@preserve c begin
        cxstr = clang_getCursorKindSpelling(k)
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end


# helper
"""
    filename(c::CXCursor) -> String
    filename(c::CLCursor) -> String
Return the complete file and path name of the given file referenced by the input cursor.
"""
function filename(c::CXCursor)
    file = Ref{CXFile}(C_NULL)
    line = Ref{Cuint}(0)
    column = Ref{Cuint}(0)
    offset = Ref{Cuint}(0)
    GC.@preserve c begin
        location = clang_getCursorLocation(c)
        clang_getExpansionLocation(location, file, line, column, offset)
        if file[] != C_NULL
            cxstr = clang_getFileName(file[])
            ptr = clang_getCString(cxstr)
            s = unsafe_string(ptr)
            clang_disposeString(cxstr)
        else
            s = ""
        end
    end
    return s
end
filename(c::CLCursor) = filename(c.cursor)

"""
    return_type(c::CLCursor, resolve::Bool=true) -> CXtype
Return the return type associated with a function/method cursor.
"""
function return_type(c::CLCursor, resolve::Bool=true)
    t = result_type(c)
    resolve && return resolve_type(t)
    return t
end

"""
    typedef_type(c::CLCursor) -> CXType
Return the underlying type of a typedef declaration.
"""
function typedef_type(c::CLCursor)
    t = underlying_type(c)
    kind(t) == CXType_Unexposed && return type(children(c)[1])
    return t
end

"""
    search(cursors::Vector{CLCursor}, ismatch::Function) -> Vector{CLCursor}
Return vector of CLCursors that match predicate. `ismatch` is a function that accepts a CLCursor argument.
"""
function search(cursors::Vector{CLCursor}, ismatch::Function)
    matched = CLCursor[]
    for cursor in cursors
        ismatch(cursor) && push!(matched, cursor)
    end
    return matched
end
search(c::CLCursor, ismatch::Function) = search(children(c), ismatch)
search(c::CLCursor, s::String) = search(c, x->spelling(x)==s)
search(c::CLCursor, k::CXCursorKind) = search(c, x->kind(x)==k)

# visitor
function cu_children_visitor(cursor::CXCursor, parent::CXCursor, client_data::Ptr{Cvoid})::Cuint
    list = unsafe_pointer_to_objref(client_data)
    push!(list, cursor)
    return CXChildVisit_Continue
end

function children(cursor::CLCursor)
    # TODO: possible to use sizehint! here?
    list = CXCursor[]
    GC.@preserve cursor begin
        cu_visitor_cb = @cfunction(cu_children_visitor, Cuint, (CXCursor, CXCursor, Ptr{Cvoid}))
        clang_visitChildren(cursor, cu_visitor_cb, pointer_from_objref(list))
    end
    return Vector{CLCursor}(list)
end

"""
    function_args(cursor::CLCursor) -> Vector{CLCursor}
Return function arguments for a given cursor.
"""
function_args(cursor::CLCursor) = search(cursor, CXCursor_ParmDecl)

"""
    is_typedef_anon(current::CLCursor, next::CLCursor) -> Bool
Return true if the current cursor is an typedef anonymous struct/enum.
"""
function is_typedef_anon(current::CLCursor, next::CLCursor)
    !isempty(name(current)) && return false
    refback = children(next)
    if kind(next) == CXCursor_TypedefDecl &&
       !isempty(refback) && name(refback[1]) == ""
        return true
    else
        return false
    end
end
