# Generated from Index.h
baremodule Availability
    const Available = 0
    const Deprecated = 1
    const NotAvailable = 2
    const NotAccessible = 3
end
# Typedef: GlobalOptFlags
baremodule GlobalOptFlags
    const None = 0
    const ThreadBackgroundPriorityForIndexing = 1
    const ThreadBackgroundPriorityForEditing = 2
    const ThreadBackgroundPriorityForAll = 3
end
# Typedef: CXDiagnostic
baremodule DiagnosticSeverity
    const Ignored = 0
    const Note = 1
    const Warning = 2
    const Error = 3
    const Fatal = 4
end
baremodule LoadDiag_Error
    const None = 0
    const Unknown = 1
    const CannotLoad = 2
    const InvalidFile = 3
end
baremodule DiagnosticDisplay
    const DisplaySourceLocation = 1
    const DisplayColumn = 2
    const DisplaySourceRanges = 4
    const DisplayOption = 8
    const DisplayCategoryId = 16
    const DisplayCategoryName = 32
end
baremodule TranslationUnit_Flags
    const None = 0
    const DetailedPreprocessingRecord = 1
    const Incomplete = 2
    const PrecompiledPreamble = 4
    const CacheCompletionResults = 8
    const CXXPrecompiledPreamble = 16
    const CXXChainedPCH = 32
    const SkipFunctionBodies = 64
end
baremodule SaveTranslationUnit_Flags
    const None = 0
end
baremodule SaveError
    const CXSaveError_None = 0
    const CXSaveError_Unknown = 1
    const CXSaveError_TranslationErrors = 2
    const CXSaveError_InvalidTU = 3
end
baremodule Reparse_Flags
    const None = 0
end
baremodule TUResourceUsage
    const AST = 1
    const Identifiers = 2
    const Selectors = 3
    const GlobalCompletionResults = 4
    const SourceManagerContentCache = 5
    const AST_SideTables = 6
    const SourceManager_Membuffer_Malloc = 7
    const SourceManagerMMap = 8
    const ExternalASTSource_Membuffer_Malloc = 9
    const ExternalASTSource_Membuffer_MMap = 10
    const Preprocessor = 11
    const PreprocessingRecord = 12
    const SourceManager_DataStructures = 13
    const Preprocessor_HeaderSearch = 14
    const MEMORY_IN_BYTES_BEGIN = 1
    const MEMORY_IN_BYTES_END = 14
    const First = 1
    const Last = 14
end
baremodule CurKind
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
end
baremodule LinkageKind
    const Invalid = 0
    const NoLinkage = 1
    const Internal = 2
    const UniqueExternal = 3
    const External = 4
end
baremodule LanguageKind
    const Invalid = 0
    const C = 1
    const ObjC = 2
    const CPlusPlus = 3
end
baremodule TypKind
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
end
baremodule CallingConv
    const Default = 0
    const C = 1
    const X86StdCall = 2
    const X86FastCall = 3
    const X86ThisCall = 4
    const X86Pascal = 5
    const AAPCS = 6
    const VFP = 7
    const Invalid = 100
    const Unexposed = 200
end
baremodule CXXAccessSpecifier
    const InvalidAccessSpecifier = 0
    const Public = 1
    const Protected = 2
    const Private = 3
end
baremodule CursorVisitorResult
    const Break = 0
    const Continue = 1
    const Recurse = 2
end
baremodule NameRefFlags
    const WantQualifier = 1
    const WantTemplateArgs = 2
    const WantSinglePiece = 4
end
baremodule TokenKind
    const Punctuation = 0
    const Keyword = 1
    const Identifier = 2
    const Literal = 3
    const Comment = 4
end
baremodule CompletionChunkKind
    const Optional = 0
    const TypedText = 1
    const Text = 2
    const Placeholder = 3
    const Informative = 4
    const CurrentParameter = 5
    const LeftParen = 6
    const RightParen = 7
    const LeftBracket = 8
    const RightBracket = 9
    const LeftBrace = 10
    const RightBrace = 11
    const LeftAngle = 12
    const RightAngle = 13
    const Comma = 14
    const ResultType = 15
    const Colon = 16
    const SemiColon = 17
    const Equal = 18
    const HorizontalSpace = 19
    const VerticalSpace = 20
end
baremodule CodeComplete_Flags
    const IncludeMacros = 1
    const IncludeCodePatterns = 2
    const Unexposed = 0
    const AnyType = 1
    const AnyValue = 2
    const ObjCObjectValue = 4
    const ObjCSelectorValue = 8
    const CXXClassTypeValue = 16
    const DotMemberAccess = 32
    const ArrowMemberAccess = 64
    const ObjCPropertyAccess = 128
    const EnumTag = 256
    const UnionTag = 512
    const StructTag = 1024
    const ClassTag = 2048
    const Namespace = 4096
    const NestedNameSpecifier = 8192
    const ObjCInterface = 16384
    const ObjCProtocol = 32768
    const ObjCCategory = 65536
    const ObjCInstanceMessage = 131072
    const ObjCClassMessage = 262144
    const ObjCSelectorName = 524288
    const MacroName = 1048576
    const NaturalLanguage = 2097152
    const Unknown = 4194303
end
baremodule VisitorResult
    const Break = 0
    const Continue = 1
end
baremodule EntityKind
    const Unexposed = 0
    const Typedef = 1
    const Function = 2
    const Variable = 3
    const Field = 4
    const EnumConstant = 5
    const ObjCClass = 6
    const ObjCProtocol = 7
    const ObjCCategory = 8
    const ObjCInstanceMethod = 9
    const ObjCClassMethod = 10
    const ObjCProperty = 11
    const ObjCIvar = 12
    const Enum = 13
    const Struct = 14
    const Union = 15
    const CXXClass = 16
    const CXXNamespace = 17
    const CXXNamespaceAlias = 18
    const CXXStaticVariable = 19
    const CXXStaticMethod = 20
    const CXXInstanceMethod = 21
    const CXXConstructor = 22
    const CXXDestructor = 23
    const CXXConversionFunction = 24
    const CXXTypeAlias = 25
end
baremodule EntityLanguage
    const None = 0
    const C = 1
    const ObjC = 2
    const CXX = 3
end
baremodule EntityCXXTemplateKind
    const NonTemplate = 0
    const Template = 1
    const TemplatePartialSpecialization = 2
    const TemplateSpecialization = 3
end
baremodule AttrKind
    const Unexposed = 0
    const IBAction = 1
    const IBOutlet = 2
    const IBOutletCollection = 3
end
baremodule ObjCContainerKind
    const ForwardRef = 0
    const Interface = 1
    const Implementation = 2
end
baremodule EntityRefKind
    const Direct = 1
    const Implicit = 2
end
baremodule IndexOptFlags
    const None = 0
    const SuppressRedundantRefs = 1
    const IndexFunctionLocalSymbols = 2
    const IndexImplicitTemplateInstantiations = 4
    const SuppressWarnings = 8
end
