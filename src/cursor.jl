"""
    getNullCursor() -> CXCursor
Return the "NULL" CXCursor.
"""
getNullCursor() = clang_getNullCursor()

"""
    isNull(c::Union{CXCursor,CLCursor}) -> Bool
Return true if cursor is null.
"""
isNull(c::Union{CXCursor,CLCursor}) = clang_Cursor_isNull(c) != 0

# equality
Base.:(==)(c1::CXCursor, c2::CXCursor)::Bool = clang_equalCursors(c1, c2)
Base.hash(c::CXCursor)::UInt = clang_hashCursor(c)
Base.:(==)(c1::CLCursor, c2::CLCursor) = c1.cursor == c2.cursor
Base.hash(x::CLCursor) = hash(x.cursor)
Base.:(==)(c1::CLCursor, c2::CXCursor) = c1.cursor == c2
Base.:(==)(c1::CXCursor, c2::CLCursor) = c1 == c2.cursor

"""
    kind(c::CXCursor) -> CXCursorKind
Return the kind of the given cursor.
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
    isDeclaration(k::CXcursorKind) -> Bool
    isDeclaration(c::CLCursor) -> Bool
Return true if the given cursor kind represents a declaration.
"""
isDeclaration(k::CXCursorKind)::Bool = clang_isDeclaration(k)
isDeclaration(c::CLCursor) = isDeclaration(kind(c))

"""
    isInvalidDeclaration(x::CXcursorKind) -> Bool
Return true if the given declaration is invalid.
A declaration is invalid if it could not be parsed successfully.
"""
isInvalidDeclaration(x::Union{CXCursor,CLCursor})::Bool = clang_isInvalidDeclaration(x)

"""
    isReference(k::CXcursorKind) -> Bool
    isReference(c::CLCursor) -> Bool
Return true if the given cursor kind represents a simple reference. Note that other kinds of
cursors (such as expressions) can also refer to other cursors. Use [`getCursorReferenced`](@ref) to determine
whether a particular cursor refers to another entity.
"""
isReference(k::CXCursorKind)::Bool = clang_isReference(k)
isReference(c::CLCursor) = isReference(kind(c))

"""
    isExpression(k::CXcursorKind) -> Bool
    isExpression(c::CLCursor) -> Bool
Return true if the given cursor kind represents an expression.
"""
isExpression(k::CXCursorKind)::Bool = clang_isExpression(k)
isExpression(c::CLCursor) = isExpression(kind(c))

"""
    isStatement(k::CXcursorKind) -> Bool
    isStatement(c::CLCursor) -> Bool
Return true if the given cursor kind represents a statement.
"""
isStatement(k::CXCursorKind)::Bool = clang_isStatement(k)
isStatement(c::CLCursor) = isStatement(kind(c))

"""
    isAttribute(k::CXcursorKind) -> Bool
    isAttribute(c::CLCursor) -> Bool
Return true if the given cursor kind represents an attribute.
"""
isAttribute(k::CXCursorKind)::Bool = clang_isAttribute(k)
isAttribute(c::CLCursor) = isAttribute(kind(c))

"""
    hasAttrs(c::Union{CXCursor,CLCursor}) -> Bool
Determine whether the given cursor has any attributes.
"""
hasAttrs(c::Union{CXCursor,CLCursor})::Bool = clang_Cursor_hasAttrs(c)

"""
    isInvalid(k::CXcursorKind) -> Bool
    isInvalid(c::CLCursor) -> Bool
Return true if the given cursor kind represents an valid cursor.
"""
isInvalid(k::CXCursorKind) = !(Bool(clang_isInvalid(k)))
isInvalid(c::CLCursor) = isInvalid(kind(c))

"""
    isTranslationUnit(k::CXcursorKind) -> Bool
    isTranslationUnit(c::CLCursor) -> Bool
Return true if the given cursor kind represents a translation unit.
"""
isTranslationUnit(k::CXCursorKind)::Bool = clang_isTranslationUnit(k)
isTranslationUnit(c::CLCursor) = isTranslationUnit(kind(c))

