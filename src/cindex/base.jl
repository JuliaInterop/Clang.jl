function getFileName(a1::CXFile,)
    c = CXString()
    ccall( (:wci_getFileName, libwci), Void, (CXFile,Ptr{Void},), a1, c.data,)
    return get_string(c)
end
function getIncludedFile(cu::InclusionDirective)
    getFileName(ccall( (:wci_getIncludedFile, libwci),
            Ptr{Void},
            (Ptr{UInt8},),
            pointer(cu.data)))
end
function getNullLocation()
    c = CXSourceLocation()
    ccall( (:wci_getNullLocation, libwci), Void, (Ptr{Void},),    c.data,)
    return c
end
function equalLocations(a1::CXSourceLocation,a2::CXSourceLocation,)
    ccall( (:wci_equalLocations, libwci), UInt32, (Ptr{Void},Ptr{Void},), a1.data,a2.data, )
end
function getNullRange()
    c = CXSourceRange()
    ccall( (:wci_getNullRange, libwci), Void, (Ptr{Void},),    c.data,)
    return c
end
function getRange(a1::CXSourceLocation,a2::CXSourceLocation,)
    c = CXSourceRange()
    ccall( (:wci_getRange, libwci), Void, (Ptr{Void},Ptr{Void},Ptr{Void},), a1.data,a2.data, c.data,)
    return c
end
function equalRanges(a1::CXSourceRange,a2::CXSourceRange,)
    ccall( (:wci_equalRanges, libwci), UInt32, (Ptr{Void},Ptr{Void},), a1.data,a2.data, )
end
function Range_isNull(a1::CXSourceRange,)
    ccall( (:wci_Range_isNull, libwci), Int32, (Ptr{Void},), a1.data, )
end
function getNullCursor()
    c = TmpCursor()
    ccall( (:wci_getNullCursor, libwci), Void, (Ptr{Void},),    c.data,)
    return CXCursor(c)
end
function getTranslationUnitCursor(a1::CXTranslationUnit,)
    c = TmpCursor()
    ccall( (:wci_getTranslationUnitCursor, libwci), Void, (CXTranslationUnit,Ptr{Void},), a1, c.data,)
    return CXCursor(c)
end
function equalCursors(a1::CLCursor,a2::CLCursor,)
    ccall( (:wci_equalCursors, libwci), UInt32, (Ptr{Void},Ptr{Void},), a1.data,a2.data, )
end
function Cursor_isNull(a1::CLCursor,)
    ccall( (:wci_Cursor_isNull, libwci), Int32, (Ptr{Void},), a1.data, )
end
function hashCursor(a1::CLCursor,)
    ccall( (:wci_hashCursor, libwci), UInt32, (Ptr{Void},), a1.data, )
end
function getCursorKind(a1::CLCursor,)
    ccall( (:wci_getCursorKind, libwci), UInt32, (Ptr{Void},), a1.data, )
end
function isDeclaration(a1::CXCursorKind,)
    ccall( (:wci_isDeclaration, libwci), UInt32, (CXCursorKind,), a1, )
end
function isReference(a1::CXCursorKind,)
    ccall( (:wci_isReference, libwci), UInt32, (CXCursorKind,), a1, )
end
function getCursorLinkage(a1::CLCursor,)
    ccall( (:wci_getCursorLinkage, libwci), CXLinkageKind, (Ptr{Void},), a1.data, )
end
function getCursorAvailability(a1::CLCursor,)
    ccall( (:wci_getCursorAvailability, libwci), CXAvailabilityKind, (Ptr{Void},), a1.data, )
end
function getCursorLanguage(a1::CLCursor,)
    ccall( (:wci_getCursorLanguage, libwci), CXLanguageKind, (Ptr{Void},), a1.data, )
