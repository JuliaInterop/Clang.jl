# TODO test
function getFileName(cxf::CXFile)
    c = ccall( (:clang_getFileName, :libclang), CXString, (CXFile,), cxf)
    !(c.data == C_NULL) ? unsafe_string(c.data) : ""
end

# TODO move this to straight call
function getIncludedFile(cu::InclusionDirective)
    getFileName(ccall( (:clang_getIncludedFile, :libclang),
            CXFile,
            (CXCursor,),
            cu))
end

function getNullLocation()
    ccall( (:clang_getNullLocation, :libclang), CXSourceLocation, ())
end
function equalLocations(l1::CXSourceLocation, l2::CXSourceLocation)
    ccall( (:clang_equalLocations, :libclang), UInt32, (CXSourceLocation,CXSourceLocation), l1,l2 ) == 1
end
function getNullRange()
    ccall( (:clang_getNullRange, :libclang), CXSourceRange, ())
end

# returns CXSourceRange
function getRange(l1::CXSourceLocation,l2::CXSourceLocation,)
    ccall( (:clang_getRange, :libclang), CXSourceRange, (CXSourceLocation,CXSourceLocation), l1, l2) |>
        CXSourceRange
end
function equalRanges(r1::CXSourceRange,r2::CXSourceRange)
    ccall( (:clang_equalRanges, :libclang), UInt32, (CXSourceRange, CXSourceRange), r1, r2) == 1
end
function Range_isNull(cxr::CXSourceRange,)
    ccall( (:clang_Range_isNull, :libclang), Int32, (CXSourceRange,), cxr)
end
function getNullCursor()::CLCursor
    ccall( (:clang_getNullCursor, :libclang), CXCursor, () )
end
function getTranslationUnitCursor(tu::CXTranslationUnit)::CLCursor
    ccall( (:clang_getTranslationUnitCursor, :libclang), CXCursor, (CXTranslationUnit,), tu) |> CLCursor
end
function equalCursors(cu1,cu2)
    ccall( (:clang_equalCursors, :libclang), UInt32, (CXCursor, CXCursor), cu1, cu2) == 1
end
function Cursor_isNull(cu)
    ccall( (:clang_Cursor_isNull, :libclang), Int32, (CXCursor,), cu) == 1
end
function hashCursor(cu)
    ccall( (:clang_hashCursor, :libclang), UInt32, (CXCursor,), cu)
end
function getCursorKind(cu)
    ccall( (:clang_getCursorKind, :libclang), UInt32, (CXCursor,), cu)
end

# TODO test
function isDeclaration(k::CXCursorKind)
    ccall( (:clang_isDeclaration, :libclang), UInt32, (CXCursorKind,), k) == 1
end
function isReference(k::CXCursorKind)
    ccall( (:clang_isReference, :libclang), UInt32, (CXCursorKind,), k) == 1
end
#function getCursorLinkage(cu)
#    ccall( (:clang_getCursorLinkage, :libclang), CXLinkageKind, (CXCursor,), cu)
#end TODO
#function getCursorAvailability(cu::CXCursor,)
#    ccall( (:clang_getCursorAvailability, :libclang), CXAvailabilityKind, (CXCursor,), cu)
#end

#function getCursorLanguage(cu)
#    ccall( (:clang_getCursorLanguage, :libclang), CXLanguageKind, (CXCursor,), cu)
#end
function getCursorSemanticParent(cu)::CLCursor
    ccall( (:clang_getCursorSemanticParent, :libclang), CXCursor, (CXCursor,), cu)
end
function getCursorLexicalParent(cu)::CLCursor
    ccall( (:clang_getCursorLexicalParent, :libclang), CXCursor, (CXCursor,), cu)
end
function getCursorType(cu)
    ccall( (:clang_getCursorType, :libclang), CXType, (CXCursor,), cu)
end

function getTypedefDeclUnderlyingType(cu)
    ccall( (:clang_getTypedefDeclUnderlyingType, :libclang), CXType, (CXCursor,), cu)
end
function getEnumDeclIntegerType(cu)
    ccall( (:clang_getEnumDeclIntegerType, :libclang), CXType, (CXCursor,), cu)