"""
    isPreprocessing(k::CXcursorKind) -> Bool
    isPreprocessing(c::CLCursor) -> Bool
Return true if the given cursor kind represents a preprocessing element, such as a
preprocessor directive or macro instantiation.
"""
isPreprocessing(k::CXCursorKind)::Bool = clang_isPreprocessing(k)
isPreprocessing(c::CLCursor) = isPreprocessing(kind(c))

"""
    isUnexposed(k::CXcursorKind) -> Bool
Return true if the given cursor kind represents a currently unexposed piece of the AST
(e.g., CXCursor_UnexposedStmt).
"""
isUnexposed(k::CXCursorKind)::Bool = clang_isUnexposed(k)
isUnexposed(c::CLCursor) = isUnexposed(kind(c))

"""
    getCursorLinkage(c::Union{CXCursor,CLCursor}) -> CXLinkageKind
Return the linkage of the entity referred to by a given cursor.
"""
getCursorLinkage(c::Union{CXCursor,CLCursor})::CXLinkageKind = clang_getCursorLinkage(c)

function getCursorPlatformAvailability(c::Union{<:CXCursor,<:CLCursor})::Union{Nothing, CLPlatformAvailability}
    n_plats = clang_getCursorPlatformAvailability(c, C_NULL, C_NULL, C_NULL, C_NULL, C_NULL, C_NULL)

    avails = Vector{LibClang.CXPlatformAvailability}(undef, n_plats)

    GC.@preserve avails clang_getCursorPlatformAvailability(c, C_NULL, C_NULL, C_NULL, C_NULL, pointer(avails), n_plats)

    macos_index = findfirst(avails) do avail
        platstr = clang_getCString(avail.Platform)
        ismacos = unsafe_string(platstr) == "macos"
        clang_disposeString(avail.Platform)

        ismacos
    end

    res = if !isnothing(macos_index)
        CLPlatformAvailability(avails[macos_index])
    else
        nothing
    end

    # XXX: figure out
    # dispose availabilities
    # for avail in avails
    #     disposeCXPlatformAvailability(avail)
    # end

    return res
end

disposeCXPlatformAvailability(avail::CXPlatformAvailability)::Nothing = clang_disposeCXPlatformAvailability(avail)

## TODO:
# clang_getCursorVisibility
# clang_getCursorAvailability

"""
    getCursorLanguage(c::Union{CXCursor,CLCursor}) -> CXLanguageKind
Return the language of the entity referred to by a given cursor.
Return `CXLanguage_Invalid` if the input cursor is not a decl.
Note that, this function has limitations, for example, it cannot distinguish C++ structs
from C structs, in both cases, it returns `CXLanguage_C`.
"""
getCursorLanguage(c::Union{CXCursor,CLCursor})::CXLanguageKind = clang_getCursorLanguage(c)

# clang_getCursorTLSKind

"""
    getTranslationUnit(c::Union{CXCursor,CLCursor}) -> CXTranslationUnit
Returns the translation unit that a cursor originated from.
"""
getTranslationUnit(c::Union{CXCursor,CLCursor}) = clang_Cursor_getTranslationUnit(c)

## TODO: this is mainly for internal debugging?
# clang_createCXCursorSet
# clang_disposeCXCursorSet
# clang_CXCursorSet_contains
# clang_CXCursorSet_insert

"""
    getCursorSemanticParent(c::CXCursor) -> CXCursor
    getCursorSemanticParent(c::CLCursor) -> CLCursor
Return the semantic parent of the given cursor. Please checkout libclang's doc to know more.
"""
getCursorSemanticParent(c::CXCursor) = clang_getCursorSemanticParent(c)
getCursorSemanticParent(c::CLCursor)::CLCursor = clang_getCursorSemanticParent(c)

"""
    getCursorLexicalParent(c::CXCursor) -> CXCursor
    getCursorLexicalParent(c::CLCursor) -> CLCursor
Return the lexical parent of the given cursor. Please checkout libclang's doc to know more.
"""
getCursorLexicalParent(c::CXCursor) = clang_getCursorLexicalParent(c)
getCursorLexicalParent(c::CLCursor)::CLCursor = clang_getCursorLexicalParent(c)

## TODO:
# clang_getOverriddenCursors
# clang_disposeOverriddenCursors

