# Automatically generated from Index.h
#   using dumpenums.jl
# enum ENUM_CXAvailabilityKind
const CXAvailability_Available = 0
const CXAvailability_Deprecated = 1
const CXAvailability_NotAvailable = 2
const CXAvailability_NotAccessible = 3
# end

# enum CXGlobalOptFlags
const CXGlobalOpt_None = 0
const CXGlobalOpt_ThreadBackgroundPriorityForIndexing = 1
const CXGlobalOpt_ThreadBackgroundPriorityForEditing = 2
const CXGlobalOpt_ThreadBackgroundPriorityForAll = 3
# end

# enum ENUM_CXDiagnosticSeverity
const CXDiagnostic_Ignored = 0
const CXDiagnostic_Note = 1
const CXDiagnostic_Warning = 2
const CXDiagnostic_Error = 3
const CXDiagnostic_Fatal = 4
# end
# const CXDiagnostic == ENUM_CXDiagnosticSeverity

# enum ENUM_CXLoadDiag_Error
const CXLoadDiag_None = 0
const CXLoadDiag_Unknown = 1
const CXLoadDiag_CannotLoad = 2
const CXLoadDiag_InvalidFile = 3
# end

# enum ENUM_CXDiagnosticDisplayOptions
const CXDiagnostic_DisplaySourceLocation = 1
const CXDiagnostic_DisplayColumn = 2
const CXDiagnostic_DisplaySourceRanges = 4
const CXDiagnostic_DisplayOption = 8
const CXDiagnostic_DisplayCategoryId = 16
const CXDiagnostic_DisplayCategoryName = 32
# end

# enum ENUM_CXTranslationUnit_Flags
const CXTranslationUnit_None = 0
const CXTranslationUnit_DetailedPreprocessingRecord = 1
const CXTranslationUnit_Incomplete = 2
const CXTranslationUnit_PrecompiledPreamble = 4
const CXTranslationUnit_CacheCompletionResults = 8
const CXTranslationUnit_CXXPrecompiledPreamble = 16
const CXTranslationUnit_CXXChainedPCH = 32
const CXTranslationUnit_SkipFunctionBodies = 64
# end

# enum ENUM_CXSaveTranslationUnit_Flags
const CXSaveTranslationUnit_None = 0
# end

# enum ENUM_CXSaveError
const CXSaveError_None = 0
const CXSaveError_Unknown = 1
const CXSaveError_TranslationErrors = 2
const CXSaveError_InvalidTU = 3
# end

# enum ENUM_CXReparse_Flags
const CXReparse_None = 0
# end

# enum ENUM_CXTUResourceUsageKind
const CXTUResourceUsage_AST = 1
const CXTUResourceUsage_Identifiers = 2
const CXTUResourceUsage_Selectors = 3
const CXTUResourceUsage_GlobalCompletionResults = 4
const CXTUResourceUsage_SourceManagerContentCache = 5
const CXTUResourceUsage_AST_SideTables = 6
const CXTUResourceUsage_SourceManager_Membuffer_Malloc = 7
const CXTUResourceUsage_SourceManager_Membuffer_MMap = 8
const CXTUResourceUsage_ExternalASTSource_Membuffer_Malloc = 9
const CXTUResourceUsage_ExternalASTSource_Membuffer_MMap = 10
const CXTUResourceUsage_Preprocessor = 11
const CXTUResourceUsage_PreprocessingRecord = 12
const CXTUResourceUsage_SourceManager_DataStructures = 13
const CXTUResourceUsage_Preprocessor_HeaderSearch = 14
const CXTUResourceUsage_MEMORY_IN_BYTES_BEGIN = 1
const CXTUResourceUsage_MEMORY_IN_BYTES_END = 14
const CXTUResourceUsage_First = 1
const CXTUResourceUsage_Last = 14
# end

