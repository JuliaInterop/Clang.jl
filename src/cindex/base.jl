# TODO test
function getFileName(cxf::CXFile)
    c = ccall( (:clang_getFileName, libwci), CXString, (CXFile,), cxf)
    !(c.data == C_NULL) ? unsafe_string(c.data) : ""
end

# TODO move this to straight call
function getIncludedFile(cu::InclusionDirective)
    getFileName(ccall( (:wci_getIncludedFile, libwci),
            Ptr{Void},
            (Ptr{UInt8},),
            pointer(cu.data)))
end

function getNullLocation()
    ccall( (:clang_getNullLocation, :libclang), CXSourceLocation, ())
end
function equalLocations(l1::CXSourceLocation, l2::CXSourceLocation)
    ccall( (:clang_equalLocations, :libclang), Uint32, (CXSourceLocation,CXSourceLocation), l1,l2 ) == 1
end
function getNullRange()
    ccall( (:clang_getNullRange, :libclang), CXSourceRange, ())
end

# returns CXSourceRange
function getRange(l1::CXSourceLocation,l2::CXSourceLocation,)
    ccall( (:clang_getRange, :libclang), CXSourceRange, (CXSourceLocation,CXSourceLocation), l1, l2)
end
function equalRanges(r1::CXSourceRange,r2::CXSourceRange)
    ccall( (:clang_equalRanges, :libclang), Uint32, (CXSourceRange, CXSourceRange), r1, r2) == 1
end
function Range_isNull(cxr::CXSourceRange,)
    ccall( (:clang_Range_isNull, :libclang), Int32, (CXSourceRange,), cxr)
end
function getNullCursor()
    ccall( (:clang_getNullCursor, :libclang), CXCursorBase, () )
end
function getTranslationUnitCursor(tu::CXTranslationUnit)
    ccall( (:clang_getTranslationUnitCursor, :libclang), CXCursor, (CXTranslationUnit,), tu)
end
function equalCursors(cu1::CXCursor,cu2::CXCursor)
    ccall( (:clang_equalCursors, :libclang), UInt32, (CXCursor, CXCursor), cu1, cu2) == 1
end
function Cursor_isNull(cu::CXCursor)
    ccall( (:clang_Cursor_isNull, :libclang), Int32, (CXCursor,), cu) == 1
end
function hashCursor(cu::CXCursor)
    ccall( (:clang_hashCursor, :libclang), UInt32, (CXCursor,), cu)
end
function getCursorKind(cu::CXCursor)
    ccall( (:clang_getCursorKind, :libclang), Uint32, (CXCursor,), cu)
end

# TODO test
function isDeclaration(k::CXCursorKind)
    ccall( (:clang_isDeclaration, :libclang), Uint32, (CXCursorKind,), k) == 1
end
function isReference(k::CXCursorKind,)
    ccall( (:clang_isReference, :libclang), Uint32, (CXCursorKind,), k) == 1
end
function getCursorLinkage(cu::CXCursor)
    ccall( (:clang_getCursorLinkage, :libclang), CXLinkageKind, (CXCursor,), cu)
end
function getCursorAvailability(cu::CXCursor,)
    ccall( (:clang_getCursorAvailability, :libclang), CXAvailabilityKind, (CXCursor,), cu)
end

function getCursorLanguage(cu::CXCursor)
    ccall( (:clang_getCursorLanguage, :libclang), CXLanguageKind, (CXCursor,), cu)
end
function getCursorSemanticParent(cu::CXCursor,)
    ccall( (:clang_getCursorSemanticParent, :libclang), CXCursorBase, (CXCursor,), cu)
end
function getCursorLexicalParent(cu::CXCursor)
    ccall( (:clang_getCursorLexicalParent, :libclang), CXCursorBase, (CXCursor,), cu)
end
function getCursorType(cu::CXCursor)
    ccall( (:clang_getCursorType, :libclang), CXType, (CXCursor,), cu)
end

function getTypedefDeclUnderlyingType(cu::CXCursor)
    ccall( (:clang_getTypedefDeclUnderlyingType, :libclang), CXType, (CXCursor,), cu)
end
function getEnumDeclIntegerType(cu::CXCursor)
    ccall( (:clang_getEnumDeclIntegerType, :libclang), CXType, (CXCursor,), cu)