"""
    getIncludedFile(c::Union{CXCursor,CLCursor}) -> CXFile
Return the file that is included by the given inclusion directive cursor.
"""
getIncludedFile(c::Union{CXCursor,CLCursor}) = clang_getIncludedFile(c)

"""
    getCursorLocation(c::Union{CXCursor,CLCursor}) -> CXSourceLocation
Return the physical location of the source constructor referenced by the given cursor.
"""
getCursorLocation(c::Union{CXCursor,CLCursor}) = clang_getCursorLocation(c)

"""
    getCursorExtent(c::Union{CXCursor,CLCursor}) -> CXSourceRange
Return the physical extent of the source construct referenced by the given cursor.

The extent of a cursor starts with the file/line/column pointing at the first character
within the source construct that the cursor refers to and ends with the last character
within that source construct. For a declaration, the extent covers the declaration itself.
For a reference, the extent covers the location of the reference (e.g., where the referenced
entity was actually used).
"""
getCursorExtent(c::Union{CXCursor,CLCursor}) = clang_getCursorExtent(c)

"""
    getCursorType(c::CXCursor) -> CXType
    getCursorType(c::CLCursor) -> CLType
Return the type of a CXCursor (if any). To get the cursor from a type, see [`getTypeDeclaration`](@ref).
"""
getCursorType(c::CXCursor) = clang_getCursorType(c)
getCursorType(c::CLCursor)::CLType = clang_getCursorType(c)

"""
    getTypedefDeclUnderlyingType(c::CLTypedefDecl) -> CLType
Return the underlying type of a typedef declaration.
"""
getTypedefDeclUnderlyingType(c::CXCursor) = clang_getTypedefDeclUnderlyingType(c)
getTypedefDeclUnderlyingType(c::CLTypedefDecl)::CLType = clang_getTypedefDeclUnderlyingType(c)

"""
    getEnumDeclIntegerType(c::CLEnumDecl) -> CLType
Retrieve the integer type of an enum declaration.
"""
getEnumDeclIntegerType(c::CXCursor) = clang_getEnumDeclIntegerType(c)
getEnumDeclIntegerType(c::CLEnumDecl)::CLType = clang_getEnumDeclIntegerType(c)

"""
    value(c::CLCursor) -> Integer
Return the integer value of an enum constant declaration.
"""
function value(c::CLEnumConstantDecl)::Integer
    typeKind = kind(getCursorType(c))

    # PR 519
    if typeKind == CXType_Elaborated
        typeKind = getCursorType(c) |>
                    get_elaborated_cursor |>
                    getTypedefDeclUnderlyingType |>
                    getCanonicalType |>
                    kind
    end

    # issue #404
    if typeKind == CXType_Typedef
        typeKind = getCursorType(c) |>
                    getTypeDeclaration |>
                    getTypedefDeclUnderlyingType |>
                    getCanonicalType |>
                    kind
    end
    # PR #435
    if typeKind == CXType_Enum
        typeKind = getCursorType(c) |>
                     getTypeDeclaration |>
                     getCanonicalType |>
                     kind
    end
    if typeKind == CXType_Bool ||
        typeKind == CXType_Short ||
        typeKind == CXType_Int ||
        typeKind == CXType_Long ||
        typeKind == CXType_LongLong ||
        typeKind == CXType_Char_S # enum : char
        return clang_getEnumConstantDeclValue(c)
    elseif typeKind == CXType_UShort ||
           typeKind == CXType_UInt ||
           typeKind == CXType_ULong ||
           typeKind == CXType_ULongLong ||
           typeKind == CXType_UChar
        return clang_getEnumConstantDeclUnsignedValue(c)
    end

    return error("Unknown EnumConstantDecl type: ", typeKind, " cursor: ", kind(c))
end

"""
    getFieldDeclBitWidth(c::CLFieldDecl) -> Int
Return the bit width of a bit field declaration as an integer.
"""
getFieldDeclBitWidth(c::CXCursor)::Int = clang_getFieldDeclBitWidth(c)
getFieldDeclBitWidth(c::CLFieldDecl) = clang_getFieldDeclBitWidth(c)

