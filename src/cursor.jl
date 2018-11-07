# for manipulating CXCursors
"""
    isnull(c::CXCursor) -> Bool
Return true if cursor is null.
"""
isnull(c::CXCursor) = clang_Cursor_isNull(c) != 0

"""
    getcursor() -> (NULL)CXCursor
Return the NULL CXCursor.
"""
getcursor() = clang_getNullCursor()

# equality
Base.:(==)(c1::CXCursor, c2::CXCursor)::Bool = clang_equalCursors(c1, c2)
Base.hash(c::CXCursor) = clang_hashCursor(c)

"""
    kind(c::CXCursor) -> CXCursorKind
Return the kind of the given cursor.
"""
kind(c::CXCursor) = clang_getCursorKind(c)

"""
    isdecl(k::CXcursorKind) -> Bool
Return true if the given cursor kind represents a declaration.
"""
isdecl(k::CXCursorKind)::Bool = clang_isDeclaration(k)

"""
    isref(k::CXcursorKind) -> Bool
Return true if the given cursor kind represents a simple reference. Note that other kinds of
cursors (such as expressions) can also refer to other cursors. Use [`getref`](@ref) to determine
whether a particular cursor refers to another entity.
"""
isref(k::CXCursorKind)::Bool = clang_isReference(k)

"""
    isexpr(k::CXcursorKind) -> Bool
Return true if the given cursor kind represents an expression.
"""
isexpr(k::CXCursorKind)::Bool = clang_isExpression(k)

"""
    isstat(k::CXcursorKind) -> Bool
Return true if the given cursor kind represents a statement.
"""
isstat(k::CXCursorKind)::Bool = clang_isStatement(k)

"""
    isattr(k::CXcursorKind) -> Bool
Return true if the given cursor kind represents an attribute.
"""
isattr(k::CXCursorKind)::Bool = clang_isAttribute(k)

"""
    hasattr(c::CXCursor) -> Bool
Determine whether the given cursor has any attributes.
"""
hasattr(c::CXCursor)::Bool = clang_Cursor_hasAttrs(c)

"""
    isvalid(k::CXcursorKind) -> Bool
Return true if the given cursor kind represents an valid cursor.
"""
Base.isvalid(k::CXCursorKind) = !(Bool(clang_isInvalid(k)))

"""
    is_translation_unit(k::CXcursorKind) -> Bool
Return true if the given cursor kind represents a translation unit.
"""
is_translation_unit(k::CXCursorKind)::Bool = clang_isTranslationUnit(k)

"""
    is_translation_unit(k::CXcursorKind) -> Bool
Return true if the given cursor kind represents a preprocessing element, such as a
preprocessor directive or macro instantiation.
"""
ispreprocessing(k::CXCursorKind)::Bool = clang_isPreprocessing(k)

"""
    isunexposed(k::CXcursorKind) -> Bool
Return true if the given cursor kind represents a currently unexposed piece of the AST
(e.g., CXCursor_UnexposedStmt).
"""
isunexposed(k::CXCursorKind)::Bool = clang_isUnexposed(k)

"""
    linkage(c::CXCursor) -> CXLinkageKind
Return the linkage of the entity referred to by a given cursor.
"""
linkage(c::CXCursor)::CXLinkageKind = clang_getCursorLinkage(c)

## TODO:
# clang_getCursorVisibility
# clang_getCursorAvailability
# clang_getCursorPlatformAvailability
# clang_disposeCXPlatformAvailability
# clang_getCursorLanguage
# clang_getCursorTLSKind

"""
    get_translation_unit(c::CXCursor) -> CXTranslationUnit
Returns the translation unit that a cursor originated from.
"""
get_translation_unit(c::CXCursor) = clang_Cursor_getTranslationUnit(c)

## TODO: this is mainly for internal debugging?
# clang_createCXCursorSet
# clang_disposeCXCursorSet
# clang_CXCursorSet_contains
# clang_CXCursorSet_insert

"""
    get_semantic_parent(c::CXCursor) -> CXCursor
Return the semantic parent of the given cursor. Please checkout libclang's doc to know more.
"""
get_semantic_parent(c::CXCursor) = clang_getCursorSemanticParent(c)

"""
    get_lexical_parent(c::CXCursor) -> CXCursor
Return the lexical parent of the given cursor. Please checkout libclang's doc to know more.
"""
get_lexical_parent(c::CXCursor) = clang_getCursorLexicalParent(c)

## TODO:
# clang_getOverriddenCursors
# clang_disposeOverriddenCursors

"""
    get_included_file(c::CXCursor) -> CXFile
Return the file that is included by the given inclusion directive cursor.
"""
get_included_file(c::CXCursor) = clang_getIncludedFile(c)

"""
    location(c::CXCursor) -> CXSourceLocation
Return the physical location of the source constructor referenced by the given cursor.
"""
location(c::CXCursor) = clang_getCursorLocation(c)