end
function getEnumConstantDeclValue(cu::CXCursor)
    ccall( (:clang_getEnumConstantDeclValue, :libclang), Int64, (CXCursor,), cu)
end
function getEnumConstantDeclUnsignedValue(cu::CXCursor)
    ccall( (:clang_getEnumConstantDeclUnsignedValue, :libclang), Uint64, (CXCursor,), cu)
end
function Cursor_getNumArguments(cu::CXCursor)
    ccall( (:clang_Cursor_getNumArguments, :libclang), Int32, (CXCursor,), cu)
end
function Cursor_getArgument(cu::CXCursor,arg::Int32)
    ccall( (:clang_Cursor_getArgument, :libclang), CXCursorBase, (CXCursor,Int32), cu, arg)
end
function equalTypes(t1::CXType,t2::CXType)
    ccall( (:clang_equalTypes, :libclang), Uint32, (CXType,CXType), t1, t2)
end
function getCanonicalType(t::CXType)
    ccall( (:clang_getCanonicalType, :libclang), CXType, (CXType,), t)
end
function isConstQualifiedType(t::CXType)
    ccall( (:clang_isConstQualifiedType, :libclang), Uint32, (CXType,), t) == 1
end
function isVolatileQualifiedType(t::CXType)
    ccall( (:clang_isVolatileQualifiedType, :libclang), Uint32, (CXType,), t) == 1
end
function isRestrictQualifiedType(t::CXType,)
    ccall( (:clang_isRestrictQualifiedType, :libclang), Uint32, (CXType,), t)
end
function getPointeeType(t::CXType)
    ccall( (:clang_getPointeeType, :libclang), CXType, (CXType,), t)
end
function getTypeDeclaration(t::CXType,)
    ccall( (:clang_getTypeDeclaration, :libclang), Void, (CXType,), t)
end
function getDeclObjCTypeEncoding(cu::CXCursor)
    ccall( (:clang_getDeclObjCTypeEncoding, :libclang), CXString, (CXCursor,), cu)
end
function getTypeKindSpelling(tk::CXTypeKind)
    s = ccall( (:clang_getTypeKindSpelling, :libclang), CXString, (CXTypeKind,), tk)
    unsafe_string(s.data)
end
function getFunctionTypeCallingConv(t::CXType)
    ccall( (:clang_getFunctionTypeCallingConv, :libclang), Int32, (CXType,), t)
end
function getResultType(t::CXType)
    ccall( (:clang_getResultType, :libclang), CXType, (CXType,), t)
end
function getNumArgTypes(t::CXType)
    ccall( (:clang_getNumArgTypes, :libclang), Int32, (CXType,), t)
end
function getArgType(t::CXType,arg::UInt32)
    ccall( (:clang_getArgType, :libclang), CXType, (CXType,Uint32), t, arg)
end
function isFunctionTypeVariadic(a1::CLType,)
    ccall( (:clang_isFunctionTypeVariadic, :libclang), Uint32, (Ptr{Void},), a1.data, )
end
function getCursorResultType(cu::CXCursor,)
    ccall( (:clang_getCursorResultType, :libclang), CXType, (CXCursor,), cu)
end
function isPODType(t::CXType)
    ccall( (:clang_isPODType, :libclang), Uint32, (CXType,), t)
end
function getElementType(t::CXType)
    ccall( (:clang_getElementType, :libclang), CXType, (CXType,), t)
end
function getNumElements(t::CXType,)
    ccall( (:clang_getNumElements, :libclang), Int64, (CXType,), t)
end
function getArrayElementType(t::CXType)
    ccall( (:clang_getArrayElementType, :libclang), CXType, (CXType,), t)
end
function getArraySize(t::CXType)
    ccall( (:clang_getArraySize, :libclang), Int64, (CXType,), t)
end
function isVirtualBase(cu::CXCursor)
    ccall( (:clang_isVirtualBase, :libclang), Uint32, (CXCursor,), cu) == 1
end
function getCXXAccessSpecifier(cu::CXCursor)
    ccall( (:clang_getCXXAccessSpecifier, :libclang), Int64, (CXCursor,), cu)
end
function getNumOverloadedDecls(cu::CXCursor)
    ccall( (:clang_getNumOverloadedDecls, :libclang), Uint32, (CXCursor,), cu)