"""
    getNumArguments(c::Union{CXCursor,CLCursor}) -> Int
Return the number of non-variadic arguments associated with a given cursor.
"""
getNumArguments(c::Union{CXCursor,CLCursor})::Int = clang_Cursor_getNumArguments(c)

"""
    getArgument(c::CXCursor, i::Integer) -> CXCursor
    getArgument(c::Union{CLFunctionDecl,CLCXXMethod,CLConstructor,CLFunctionTemplate}, i::Integer) -> CLCursor
Return the argument cursor of a function or method.
"""
getArgument(c::CXCursor, i::Integer) = clang_Cursor_getArgument(c, Unsigned(i))
getArgument(c::Union{CLFunctionDecl,CLCXXMethod,CLConstructor,CLFunctionTemplate}, i::Integer)::CLCursor =
    clang_Cursor_getArgument(c, Unsigned(i))

## TODO:
# clang_Cursor_getNumTemplateArguments
# clang_Cursor_getTemplateArgumentKind
# clang_Cursor_getTemplateArgumentType
# clang_Cursor_getTemplateArgumentValue
# clang_Cursor_getTemplateArgumentUnsignedValue

"""
    isMacroFunctionLike(c::Union{CXCursor,CLCursor}) -> Bool
Determine whether a CXCursor that is a macro, is function like.
"""
isMacroFunctionLike(c::Union{CXCursor,CLCursor})::Bool = clang_Cursor_isMacroFunctionLike(c)

"""
    isMacroBuiltin(c::Union{CXCursor,CLCursor}) -> Bool
Determine whether a  CXCursor that is a macro, is a builtin one.
"""
isMacroBuiltin(c::Union{CXCursor,CLCursor})::Bool = clang_Cursor_isMacroBuiltin(c)

"""
    isFunctionInlined(c::Union{CXCursor,CLCursor}) -> Bool
Determine whether a CXCursor that is a function declaration, is an inline declaration.
"""
isFunctionInlined(c::Union{CXCursor,CLCursor})::Bool = clang_Cursor_isFunctionInlined(c)

"""
    getCursorResultType(c::CXCursor) -> CXType
    getCursorResultType(c::Union{CLFunctionDecl,CLCXXMethod}) -> CLType
Return the return type associated with a given cursor. This only returns a valid type if
the cursor refers to a function or method.
"""
getCursorResultType(c::CXCursor) = clang_getCursorResultType(c)
getCursorResultType(c::Union{CLFunctionDecl,CLCXXMethod})::CLType = clang_getCursorResultType(c)

## TODO:
# clang_getCursorExceptionSpecificationType

"""
    getOffsetOfField(c::Union{CXCursor,CLCursor}) -> Int
Return the offset of the field represented by the cursor in bits as it
would be returned by __offsetof__ as per C++11[18.2p4].
It returns a minus number for layout errors, please convert the result to
a [`CXTypeLayoutError`](@ref) to see what the error is.
"""
getOffsetOfField(c::Union{CXCursor,CLCursor})::Int = clang_Cursor_getOffsetOfField(c)

"""
    isAnonymous(c::Union{CXCursor,CLCursor}) -> Bool
Return true if the given cursor represents an anonymous record declaration(C++).
"""
isAnonymous(c::Union{CXCursor,CLCursor})::Bool = clang_Cursor_isAnonymous(c)

"""
    isBitField(c::Union{CXCursor,CLCursor}) -> Bool
Return true if the cursor specifies a Record member that is a bitfield.
"""
isBitField(c::Union{CXCursor,CLCursor}) = clang_Cursor_isBitField(c) != 0

"""
    isVirtualBase(c::Union{CXCursor,CLCursor}) -> Bool
Return true if the base class specified by the cursor with kind CX_CXXBaseSpecifier is virtual.
"""
isVirtualBase(c::Union{CXCursor,CLCursor})::Bool = clang_isVirtualBase(c)

## TODO:
# clang_getCXXAccessSpecifier
# clang_Cursor_getStorageClass
# clang_getNumOverloadedDecls
# clang_getOverloadedDecl
# clang_getIBOutletCollectionType
#