end
function getCursorSemanticParent(a1::CLCursor,)
    c = TmpCursor()
    ccall( (:wci_getCursorSemanticParent, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXCursor(c)
end
function getCursorLexicalParent(a1::CLCursor,)
    c = TmpCursor()
    ccall( (:wci_getCursorLexicalParent, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXCursor(c)
end
function getCursorType(a1::CLCursor,)
    c = TmpType()
    ccall( (:wci_getCursorType, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXType(c)
end
function getTypedefDeclUnderlyingType(a1::CLCursor,)
    c = TmpType()
    ccall( (:wci_getTypedefDeclUnderlyingType, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXType(c)
end
function getEnumDeclIntegerType(a1::CLCursor,)
    c = TmpType()
    ccall( (:wci_getEnumDeclIntegerType, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXType(c)
end
function getEnumConstantDeclValue(a1::CLCursor,)
    ccall( (:wci_getEnumConstantDeclValue, libwci), Int64, (Ptr{Void},), a1.data, )
end
function getEnumConstantDeclUnsignedValue(a1::CLCursor,)
    ccall( (:wci_getEnumConstantDeclUnsignedValue, libwci), UInt64, (Ptr{Void},), a1.data, )
end
function Cursor_getNumArguments(a1::CLCursor,)
    ccall( (:wci_Cursor_getNumArguments, libwci), Int32, (Ptr{Void},), a1.data, )
end
function Cursor_getArgument(a1::CLCursor,a2::Int32,)
    c = TmpCursor()
    ccall( (:wci_Cursor_getArgument, libwci), Void, (Ptr{Void},Int32,Ptr{Void},), a1.data,a2, c.data,)
    return CXCursor(c)
end
function equalTypes(a1::CLType,a2::CLType,)
    ccall( (:wci_equalTypes, libwci), UInt32, (Ptr{Void},Ptr{Void},), a1.data,a2.data, )
end
function getCanonicalType(a1::CLType,)
    c = TmpType()
    ccall( (:wci_getCanonicalType, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXType(c)
end
function isConstQualifiedType(a1::CLType,)
    ccall( (:wci_isConstQualifiedType, libwci), UInt32, (Ptr{Void},), a1.data, )
end
function isVolatileQualifiedType(a1::CLType,)
    ccall( (:wci_isVolatileQualifiedType, libwci), UInt32, (Ptr{Void},), a1.data, )
end
function isRestrictQualifiedType(a1::CLType,)
    ccall( (:wci_isRestrictQualifiedType, libwci), UInt32, (Ptr{Void},), a1.data, )
end
function getPointeeType(a1::CLType,)
    c = TmpType()
    ccall( (:wci_getPointeeType, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXType(c)
end
function getTypeDeclaration(a1::CLType,)
    c = TmpCursor()
    ccall( (:wci_getTypeDeclaration, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXCursor(c)
end
function getDeclObjCTypeEncoding(a1::CLCursor,)
    c = CXString()
    ccall( (:wci_getDeclObjCTypeEncoding, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return get_string(c)
end
function getTypeKindSpelling(a1::CXTypeKind,)
    c = CXString()
    ccall( (:wci_getTypeKindSpelling, libwci), Void, (CXTypeKind,Ptr{Void},), a1, c.data,)
    return get_string(c)
end
function getFunctionTypeCallingConv(a1::CLType,)
    ccall( (:wci_getFunctionTypeCallingConv, libwci), Int32, (Ptr{Void},), a1.data, )
end
function getResultType(a1::CLType,)
    c = TmpType()
    ccall( (:wci_getResultType, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXType(c)
end
function getNumArgTypes(a1::CLType,)
    ccall( (:wci_getNumArgTypes, libwci), Int32, (Ptr{Void},), a1.data, )
end
function getArgType(a1::CLType,a2::UInt32,)
    c = TmpType()
    ccall( (:wci_getArgType, libwci), Void, (Ptr{Void},UInt32,Ptr{Void},), a1.data,a2, c.data,)
    return CXType(c)
end
function isFunctionTypeVariadic(a1::CLType,)
    ccall( (:wci_isFunctionTypeVariadic, libwci), UInt32, (Ptr{Void},), a1.data, )
end
function getCursorResultType(a1::CLCursor,)
    c = TmpType()
    ccall( (:wci_getCursorResultType, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXType(c)
end
function isPODType(a1::CLType,)
    ccall( (:wci_isPODType, libwci), UInt32, (Ptr{Void},), a1.data, )
end
function getElementType(a1::CLType,)
    c = TmpType()
    ccall( (:wci_getElementType, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXType(c)
end
function getNumElements(a1::CLType,)
    ccall( (:wci_getNumElements, libwci), Int64, (Ptr{Void},), a1.data, )
end
function getArrayElementType(a1::CLType,)
    c = TmpType()
    ccall( (:wci_getArrayElementType, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXType(c)
end
function getArraySize(a1::CLType,)
    ccall( (:wci_getArraySize, libwci), Int64, (Ptr{Void},), a1.data, )
end
function isVirtualBase(a1::CLCursor,)
    ccall( (:wci_isVirtualBase, libwci), UInt32, (Ptr{Void},), a1.data, )
end
function getCXXAccessSpecifier(a1::CLCursor,)
    ccall( (:wci_getCXXAccessSpecifier, libwci), Int64, (Ptr{Void},), a1.data, )
end
function getNumOverloadedDecls(a1::CLCursor,)
    ccall( (:wci_getNumOverloadedDecls, libwci), UInt32, (Ptr{Void},), a1.data, )
end
function getOverloadedDecl(a1::CLCursor,a2::UInt32,)
    c = TmpCursor()
    ccall( (:wci_getOverloadedDecl, libwci), Void, (Ptr{Void},UInt32,Ptr{Void},), a1.data,a2, c.data,)
    return CXCursor(c)
end
function getCursorUSR(a1::CLCursor,)
    c = CXString()
    ccall( (:wci_getCursorUSR, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return get_string(c)
end
function getCursorSpelling(a1::CLCursor,)
    c = CXString()
    ccall( (:wci_getCursorSpelling, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return get_string(c)
end
function getCursorDisplayName(a1::CLCursor,)
    c = CXString()
    ccall( (:wci_getCursorDisplayName, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return get_string(c)
end
function getCursorReferenced(a1::CLCursor,)
    c = TmpCursor()
    ccall( (:wci_getCursorReferenced, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXCursor(c)
end
function getCursorDefinition(a1::CLCursor,)
    c = TmpCursor()
    ccall( (:wci_getCursorDefinition, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXCursor(c)
end
function isCursorDefinition(a1::CLCursor,)
    ccall( (:wci_isCursorDefinition, libwci), UInt32, (Ptr{Void},), a1.data, )
end
function getCanonicalCursor(a1::CLCursor,)
    c = TmpCursor()
    ccall( (:wci_getCanonicalCursor, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXCursor(c)
end
function CXXMethod_isStatic(a1::CLCursor,)
    ccall( (:wci_CXXMethod_isStatic, libwci), UInt32, (Ptr{Void},), a1.data, )
end
function CXXMethod_isVirtual(a1::CLCursor,)
    ccall( (:wci_CXXMethod_isVirtual, libwci), UInt32, (Ptr{Void},), a1.data, )
end
function CXXMethod_isProtected(a1::CLCursor,)
    ccall( (:wci_CXXMethod_isProtected, libwci), UInt32, (Ptr{Void},), a1.data, )
end
function getTemplateCursorKind(a1::CLCursor,)
    ccall( (:wci_getTemplateCursorKind, libwci), Int32, (Ptr{Void},), a1.data, )
end
function getSpecializedCursorTemplate(a1::CLCursor,)
    c = TmpCursor()
    ccall( (:wci_getSpecializedCursorTemplate, libwci), Void, (Ptr{Void},Ptr{Void},), a1.data, c.data,)
    return CXCursor(c)
end
function getTokenKind(a1::CXToken,)
    ccall( (:wci_getTokenKind, libwci), Int32, (Ptr{Void},), a1.data, )
end
function getTokenSpelling(a1::CXTranslationUnit,a2::CXToken,)
    c = CXString()
    ccall( (:wci_getTokenSpelling, libwci), Void, (CXTranslationUnit,Ptr{Void},Ptr{Void},), a1,a2.data, c.data,)
    return get_string(c)
end
function getCursorKindSpelling(a1::CXCursorKind,)
    c = CXString()
    ccall( (:wci_getCursorKindSpelling, libwci), Void, (CXCursorKind,Ptr{Void},), a1, c.data,)
    return get_string(c)
end
function getClangVersion()
    c = CXString()
    ccall( (:wci_getClangVersion, libwci), Void, (Ptr{Void},),    c.data,)
    return get_string(c)
end
function getCursorExtent(a1::CLCursor)
    c = CXSourceRange()
    ccall( (:wci_getCursorExtent, libwci), Void, (Ptr{Void},Ptr{Void}), a1.data, c.data)
    return c
end
function disposeTokens(tu::CXTranslationUnit, tokens::Ptr{_CXToken}, numtokens::Cuint)
    ccall( (:clang_disposeTokens, :libclang), Void, (Ptr{Void}, Ptr{_CXToken}, Cuint),
           tu, tokens, numtokens)
end
function tokenize(tu::CXTranslationUnit, sr::CXSourceRange)
    tokens = Ptr{_CXToken}[C_NULL]
    numtokens = ccall( (:wci_tokenize, libwci), Cuint, (Ptr{Void}, Ptr{Void}, Ptr{_CXToken}),
            tu, sr.data, pointer(tokens))
    return TokenList(tokens[1], convert(Cuint, numtokens - 1), tu)
end
function Cursor_getTranslationUnit(cu::CLCursor)
    ccall( (:wci_Cursor_getTranslationUnit, libwci), CXTranslationUnit, (Ptr{Void},), cu.data)
end