end
function getOverloadedDecl(cu::CXCursor,arg::UInt32)
    ccall( (:clang_getOverloadedDecl, :libclang), CXCursorBase, (CXCursor,Uint32), cu, arg)
end
function getCursorUSR(cu::CXCursor)
    c = ccall( (:clang_getCursorUSR, :libclang), CXString, (CXCursor,), cu)
    unsafe_string(c.data)
end
function getCursorSpelling(cu::CXCursor)
    c = ccall( (:clang_getCursorSpelling, :libclang), CXString, (CXString,), cu)
    unsafe_string(c.data)
end
function getCursorDisplayName(cu::CXCursor)
    c = ccall( (:clang_getCursorDisplayName, :libclang), CXString, (CXCursor,), cu)
    unsafe_string(c.data)
end
function getCursorReferenced(cu::CXCursor)
    ccall( (:clang_getCursorReferenced, :libclang), CXCursorBase, (CXCursor,), cu)
end
function getCursorDefinition(cu::CXCursor)
    ccall( (:clang_getCursorDefinition, :libclang), CXCursorBase, (CXCursor,), cu)
end
function isCursorDefinition(cu::CXCursor)
    ccall( (:clang_isCursorDefinition, :libclang), Uint32, (CXCursor,), cu)
end
function getCanonicalCursor(cu::CXCursor)
    ccall( (:clang_getCanonicalCursor, :libclang), CXCursorBase, (CXCursor,), cu)
end
function CXXMethod_isStatic(cu::CXCursor,)
    ccall( (:clang_CXXMethod_isStatic, :libclang), Uint32, (CXCursor,), cu)
end
function CXXMethod_isVirtual(cu::CXCursor,)
    ccall( (:clang_CXXMethod_isVirtual, :libclang), Uint32, (CXCursor,), cu)
end
function CXXMethod_isProtected(cu::CXCursor)
    ccall( (:clang_CXXMethod_isProtected, :libclang), Uint32, (CXCursor,), cu)
end
function getTemplateCursorKind(cu::CXCursor,)
    ccall( (:clang_getTemplateCursorKind, :libclang), Int32, (CXCursor,), cu)
end
function getSpecializedCursorTemplate(cu::CXCursor)
    ccall( (:clang_getSpecializedCursorTemplate, :libclang), CXCursorBase, (CXCursor,), cu)
end
function getTokenKind(cu::CXCursor)
    ccall( (:clang_getTokenKind, :libclang), Int32, (CXCursor,), cu)
end
function getTokenSpelling(tu::CXTranslationUnit,tk::CXToken)
    c = ccall( (:clang_getTokenSpelling, :libclang), CXString, (CXTranslationUnit,CXToken), tu, tk)
    return get_string(c)
end
function getCursorKindSpelling(ck::CXCursorKind)
    c = ccall( (:clang_getCursorKindSpelling, :libclang), CXString, (CXCursorKind,), ck)
    unsafe_string(c.data)
end
function getClangVersion()
    c = ccall( (:clang_getClangVersion, :libclang), CXString, ())
    unsafe_string(c.data)
end
function getCursorExtent(cu::CXCursor)
    ccall( (:wci_getCursorExtent, :libclang), CXSourceRange, (CXCursor,), cu)
end
function disposeTokens(tu::CXTranslationUnit, tokens::Ptr{CXToken}, numtokens::Cuint)
    ccall( (:clang_disposeTokens, :libclang), Void, (Ptr{Void}, Ptr{CXToken}, Cuint),
           tu, tokens, numtokens)
end
function tokenize(tu::CXTranslationUnit, sr::CXSourceRange)
    tokens = Ptr{CXToken}[C_NULL]
    numtokens = Ref{Cuint}()
    numtokens = ccall( (:clang_tokenize, libclang), Cuint, (CXTranslationUnit, CXSourceRange, Ptr{Ptr{CXToken}}, Ref{Cuint}),
            tu, sr, tokens, numtokens)
#    return TokenList(tokens[1], convert(Cuint, numtokens - 1), tu)
end
function Cursor_getTranslationUnit(cu::CXCursor)::CXCursor
    ccall( (:clang_Cursor_getTranslationUnit, libwci), CXTranslationUnit, (CXCursor,), cu)
end