"""
    extent(c::CXCursor) -> CXSourceRange
Return the physical extent of the source construct referenced by the given cursor.

The extent of a cursor starts with the file/line/column pointing at the first character
within the source construct that the cursor refers to and ends with the last character
within that source construct. For a declaration, the extent covers the declaration itself.
For a reference, the extent covers the location of the reference (e.g., where the referenced
entity was actually used).
"""
extent(c::CXCursor) = clang_getCursorExtent(c)

"""
    type(c::CXCursor) -> CXType
Return the type of a CXCursor (if any). To get the cursor from a type, see [`typedecl`](@ref).
"""
type(c::CXCursor) = clang_getCursorType(c)

"""
    underlying_type(c::CXCursor) -> CXType
Return the underlying type of a typedef declaration.
"""
underlying_type(c::CXCursor) = _underlying_type(Val(kind(c)), c)
_underlying_type(::Val{CXCursor_TypedefDecl}, c::CXCursor) = clang_getTypedefDeclUnderlyingType(c)

"""
    integer_type(c::CXCursor) -> CXType
Retrieve the integer type of an enum declaration.
"""
integer_type(c::CXCursor) = _integer_type(Val(kind(c)), c)
_integer_type(::Val{CXCursor_EnumDecl}, c::CXCursor) = clang_getEnumDeclIntegerType(c)

"""
    value(c::CXCursor) -> Int
Return the integer value of an enum constant declaration.
"""
value(c::CXCursor)::Int = _value(Val(kind(c)), c)
function _value(::Val{CXCursor_EnumConstantDecl}, c::CXCursor)
    typeKind = kind(type(c))
    if typeKind == CXType_Int || typeKind == CXType_Long || typeKind == CXType_LongLong
        return clang_getEnumConstantDeclValue(c)
    elseif typeKind == CXType_UInt || typeKind == CXType_ULong || typeKind == CXType_ULongLong
        return clang_getEnumConstantDeclUnsignedValue(c)
    end
    error("Unknown EnumConstantDecl type: ", typeKind, " cursor: ", cursorKind)
end

"""
    bitwidth(c::CXCursor) -> Int
Return the bit width of a bit field declaration as an integer.
"""
bitwidth(c::CXCursor)::Int = _bitwidth(Val(kind(c)), c)
_bitwidth(::Val{CXCursor_FieldDecl}, c::CXCursor) = clang_Cursor_getNumArguments(c)

"""
    argnum(c::CXCursor) -> Int
Return the number of non-variadic arguments associated with a given cursor.
"""
argnum(c::CXCursor)::Int = _argnum(Val(kind(c)), c)
_argnum(::Val{CXCursor_FunctionDecl}, c::CXCursor) = clang_Cursor_getNumArguments(c)
_argnum(::Val{CXCursor_CXXMethod}, c::CXCursor) = clang_Cursor_getNumArguments(c)

"""
    argument(c::CXCursor, i::Integer) -> CXCursor
Return the argument cursor of a function or method.
"""
argument(c::CXCursor, i::Integer) = _argument(Val(kind(c)), c, Unsigned(i))
_argument(::Val{CXCursor_FunctionDecl}, c::CXCursor, i::Unsigned) = clang_Cursor_getArgument(c, i)
_argument(::Val{CXCursor_CXXMethod}, c::CXCursor, i::Unsigned) = clang_Cursor_getArgument(c, i)

## TODO:
# clang_Cursor_getNumTemplateArguments
# clang_Cursor_getTemplateArgumentKind
# clang_Cursor_getTemplateArgumentType
# clang_Cursor_getTemplateArgumentValue
# clang_Cursor_getTemplateArgumentUnsignedValue

"""
    isfunctionlike(c::CXCursor) -> Bool
Determine whether a CXCursor that is a macro, is function like.
"""
isfunctionlike(c::CXCursor)::Bool = clang_Cursor_isMacroFunctionLike(c)

"""
    isbuiltin(c::CXCursor) -> Bool
Determine whether a  CXCursor that is a macro, is a builtin one.
"""
isbuiltin(c::CXCursor)::Bool = clang_Cursor_isMacroBuiltin(c)

"""
    isinlined(c::CXCursor) -> Bool
Determine whether a CXCursor that is a function declaration, is an inline declaration.
"""
isinlined(c::CXCursor)::Bool = clang_Cursor_isFunctionInlined(c)

"""
    result_type(c::CXCursor) -> CXType
Return the return type associated with a given cursor. This only returns a valid type if
the cursor refers to a function or method.
"""
result_type(c::CXCursor) = _result_type(Val(kind(c)), c)
_result_type(::Val{CXCursor_FunctionDecl}, c::CXCursor) = clang_getCursorResultType(c)
_result_type(::Val{CXCursor_CXXMethod}, c::CXCursor) = clang_getCursorResultType(c)