# enum ENUM_CXCursorKind
const UNEXPOSEDDECL = 1
const STRUCTDECL = 2
const UNIONDECL = 3
const CLASSDECL = 4
const ENUMDECL = 5
const FIELDDECL = 6
const ENUMCONSTANTDECL = 7
const FUNCTIONDECL = 8
const VARDECL = 9
const PARMDECL = 10
const OBJCINTERFACEDECL = 11
const OBJCCATEGORYDECL = 12
const OBJCPROTOCOLDECL = 13
const OBJCPROPERTYDECL = 14
const OBJCIVARDECL = 15
const OBJCINSTANCEMETHODDECL = 16
const OBJCCLASSMETHODDECL = 17
const OBJCIMPLEMENTATIONDECL = 18
const OBJCCATEGORYIMPLDECL = 19
const TYPEDEFDECL = 20
const CXXMETHOD = 21
const NAMESPACE = 22
const LINKAGESPEC = 23
const CONSTRUCTOR = 24
const DESTRUCTOR = 25
const CONVERSIONFUNCTION = 26
const TEMPLATETYPEPARAMETER = 27
const NONTYPETEMPLATEPARAMETER = 28
const TEMPLATETEMPLATEPARAMETER = 29
const FUNCTIONTEMPLATE = 30
const CLASSTEMPLATE = 31
const CLASSTEMPLATEPARTIALSPECIALIZATION = 32
const NAMESPACEALIAS = 33
const USINGDIRECTIVE = 34
const USINGDECLARATION = 35
const TYPEALIASDECL = 36
const OBJCSYNTHESIZEDECL = 37
const OBJCDYNAMICDECL = 38
const CXXACCESSSPECIFIER = 39
const FIRSTDECL = 1
const LASTDECL = 39
const FIRSTREF = 40
const OBJCSUPERCLASSREF = 40
const OBJCPROTOCOLREF = 41
const OBJCCLASSREF = 42
const TYPEREF = 43
const CXXBASESPECIFIER = 44
const TEMPLATEREF = 45
const NAMESPACEREF = 46
const MEMBERREF = 47
const LABELREF = 48
const OVERLOADEDDECLREF = 49
const VARIABLEREF = 50
const LASTREF = 50
const FIRSTINVALID = 70
const INVALIDFILE = 70
const NODECLFOUND = 71
const NOTIMPLEMENTED = 72
const INVALIDCODE = 73
const LASTINVALID = 73
const FIRSTEXPR = 100
const UNEXPOSEDEXPR = 100
const DECLREFEXPR = 101
const MEMBERREFEXPR = 102
const CALLEXPR = 103
const OBJCMESSAGEEXPR = 104
const BLOCKEXPR = 105
const INTEGERLITERAL = 106
const FLOATINGLITERAL = 107
const IMAGINARYLITERAL = 108
const STRINGLITERAL = 109
const CHARACTERLITERAL = 110
const PARENEXPR = 111
const UNARYOPERATOR = 112
const ARRAYSUBSCRIPTEXPR = 113
const BINARYOPERATOR = 114
const COMPOUNDASSIGNOPERATOR = 115
const CONDITIONALOPERATOR = 116
const CSTYLECASTEXPR = 117
const COMPOUNDLITERALEXPR = 118
const INITLISTEXPR = 119
const ADDRLABELEXPR = 120
const STMTEXPR = 121
const GENERICSELECTIONEXPR = 122
const GNUNULLEXPR = 123
const CXXSTATICCASTEXPR = 124
const CXXDYNAMICCASTEXPR = 125
const CXXREINTERPRETCASTEXPR = 126
const CXXCONSTCASTEXPR = 127
const CXXFUNCTIONALCASTEXPR = 128
const CXXTYPEIDEXPR = 129
const CXXBOOLLITERALEXPR = 130
const CXXNULLPTRLITERALEXPR = 131
const CXXTHISEXPR = 132
const CXXTHROWEXPR = 133
const CXXNEWEXPR = 134
const CXXDELETEEXPR = 135
const UNARYEXPR = 136
const OBJCSTRINGLITERAL = 137
const OBJCENCODEEXPR = 138
const OBJCSELECTOREXPR = 139
const OBJCPROTOCOLEXPR = 140
const OBJCBRIDGEDCASTEXPR = 141
const PACKEXPANSIONEXPR = 142
const SIZEOFPACKEXPR = 143
const LAMBDAEXPR = 144
const OBJCBOOLLITERALEXPR = 145
const LASTEXPR = 145
const FIRSTSTMT = 200
const UNEXPOSEDSTMT = 200
const LABELSTMT = 201
const COMPOUNDSTMT = 202
const CASESTMT = 203
const DEFAULTSTMT = 204
const IFSTMT = 205
const SWITCHSTMT = 206
const WHILESTMT = 207
const DOSTMT = 208
const FORSTMT = 209
const GOTOSTMT = 210
const INDIRECTGOTOSTMT = 211
const CONTINUESTMT = 212
const BREAKSTMT = 213
const RETURNSTMT = 214
const ASMSTMT = 215
const OBJCATTRYSTMT = 216
const OBJCATCATCHSTMT = 217
const OBJCATFINALLYSTMT = 218
const OBJCATTHROWSTMT = 219
const OBJCATSYNCHRONIZEDSTMT = 220
const OBJCAUTORELEASEPOOLSTMT = 221
const OBJCFORCOLLECTIONSTMT = 222
const CXXCATCHSTMT = 223
const CXXTRYSTMT = 224
const CXXFORRANGESTMT = 225
const SEHTRYSTMT = 226
const SEHEXCEPTSTMT = 227
const SEHFINALLYSTMT = 228
const NULLSTMT = 230
const DECLSTMT = 231
const LASTSTMT = 231
const TRANSLATIONUNIT = 300
const FIRSTATTR = 400
const UNEXPOSEDATTR = 400
const IBACTIONATTR = 401
const IBOUTLETATTR = 402
const IBOUTLETCOLLECTIONATTR = 403
const CXXFINALATTR = 404
const CXXOVERRIDEATTR = 405
const ANNOTATEATTR = 406
const ASMLABELATTR = 407
const LASTATTR = 407
const PREPROCESSINGDIRECTIVE = 500
const MACRODEFINITION = 501
const MACROEXPANSION = 502
const MACROINSTANTIATION = 502
const INCLUSIONDIRECTIVE = 503
const FIRSTPREPROCESSING = 500
const LASTPREPROCESSING = 503
# end