"""
    spelling(c::Union{CXCursor,CLCursor}) -> String
Return a name for the entity referenced by this cursor.
"""
function spelling(c::Union{CXCursor,CLCursor})
    cxstr = clang_getCursorSpelling(c)
    ptr = clang_getCString(cxstr)
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    return s
end

# clang_Cursor_getSpellingNameRange

"""
    name(c::Union{CXCursor,CLCursor}) -> String
Return the display name for the entity referenced by this cursor.
"""
function name(c::Union{CXCursor,CLCursor})
    cxstr = clang_getCursorDisplayName(c)
    ptr = clang_getCString(cxstr)
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    return s
end

"""
    getCursorReferenced(c::CXCursor) -> CXCursor
    getCursorReferenced(c::CLCursor) -> CLCursor
For a cursor that is a reference, retrieve a cursor representing the entity that it references.
"""
getCursorReferenced(c::CXCursor) = clang_getCursorReferenced(c)
getCursorReferenced(c::CLCursor)::CLCursor = clang_getCursorReferenced(c)

"""
    getCursorDefinition(c::CXCursor) -> CXCursor
    getCursorDefinition(c::CLCursor) -> CLCursor
For a cursor that is either a reference to or a declaration of some entity, retrieve a cursor
that describes the definition of that entity.
"""
getCursorDefinition(c::CXCursor) = clang_getCursorDefinition(c)
getCursorDefinition(c::CLCursor)::CLCursor = clang_getCursorDefinition(c)

"""
    isCursorDefinition(c::Union{CXCursor,CLCursor}) -> Bool
Return true if the declaration pointed to by this cursor is also a definition of that entity.
"""
isCursorDefinition(c::Union{CXCursor,CLCursor})::Bool = clang_isCursorDefinition(c)

"""
    getCanonicalCursor(c::CXCursor) -> CXCursor
    getCanonicalCursor(c::CLCursor) -> CLCursor
Return the getCanonicalCursor cursor corresponding to the given cursor.
"""
getCanonicalCursor(c::CXCursor) = clang_getCanonicalCursor(c)
getCanonicalCursor(c::CLCursor)::CLCursor = clang_getCanonicalCursor(c)

@deprecate getCanonicalType(c::CXCursor) getCanonicalCursor(c::CXCursor)
@deprecate getCanonicalType(c::CLCursor) getCanonicalCursor(c::CLCursor)

## TODO:
# clang_Cursor_getObjCSelectorIndex
# clang_Cursor_isDynamicCall
# clang_Cursor_getReceiverType

"""
    isVariadic(c::Union{CXCursor,CLCursor}) -> Bool
Return true if the given cursor is a variadic function or method.
"""
isVariadic(c::Union{CXCursor,CLCursor}) = clang_Cursor_isVariadic(c) != 0

# clang_Cursor_isExternalSymbol
# clang_Cursor_getCommentRange
getRawCommentText(c::Union{CXCursor, CLCursor}) = _cxstring_to_string(clang_Cursor_getRawCommentText(c))
getBriefCommentText(c::Union{CXCursor, CLCursor}) = _cxstring_to_string(clang_Cursor_getBriefCommentText(c))

function spelling(k::CXCursorKind)
    cxstr = clang_getCursorKindSpelling(k)
    ptr = clang_getCString(cxstr)
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    return s
end


"""
    file_line_column(CLCursor) -> (CLFile, Int, Int)
Return file, line and column number.
"""
function file_line_column(c::CLCursor)
    file = Ref{CXFile}(C_NULL)
    line = Ref{Cuint}(0)
    column = Ref{Cuint}(0)
    offset = Ref{Cuint}(0)
    location = clang_getCursorLocation(c)
    clang_getExpansionLocation(location, file, line, column, offset)
    return CLFile(file[]), Int(line[]), Int(column[])
end

"""
    file(c::CLCursor) -> CLFile
Return the file referenced by the input cursor.
"""
function file(c::CLCursor)
    f, _, _ = file_line_column(c)
    return f
end

"""
    get_filename(c::Union{CXCursor,CLCursor}) -> String
Return the complete file and path name of the given file referenced by the input cursor.
"""
function get_filename(c::Union{CXCursor,CLCursor})
    f, _, _ = get_file_line_column(c)
    return f