end
function getEnumConstantDeclValue(cu)
    ccall( (:clang_getEnumConstantDeclValue, :libclang), Int64, (CXCursor,), cu)
end
function getEnumConstantDeclUnsignedValue(cu)
    ccall( (:clang_getEnumConstantDeclUnsignedValue, :libclang), UInt64, (CXCursor,), cu)
end
function Cursor_getNumArguments(cu)
    ccall( (:clang_Cursor_getNumArguments, :libclang), Int32, (CXCursor,), cu)
end
function Cursor_getArgument(cu,arg::Int32)::CLCursor
    ccall( (:clang_Cursor_getArgument, :libclang), CXCursor, (CXCursor,Int32), cu, arg)
end
function equalTypes(t1,t2)
    # TODO doc here is weird
    #   "Returns non-zero if the CXTypes represent the same type and zero otherwise."
    r = ccall( (:clang_equalTypes, :libclang), UInt32, (CXType,CXType), t1, t2)
    return r != 0
end
function getCanonicalType(t)::CLType
    ccall( (:clang_getCanonicalType, :libclang), CXType, (CXType,), t)
end
function isConstQualifiedType(t)
    ccall( (:clang_isConstQualifiedType, :libclang), UInt32, (CXType,), t) == 1
end
function isVolatileQualifiedType(t)
    ccall( (:clang_isVolatileQualifiedType, :libclang), UInt32, (CXType,), t) == 1
end
function isRestrictQualifiedType(t)
    ccall( (:clang_isRestrictQualifiedType, :libclang), UInt32, (CXType,), t)
end
function getPointeeType(t)::CLType
    ccall( (:clang_getPointeeType, :libclang), CXType, (CXType,), t)
end
function getTypeDeclaration(t)::CLType
    ccall( (:clang_getTypeDeclaration, :libclang), Nothing, (CXType,), t)
end
function getDeclObjCTypeEncoding(cu)::String
    ccall( (:clang_getDeclObjCTypeEncoding, :libclang), CXString, (CXCursor,), cu)
end
function getTypeKindSpelling(tk)
    s = ccall( (:clang_getTypeKindSpelling, :libclang), CXString, (CXTypeKind,), tk)
end
function getFunctionTypeCallingConv(t::CXType)::CLCallingConv
    ccall( (:clang_getFunctionTypeCallingConv, :libclang), Int32, (CXType,), t)
end
function getResultType(t::CXType)::CLType
    ccall( (:clang_getResultType, :libclang), CXType, (CXType,), t)
end
function getNumArgTypes(t::CXType)
    ccall( (:clang_getNumArgTypes, :libclang), Int32, (CXType,), t)
end
function getArgType(t::CXType,arg::UInt32)::CLType
    ccall( (:clang_getArgType, :libclang), CXType, (CXType,UInt32), t, arg)
end
function isFunctionTypeVariadic(t)
    ccall( (:clang_isFunctionTypeVariadic, :libclang), UInt32, (CXType,), t) == 1
end
function getCursorResultType(cu)::CLType
    ccall( (:clang_getCursorResultType, :libclang), CXType, (CXCursor,), cu)
end
function isPODType(t)
    ccall( (:clang_isPODType, :libclang), UInt32, (CXType,), t) == 1
end
function getElementType(t)::CLType
    ccall( (:clang_getElementType, :libclang), CXType, (CXType,), t)
end
function getNumElements(t)
    ccall( (:clang_getNumElements, :libclang), Int64, (CXType,), t)
end
function getArrayElementType(t)::CLType
    ccall( (:clang_getArrayElementType, :libclang), CXType, (CXType,), t)
end
function getArraySize(t)
    ccall( (:clang_getArraySize, :libclang), Int64, (CXType,), t)
end
function isVirtualBase(cu)
    ccall( (:clang_isVirtualBase, :libclang), UInt32, (CXCursor,), cu) == 1
end
function getCXXAccessSpecifier(cu)::CLCXXAccessSpecifier
    ccall( (:clang_getCXXAccessSpecifier, :libclang), Int64, (CXCursor,), cu)