# enum ENUM_CXLinkageKind
const CXLinkage_Invalid = 0
const CXLinkage_NoLinkage = 1
const CXLinkage_Internal = 2
const CXLinkage_UniqueExternal = 3
const CXLinkage_External = 4
# end

# enum ENUM_CXLanguageKind
const CXLanguage_Invalid = 0
const CXLanguage_C = 1
const CXLanguage_ObjC = 2
const CXLanguage_CPlusPlus = 3
# end

# enum ENUM_CXTypeKind
const INVALID = 0
const UNEXPOSED = 1
const VOID = 2
const BOOL = 3
const CHAR_U = 4
const UCHAR = 5
const CHAR16 = 6
const CHAR32 = 7
const USHORT = 8
const UINT = 9
const ULONG = 10
const ULONGLONG = 11
const UINT128 = 12
const CHAR_S = 13
const SCHAR = 14
const WCHAR = 15
const SHORT = 16
const INT = 17
const LONG = 18
const LONGLONG = 19
const INT128 = 20
const FLOAT = 21
const DOUBLE = 22
const LONGDOUBLE = 23
const NULLPTR = 24
const OVERLOAD = 25
const DEPENDENT = 26
const OBJCID = 27
const OBJCCLASS = 28
const OBJCSEL = 29
const FIRSTBUILTIN = 2
const LASTBUILTIN = 29
const COMPLEX = 100
const POINTER = 101
const BLOCKPOINTER = 102
const LVALUEREFERENCE = 103
const RVALUEREFERENCE = 104
const RECORD = 105
const ENUM = 106
const TYPEDEF = 107
const OBJCINTERFACE = 108
const OBJCOBJECTPOINTER = 109
const FUNCTIONNOPROTO = 110
const FUNCTIONPROTO = 111
const CONSTANTARRAY = 112
const VECTOR = 113
# end

# enum ENUM_CXCallingConv
const CXCallingConv_Default = 0
const CXCallingConv_C = 1
const CXCallingConv_X86StdCall = 2
const CXCallingConv_X86FastCall = 3
const CXCallingConv_X86ThisCall = 4
const CXCallingConv_X86Pascal = 5
const CXCallingConv_AAPCS = 6
const CXCallingConv_AAPCS_VFP = 7
const CXCallingConv_Invalid = 100
const CXCallingConv_Unexposed = 200
# end

# enum ENUM_CX_CXXAccessSpecifier
const CX_CXXInvalidAccessSpecifier = 0
const CX_CXXPublic = 1
const CX_CXXProtected = 2
const CX_CXXPrivate = 3
# end

# enum ENUM_CXChildVisitResult
const CXChildVisit_Break = 0
const CXChildVisit_Continue = 1
const CXChildVisit_Recurse = 2
# end
# const CXCursorVisitor == ENUM_CXChildVisitResult

# enum ENUM_CXNameRefFlags
const CXNameRange_WantQualifier = 1
const CXNameRange_WantTemplateArgs = 2
const CXNameRange_WantSinglePiece = 4
# end

# enum ENUM_CXTokenKind
const CXToken_Punctuation = 0
const CXToken_Keyword = 1
const CXToken_Identifier = 2
const CXToken_Literal = 3
const CXToken_Comment = 4
# end
# const CXTokenKind == ENUM_CXTokenKind

# enum ENUM_CXCompletionChunkKind
const CXCompletionChunk_Optional = 0
const CXCompletionChunk_TypedText = 1
const CXCompletionChunk_Text = 2
const CXCompletionChunk_Placeholder = 3
const CXCompletionChunk_Informative = 4
const CXCompletionChunk_CurrentParameter = 5
const CXCompletionChunk_LeftParen = 6
const CXCompletionChunk_RightParen = 7
const CXCompletionChunk_LeftBracket = 8
const CXCompletionChunk_RightBracket = 9
const CXCompletionChunk_LeftBrace = 10
const CXCompletionChunk_RightBrace = 11
const CXCompletionChunk_LeftAngle = 12
const CXCompletionChunk_RightAngle = 13
const CXCompletionChunk_Comma = 14
const CXCompletionChunk_ResultType = 15
const CXCompletionChunk_Colon = 16
const CXCompletionChunk_SemiColon = 17
const CXCompletionChunk_Equal = 18
const CXCompletionChunk_HorizontalSpace = 19
const CXCompletionChunk_VerticalSpace = 20
# end