end

"""
    get_file_line_column(c::Union{CXCursor,CLCursor}) -> (String, Int, Int)
Return file name, line and column number.
"""
function get_file_line_column(c::Union{CXCursor,CLCursor})
    f, l, c = file_line_column(c)
    return name(f), l, c
end

"""
    search(cursors::Vector{CLCursor}, ismatch::Function) -> Vector{CLCursor}
Return vector of CLCursors that match predicate. `ismatch` is a function that accepts a CLCursor argument.
"""
function search(cursors::Vector{T}, ismatch::Function) where {T<:CLCursor}
    matched = CLCursor[]
    for cursor in cursors
        ismatch(cursor) && push!(matched, cursor)
    end
    return matched
end
search(c::CLCursor, ismatch::Function) = search(children(c), ismatch)
search(c::CLCursor, s::String) = search(c, x -> spelling(x) == s)
search(c::CLCursor, k::CXCursorKind) = search(c, x -> kind(x) == k)

# visitor
function cu_children_visitor(cursor::CXCursor, parent::CXCursor, list)::Cuint
    push!(list, cursor)
    return CXChildVisit_Continue
end

"""
    children(cursor::CXCursor) -> Vector{CXCursor}
    children(cursor::CLCursor) -> Vector{CLCursor}
Return immediate cursors of the given cursor.
"""
function children(cursor::CXCursor)
    list = CXCursor[]
    cu_visitor_cb = @cfunction(
        cu_children_visitor, Cuint, (CXCursor, CXCursor, Ref{Vector{CXCursor}})
    )
    GC.@preserve list ccall(
        (:clang_visitChildren, LibClang.libclang),
        UInt32,
        (CXCursor, CXCursorVisitor, Any),
        cursor,
        cu_visitor_cb,
        list,
    )
    return list
end
children(c::CLCursor)::Vector{CLCursor} = children(c.cursor)

"""
    get_function_args(cursor::CLCursor) -> Vector{CLCursor}
Return function arguments for a given cursor.
"""
function get_function_args(cursor::CLCursor)
    if cursor isa CLFunctionTemplate && getNumArguments(cursor) == -1
        return search(cursor, x -> kind(x) == CXCursor_ParmDecl)
    else
        return [getArgument(cursor, i - 1) for i = 1:getNumArguments(cursor)]
    end
end

"""
    is_typedef_anon(current::CLCursor, next::CLCursor) -> Bool
Return true if the current cursor is a typedef anonymous struct/enum.
"""
function is_typedef_anon(current::CLCursor, next::CLCursor)
    !isempty(name(current)) && return false
    refback = children(next)
    if kind(next) == CXCursor_TypedefDecl && !isempty(refback) && isempty(name(refback[1]))
        return true
    else
        return false
    end
end

"""
    is_forward_declaration(x::CLCursor) -> Bool
Return true if the cursor is a forward declaration.
Reference: https://joshpeterson.github.io/identifying-a-forward-declaration-with-libclang
"""
function is_forward_declaration(x::CLCursor)
    def = getCursorDefinition(x)
    def == getNullCursor() && return true
    return !(x == def)
end

"""
    is_inclusion_directive(x::CLCursor) -> Bool
Return true if the cursor is an inclusion directive.
"""
function is_inclusion_directive(x::CLCursor)
    k = kind(x)
    return k == CXCursor_InclusionDirective && k == CXCursor_LastPreprocessing
end

## Comment utilities

"""
    getParsedComment(c::CXCursor) -> CXComment
    getParsedComment(c::CLCursor) -> CLComment
Return the parsed AST of doxygen comment associated with the given node.
"""
getParsedComment(c::CXCursor) = clang_Cursor_getParsedComment(c)
getParsedComment(c::CLCursor)::CLComment = getParsedComment(c.cursor)

"""
    getAsHTML(c::Union{CXComment, FullComment})
Convert a comment into an HTML fragment. Check [libclang's documentation](https://clang.llvm.org/doxygen/group__CINDEX__COMMENT.html) for more details.
"""
getAsHTML(c::Union{CXComment, FullComment}) = _cxstring_to_string(clang_FullComment_getAsHTML(c))