end
function getNumOverloadedDecls(cu)
    ccall( (:clang_getNumOverloadedDecls, :libclang), UInt32, (CXCursor,), cu)
end
function getOverloadedDecl(cu,arg::UInt32)::CLCursor
    ccall( (:clang_getOverloadedDecl, :libclang), CXCursor, (CXCursor,UInt32), cu, arg)
end
function getCursorUSR(cu)::String
    c = ccall( (:clang_getCursorUSR, :libclang), CXString, (CXCursor,), cu)
end
function getCursorSpelling(cu)::String
    c = ccall( (:clang_getCursorSpelling, :libclang), CXString, (CXCursor,), cu)
end
function getCursorDisplayName(cu)::String
    c = ccall( (:clang_getCursorDisplayName, :libclang), CXString, (CXCursor,), cu)
end
function getCursorReferenced(cu)::CLCursor
    ccall( (:clang_getCursorReferenced, :libclang), CXCursor, (CXCursor,), cu)
end
function getCursorDefinition(cu)::CLCursor
    ccall( (:clang_getCursorDefinition, :libclang), CXCursor, (CXCursor,), cu)
end
function isCursorDefinition(cu)
    ccall( (:clang_isCursorDefinition, :libclang), UInt32, (CXCursor,), cu) == 1
end
function getCanonicalCursor(cu)::CLCursor
    ccall( (:clang_getCanonicalCursor, :libclang), CXCursor, (CXCursor,), cu)
end
function CXXMethod_isStatic(cu)
    ccall( (:clang_CXXMethod_isStatic, :libclang), UInt32, (CXCursor,), cu) == 1
end
function CXXMethod_isVirtual(cu)
    ccall( (:clang_CXXMethod_isVirtual, :libclang), UInt32, (CXCursor,), cu) == 1
end
function CXXMethod_isProtected(cu)
    ccall( (:clang_CXXMethod_isProtected, :libclang), UInt32, (CXCursor,), cu) == 1
end
function getTemplateCursorKind(cu)::CLCursorKind
    ccall( (:clang_getTemplateCursorKind, :libclang), Int32, (CXCursor,), cu)
end
function getSpecializedCursorTemplate(cu)::CLCursor
    ccall( (:clang_getSpecializedCursorTemplate, :libclang), CXCursor, (CXCursor,), cu)
end
function getTokenKind(cu)
    ccall( (:clang_getTokenKind, :libclang), Int32, (CXCursor,), cu)
end
function getTokenSpelling(tu,token)::String
    ccall( (:clang_getTokenSpelling, :libclang), CXString, (CXTranslationUnit,CXToken), tu, token)
end
function getCursorKindSpelling(ck)::String
    ccall( (:clang_getCursorKindSpelling, :libclang), CXString, (CXCursorKind,), ck)
end
function getClangVersion()
    c = ccall( (:clang_getClangVersion, :libclang), CXString, ())
end
function getCursorExtent(cu)
    ccall( (:clang_getCursorExtent, :libclang), CXSourceRange, (CXCursor,), cu)
end
function disposeTokens(tu::CXTranslationUnit, tokens::Ptr{CXToken}, numtokens::Cuint)
    ccall( (:clang_disposeTokens, :libclang), Nothing, (Ptr{Nothing}, Ptr{CXToken}, Cuint),
           tu, tokens, numtokens)
end
function tokenize(tu::CXTranslationUnit, sr::CXSourceRange)
    token_p = Ref{Ptr{CXToken}}()
    numtokens = Ref{Cuint}()

    ccall(  (:clang_tokenize, :libclang), Cuint,
            (CXTranslationUnit, CXSourceRange, Ref{Ptr{CXToken}}, Ref{Cuint}),
            tu, sr, token_p, numtokens)
    return TokenList(token_p[], convert(Cuint, numtokens[]), tu)
end
function Cursor_getTranslationUnit(cu)
    ccall( (:clang_Cursor_getTranslationUnit, :libclang), CXTranslationUnit, (CXCursor,), cu)
end