# enum ENUM_CXCodeComplete_Flags
const CXCodeComplete_IncludeMacros = 1
const CXCodeComplete_IncludeCodePatterns = 2
# end

# enum ENUM_CXCompletionContext
const CXCompletionContext_Unexposed = 0
const CXCompletionContext_AnyType = 1
const CXCompletionContext_AnyValue = 2
const CXCompletionContext_ObjCObjectValue = 4
const CXCompletionContext_ObjCSelectorValue = 8
const CXCompletionContext_CXXClassTypeValue = 16
const CXCompletionContext_DotMemberAccess = 32
const CXCompletionContext_ArrowMemberAccess = 64
const CXCompletionContext_ObjCPropertyAccess = 128
const CXCompletionContext_EnumTag = 256
const CXCompletionContext_UnionTag = 512
const CXCompletionContext_StructTag = 1024
const CXCompletionContext_ClassTag = 2048
const CXCompletionContext_Namespace = 4096
const CXCompletionContext_NestedNameSpecifier = 8192
const CXCompletionContext_ObjCInterface = 16384
const CXCompletionContext_ObjCProtocol = 32768
const CXCompletionContext_ObjCCategory = 65536
const CXCompletionContext_ObjCInstanceMessage = 131072
const CXCompletionContext_ObjCClassMessage = 262144
const CXCompletionContext_ObjCSelectorName = 524288
const CXCompletionContext_MacroName = 1048576
const CXCompletionContext_NaturalLanguage = 2097152
const CXCompletionContext_Unknown = 4194303
# end

# enum ENUM_CXVisitorResult
const CXVisit_Break = 0
const CXVisit_Continue = 1
# end

# enum CXIdxEntityKind
const CXIdxEntity_Unexposed = 0
const CXIdxEntity_Typedef = 1
const CXIdxEntity_Function = 2
const CXIdxEntity_Variable = 3
const CXIdxEntity_Field = 4
const CXIdxEntity_EnumConstant = 5
const CXIdxEntity_ObjCClass = 6
const CXIdxEntity_ObjCProtocol = 7
const CXIdxEntity_ObjCCategory = 8
const CXIdxEntity_ObjCInstanceMethod = 9
const CXIdxEntity_ObjCClassMethod = 10
const CXIdxEntity_ObjCProperty = 11
const CXIdxEntity_ObjCIvar = 12
const CXIdxEntity_Enum = 13
const CXIdxEntity_Struct = 14
const CXIdxEntity_Union = 15
const CXIdxEntity_CXXClass = 16
const CXIdxEntity_CXXNamespace = 17
const CXIdxEntity_CXXNamespaceAlias = 18
const CXIdxEntity_CXXStaticVariable = 19
const CXIdxEntity_CXXStaticMethod = 20
const CXIdxEntity_CXXInstanceMethod = 21
const CXIdxEntity_CXXConstructor = 22
const CXIdxEntity_CXXDestructor = 23
const CXIdxEntity_CXXConversionFunction = 24
const CXIdxEntity_CXXTypeAlias = 25
# end

# enum CXIdxEntityLanguage
const CXIdxEntityLang_None = 0
const CXIdxEntityLang_C = 1
const CXIdxEntityLang_ObjC = 2
const CXIdxEntityLang_CXX = 3
# end

# enum CXIdxEntityCXXTemplateKind
const CXIdxEntity_NonTemplate = 0
const CXIdxEntity_Template = 1
const CXIdxEntity_TemplatePartialSpecialization = 2
const CXIdxEntity_TemplateSpecialization = 3
# end

# enum CXIdxAttrKind
const CXIdxAttr_Unexposed = 0
const CXIdxAttr_IBAction = 1
const CXIdxAttr_IBOutlet = 2
const CXIdxAttr_IBOutletCollection = 3
# end

# enum CXIdxObjCContainerKind
const CXIdxObjCContainer_ForwardRef = 0
const CXIdxObjCContainer_Interface = 1
const CXIdxObjCContainer_Implementation = 2
# end

# enum CXIdxEntityRefKind
const CXIdxEntityRef_Direct = 1
const CXIdxEntityRef_Implicit = 2
# end

# enum CXIndexOptFlags
const CXIndexOpt_None = 0
const CXIndexOpt_SuppressRedundantRefs = 1
const CXIndexOpt_IndexFunctionLocalSymbols = 2
const CXIndexOpt_IndexImplicitTemplateInstantiations = 4
const CXIndexOpt_SuppressWarnings = 8
# end