"""
    getAsXML(c::Union{CXComment, FullComment})
Convert a comment into an XML document.
"""
getAsXML(c::Union{CXComment, FullComment}) = _cxstring_to_string(clang_FullComment_getAsXML(c))

"""
    kind(c::Union{CXComment, CXComment}) -> CXCommentKind
Return the kind of a comment.
"""
kind(c::Union{CXComment, CXComment}) = clang_Comment_getKind(c)

"""
    isWhiteSpace(c::Union{CXComment, CLComment}) -> Bool
Return whether a CXParagraph or CXText is contains only white space. Return false for other kinds of comment.
"""
isWhiteSpace(c::Union{CXComment, CLComment}) = !iszero(clang_Comment_isWhitespace(c))
hasTrailingNewline(c::Union{CXComment, CLComment}) = !iszero(clang_InlineContentComment_hasTrailingNewline(c))

"""
    getText(c::Text) -> String
    getText(c::VerbatimBlockLine) -> String
    getText(c::VerbatimLine) -> String
Get the text content assiciated with the node.
"""
getText(c::Text) = _cxstring_to_string(clang_TextComment_getText(c))
getText(c::VerbatimBlockLine) = _cxstring_to_string(clang_VerbatimBlockLineComment_getText(c))
getText(c::VerbatimLine) = _cxstring_to_string(clang_VerbatimLineComment_getText(c))

"""
    getCommandName(c::InlineCommand) -> String
    getCommandName(c::BlockCommand) -> String
Return the command name of a command, e.g. "brief" for `\\brief blah`.
"""
getCommandName(c::InlineCommand) = _cxstring_to_string(clang_InlineCommandComment_getCommandName(c))
getCommandName(c::BlockCommand) = _cxstring_to_string(clang_BlockCommandComment_getCommandName(c))

"""
    getParamName(c::ParamCommand) -> String
Return the name of a parameter.
"""
getParamName(c::ParamCommand) = _cxstring_to_string(clang_ParamCommandComment_getParamName(c))
getParamName(c::TParamCommand) = _cxstring_to_string(clang_TParamCommandComment_getParamName(c))

# See getArguments
getNumArgs(c::InlineCommand) = clang_InlineCommandComment_getNumArgs(c)
getNumArgs(c::BlockCommand) = clang_BlockCommandComment_getNumArgs(c)

# See getArguments
getArgText(c::InlineCommand, i) = _cxstring_to_string(clang_InlineCommandComment_getArgText(c, i))
getArgText(c::BlockCommand, i) = _cxstring_to_string(clang_BlockCommandComment_getArgText(c, i))

"""
    getParagraph(c::CXComment)
    getParagraph(c::BlockCommand)
Return the paragraph argument of a given command.
"""
getParagraph(c::CXComment) = clang_BlockCommandComment_getParagraph(c)
getParagraph(c::BlockCommand)::CLComment = getParagraph(c.comment)

"""
    getRenderKind(c::Union{CXComment, InlineCommand}) -> CXCommentInlineCommandRenderKind
Return the most appropriate rendering mode, chosen on command semantics in Doxygen.
"""
getRenderKind(c::Union{CXComment, InlineCommand}) = clang_InlineCommandComment_getRenderKind(c)

"""
    getTagName(c::Union{CXComment, HTMLStartTag, HTMLEndTag})
Return the tag name of a HTML tag.
"""
getTagName(c::Union{CXComment, HTMLStartTag, HTMLEndTag}) = _cxstring_to_string(clang_HTMLTagComment_getTagName(c))
"""
    isSelfClosing(c::Union{CXComment, HTMLStartTag})
Return whether a tag is self-closing (for example, `<br />`).
"""
isSelfClosing(c::Union{CXComment, HTMLStartTag}) = !iszero(clang_HTMLStartTagComment_isSelfClosing(c))

# See getAttributes
getNumAttrs(c::Union{CXComment, HTMLStartTag}) = clang_HTMLStartTag_getNumAttrs(c)