## TODO:
# clang_getCursorExceptionSpecificationType
# clang_Cursor_getOffsetOfField
#

"""
    isanonymous(c::CXCursor) -> Bool
Return true if the given cursor represents an anonymous record declaration(C++).
"""
isanonymous(c::CXCursor)::Bool = clang_Cursor_isAnonymous(c)

"""
    isbit(c::CXCursor) -> Bool
Return true if the cursor specifies a Record member that is a bitfield.
"""
isbit(c::CXCursor) = clang_Cursor_isBitField(c) != 0

"""
    isvirtual(c::CXCursor) -> Bool
Return true if the base class specified by the cursor with kind CX_CXXBaseSpecifier is virtual.
"""
isvirtual(c::CXCursor)::Bool = clang_isVirtualBase(c)

## TODO:
# clang_getCXXAccessSpecifier
# clang_Cursor_getStorageClass
# clang_getNumOverloadedDecls
# clang_getOverloadedDecl
# clang_getIBOutletCollectionType
#

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

# clang_Cursor_getSpellingNameRange

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
    getref(c::CXCursor) -> CXCursor
For a cursor that is a reference, retrieve a cursor representing the entity that it references.
"""
getref(c::CXCursor) = clang_getCursorReferenced(c)

"""
    getdef(c::CXCursor) -> CXCursor
For a cursor that is either a reference to or a declaration of some entity, retrieve a cursor
that describes the definition of that entity.
"""
getdef(c::CXCursor) = clang_getCursorDefinition(c)

"""
    isdef(c::Cursor) -> Bool
Return true if the declaration pointed to by this cursor is also a definition of that entity.
"""
isdef(c::CXCursor)::Bool = clang_isCursorDefinition(c)

"""
    canonical(c::CXCursor) -> CXCursor
Return the canonical cursor corresponding to the given cursor.
"""
canonical(c::CXCursor) = clang_getCanonicalCursor(c)

## TODO:
# clang_Cursor_getObjCSelectorIndex
# clang_Cursor_isDynamicCall
# clang_Cursor_getReceiverType

"""
    isvariadic(c::CXCursor) -> Bool
Return true if the given cursor is a variadic function or method.
"""
isvariadic(c::CXCursor) = clang_Cursor_isVariadic(c) != 0

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

"""
    return_type(c::CXCursor, resolve::Bool=true) -> CXtype
Return the return type associated with a function/method cursor.
"""
function return_type(c::CXCursor, resolve::Bool=true)
    t = result_type(c)
    resolve && return resolve_type(t)
    return t
end

"""
    typedef_type(c::CXCursor) -> CXType
Return the underlying type of a typedef declaration.
"""
function typedef_type(c::CXCursor)
    t = underlying_type(c)
    kind(t) == CXType_Unexposed && return type(children(c)[1])
    return t
end

"""
    search(cursors::Vector{CXCursor}, ismatch::Function) -> Vector{CXCursor}
Return vector of CXCursors that match predicate. `ismatch` is a function that accepts a CXCursor argument.
"""
function search(cursors::Vector{CXCursor}, ismatch::Function)
    matched = CXCursor[]
    for cursor in cursors
        ismatch(cursor) && push!(matched, cursor)
    end
    return matched
end
search(c::CXCursor, ismatch::Function) = search(children(c), ismatch)
search(c::CXCursor, s::String) = search(c, x->spelling(x)==s)
search(c::CXCursor, k::CXCursorKind) = search(c, x->kind(x)==k)

# visitor
function cu_children_visitor(cursor::CXCursor, parent::CXCursor, client_data::Ptr{Cvoid})::Cuint
    list = unsafe_pointer_to_objref(client_data)
    push!(list, cursor)
    return CXChildVisit_Continue
end

function children(cursor::CXCursor)
    # TODO: possible to use sizehint! here?
    list = CXCursor[]
    GC.@preserve cursor begin
        cu_visitor_cb = @cfunction(cu_children_visitor, Cuint, (CXCursor, CXCursor, Ptr{Cvoid}))
        clang_visitChildren(cursor, cu_visitor_cb, pointer_from_objref(list))
    end
    list
end

"""
    function_args(cursor::CXCursor) -> Vector{CXCursor}
Return function arguments for a given cursor.
"""
function_args(cursor::CXCursor) = search(cursor, CXCursor_ParmDecl)

"""
    is_typedef_anon(current::CXCursor, next::CXCursor) -> Bool
Return true if the current cursor is an typedef anonymous struct/enum.
"""
function is_typedef_anon(current::CXCursor, next::CXCursor)
    refback = children(next)
    if kind(next) == CXCursor_TypedefDecl &&
       !isempty(refback) && name(refback[1]) == ""
        return true
    else
        return false
    end
end