# See getAttributes
getAttrName(c::Union{CXComment, HTMLStartTag}, i) = _cxstring_to_string(clang_HTMLStartTag_getAttrName(c, i))

# See getAttributes
getAttrValue(c::Union{CXComment, HTMLStartTag}, i) = _cxstring_to_string(clang_HTMLStartTag_getAttrName(c, i))

"""
    getAsString(c::Union{CXComment, HTMLStartTag, HTMLEndTag})
Convert an HTML tag to its string representation.
"""
getAsString(c::Union{CXComment, HTMLStartTag, HTMLEndTag}) = _cxstring_to_string(clang_HTMLTagComment_getAsString(c))

"""
    getIndex(c::Union{CXComment, ParamCommand})
Return zero-based parameter index in function prototype or `missing` if the parameter is invalid.
"""
function getIndex(c::Union{CXComment, ParamCommand})
    if iszero(clang_ParamCommandComment_isParamIndexValid(c))
        return missing
    else
        return clang_ParamCommandComment_getParamIndex(c)
    end
end

"""
    getDirection(c::Union{CXComment, ParamCommand})
Return the parameter passing direction (`[in]`, `[out]`, `[in,out]`) or `missing` if the direction is not specified.
"""
function getDirection(c::Union{CXComment, ParamCommand})
    if iszero(clang_ParamCommandComment_isDirectionExplicit(c))
        return missing
    else
        return clang_ParamCommandComment_getDirection(c)
    end
end

getNumChildren(c::Union{CXComment, CLComment}) = clang_Comment_getNumChildren(c)

getChild(c::CXComment, i) = clang_Comment_getChild(c, i)
getChild(c::CLComment, i)::CLComment = getChild(c.comment, i)

function children(c::CXComment)
    num = getNumChildren(c)
    result = Vector{CXComment}(undef, num)
    for i in 1:num
        result[i] = getChild(c, i-1)
    end
    result
end

function children(c::CLComment)
    num = getNumChildren(c)
    result = Vector{CLComment}(undef, num)
    for i in 1:num
        result[i] = getChild(c, i-1)
    end
    result
end

"""
    getArguments(c::Union{BlockCommand, InlineCommand}) -> Vector{String}
Return the arguments of a command.
"""
function getArguments(c::Union{BlockCommand, InlineCommand})
    num = getNumArgs(c)
    result = Vector{String}(undef, num)
    for i in 1:num
        result[i] = getArgText(c, i-1)
    end
    return result
end

"""
    getAttributes(c::Union{CXComment, HTMLStartTag}) -> Vector{Pair{String, String}}
Return the attributes of an HTML tag.
"""
function getAttributes(c::Union{CXComment, HTMLStartTag})
    num = getNumAttrs(c)
    result = Vector{Pair{String, String}}(undef, num)
    for i in 1:num
        result[i] = (getAttrName(c, i-1) => getAttrValue(c, i-1))
    end
    return result
end

# clang_TParamCommandComment_isParamPositionValid
# clang_TParamCommandComment_getDepth
# clang_TParamCommandComment_getIndex


"""
    getSourceCode(cursor::Union{CXCursor, CLCursor}) -> String
Get source code for the cursor.
"""
function getSourceCode(cursor::Union{CXCursor, CLCursor})
    ext = getCursorExtent(cursor)
    range_begin = clang_getRangeStart(ext)
    range_end = clang_getRangeEnd(ext)
    file_begin = Ref{CXFile}(C_NULL)
    file_end = Ref{CXFile}(C_NULL)
    offset_begin = Ref{Cuint}(0)
    offset_end = Ref{Cuint}(0)
    clang_getExpansionLocation(range_begin, file_begin, C_NULL, C_NULL, offset_begin)
    clang_getExpansionLocation(range_end, file_end, C_NULL, C_NULL, offset_end)
    @assert !iszero(clang_File_isEqual(file_begin[], file_end[]))
    tu = getTranslationUnit(cursor)
    size = Ref{Csize_t}(0)
    buf = clang_getFileContents(tu, file_begin[], size)
    @assert offset_begin[] <= offset_end[] <= size[]
    unsafe_string(pointer(buf) + offset_begin[], offset_end[] - offset_begin[])
end
