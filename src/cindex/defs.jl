export Availability
export GlobalOptFlags
export DiagnosticSeverity
export LoadDiag_Error
export DiagnosticDisplay
export TranslationUnit_Flags
export SaveTranslationUnit_Flags
export SaveError
export Reparse_Flags
export TUResourceUsage
export CursorKind
export LinkageKind
export LanguageKind
export TypeKind
export CallingConv
export CXXAccessSpecifiers
export CursorVisitorResult
export NameRefFlags
export TokenKind
export CompletionChunkKind
export CodeComplete_Flags
export VisitorResult
export EntityKind
export EntityLanguage
export EntityCXXTemplateKind
export AttrKind
export ObjCContainerKind
export EntityRefKind
export IndexOptFlags

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
baremodule CursorKind
    const UnexposedDecl = 1
    const StructDecl = 2
    const UnionDecl = 3
    const ClassDecl = 4
    const EnumDecl = 5
    const FieldDecl = 6
    const EnumConstantDecl = 7
    const FunctionDecl = 8
    const VarDecl = 9
    const ParmDecl = 10
    const ObjCInterfaceDecl = 11
    const ObjCCategoryDecl = 12
    const ObjCProtocolDecl = 13
    const ObjCPropertyDecl = 14
    const ObjCIvarDecl = 15
    const ObjCInstanceMethodDecl = 16
    const ObjCClassMethodDecl = 17
    const ObjCImplementationDecl = 18
    const ObjCCategoryImplDecl = 19
    const TypedefDecl = 20
    const CXXMethod = 21
    const Namespace = 22
    const LinkageSpec = 23
    const Constructor = 24
    const Destructor = 25
    const ConversionFunction = 26
    const TemplateTypeParameter = 27
    const NonTypeTemplateParameter = 28
    const TemplateTemplateParameter = 29
    const FunctionTemplate = 30
    const ClassTemplate = 31
    const ClassTemplatePartialSpecialization = 32
    const NamespaceAlias = 33
    const UsingDirective = 34
    const UsingDeclaration = 35
    const TypeAliasDecl = 36
    const ObjCSynthesizeDecl = 37
    const ObjCDynamicDecl = 38
    const CXXAccessSpecifier = 39
    const FirstDecl = 1
    # const LastDecl = 39
    const FirstRef = 40
    # const ObjCSuperClassRef = 40 dup
    const ObjCProtocolRef = 41
    const ObjCClassRef = 42
    const TypeRef = 43
    const CXXBaseSpecifier = 44
    const TemplateRef = 45
    const NamespaceRef = 46
    const MemberRef = 47
    const LabelRef = 48
    const OverloadedDeclRef = 49
    const VariableRef = 50
    # const LastRef = 50 dup
    const FirstInvalid = 70
    # const InvalidFile = 70 dup
    const NoDeclFound = 71
    const NotImplemented = 72
    const InvalidCode = 73
    # const LastInvalid = 73 dup
    const FirstExpr = 100
    const UnexposedExpr = 100
    const DeclRefExpr = 101
    const MemberRefExpr = 102
    const CallExpr = 103
    const ObjCMessageExpr = 104
    const BlockExpr = 105
    const IntegerLiteral = 106
    const FloatingLiteral = 107
    const ImaginaryLiteral = 108
    const StringLiteral = 109
    const CharacterLiteral = 110
    const ParenExpr = 111
    const UnaryOperator = 112
    const ArraySubscriptExpr = 113
    const BinaryOperator = 114
    const CompoundAssignOperator = 115
    const ConditionalOperator = 116
    const CStyleCastExpr = 117
    const CompoundLiteralExpr = 118
    const InitListExpr = 119
    const AddrLabelExpr = 120
    const StmtExpr = 121
    const GenericSelectionExpr = 122
    const GNUNullExpr = 123
    const CXXStaticCastExpr = 124
    const CXXDynamicCastExpr = 125
    const CXXReinterpretCastExpr = 126
    const CXXConstCastExpr = 127
    const CXXFunctionalCastExpr = 128
    const CXXTypeidExpr = 129
    const CXXBoolLiteralExpr = 130
    const CXXNullPtrLiteralExpr = 131
    const CXXThisExpr = 132
    const CXXThrowExpr = 133
    const CXXNewExpr = 134
    const CXXDeleteExpr = 135
    const UnaryExpr = 136
    const ObjCStringLiteral = 137
    const ObjCEncodeExpr = 138
    const ObjCSelectorExpr = 139
    const ObjCProtocolExpr = 140
    const ObjCBridgedCastExpr = 141
    const PackExpansionExpr = 142
    const SizeOfPackExpr = 143
    const LambdaExpr = 144
    const ObjCBoolLiteralExpr = 145
    const ObjCSelfExpr = 146
    const ObjCAvailabilityCheckExpr     = 148
    # const LastExpr = ObjCAvailabilityCheckExpr #dupe
    const FirstStmt = 200
    const UnexposedStmt = 200
    const LabelStmt = 201
    const CompoundStmt = 202
    const CaseStmt = 203
    const DefaultStmt = 204
    const IfStmt = 205
    const SwitchStmt = 206
    const WhileStmt = 207
    const DoStmt = 208
    const ForStmt = 209
    const GotoStmt = 210
    const IndirectGotoStmt = 211
    const ContinueStmt = 212
    const BreakStmt = 213
    const ReturnStmt = 214
    const GCCAsmStmt = 215
    # const AsmStmt = GCCAsmStmt # dupe
    const ObjCAtTryStmt = 216
    const ObjCAtCatchStmt = 217
    const ObjCAtFinallyStmt = 218
    const ObjCAtThrowStmt = 219
    const ObjCAtSynchronizedStmt = 220
    const ObjCAutoreleasePoolStmt = 221
    const ObjCForCollectionStmt = 222
    const CXXCatchStmt = 223
    const CXXTryStmt = 224
    const CXXForRangeStmt = 225
    const SEHTryStmt = 226
    const SEHExceptStmt = 227
    const SEHFinallyStmt = 228
    const MSAsmStmt = 229
    const NullStmt = 230
    const DeclStmt = 231
    const OMPTargetTeamsDistributeSimdDirective = 279
    const LastStmt = OMPTargetTeamsDistributeSimdDirective #dupe
    const TranslationUnit = 300
    const FirstAttr = 400
    # const UnexposedAttr = 400 #dupe
    const IBActionAttr = 401
    const IBOutletAttr = 402
    const IBOutletCollectionAttr = 403
    const CXXFinalAttr = 404
    const CXXOverrideAttr = 405
    const AnnotateAttr = 406
    const AsmLabelAttr = 407
    const PackedAttr = 408
    const PureAttr = 409
    const ConstAttr = 410
    const NoDuplicateAttr = 411
    const CUDAConstantAttr              = 412
    const CUDADeviceAttr                = 413
    const CUDAGlobalAttr                = 414
    const CUDAHostAttr                  = 415
    const CUDASharedAttr                = 416
    const VisibilityAttr                = 417
    const DLLExport                     = 418
    const DLLImport                     = 419
    const LastAttr = DLLImport #dupe
    const PreprocessingDirective = 500
    const MacroDefinition = 501
    const MacroExpansion = 502
    const MacroInstantiation = 502
    const InclusionDirective = 503
    const FirstPreprocessing = 500
    # const LastPreprocessing = InclusionDirective #dupe
    const ModuleImportDecl = 600
    const TypeAliasTemplateDecl         = 601
    const StaticAssert                  = 602
    const FriendDecl                    = 603
    const FirstExtraDecl = ModuleImportDecl
    const LastExtraDecl = FriendDecl
    const OverloadCandidate             = 700
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
baremodule TypeKind
    const Invalid = 0
    const Unexposed = 1
    const VoidType = 2
    const BoolType = 3
    const Char_U = 4
    const UChar = 5
    const Char16 = 6
    const Char32 = 7
    const UShort = 8
    const UInt = 9
    const ULong = 10
    const ULongLong = 11
    const UInt128 = 12
    const Char_S = 13
    const SChar = 14
    const WChar = 15
    const Short = 16
    const IntType = 17
    const Long = 18
    const LongLong = 19
    const Int128 = 20
    const Float = 21
    const Double = 22
    const LongDouble = 23
    const NullPtr = 24
    const Overload = 25
    const Dependent = 26
    const ObjCId = 27
    const ObjCClass = 28
    const ObjCSel = 29
    const FirstBuiltin = 2
    const LastBuiltin = 29
    const Complex = 100
    const Pointer = 101
    const BlockPointer = 102
    const LValueReference = 103
    const RValueReference = 104
    const Record = 105
    const Enum = 106
    const Typedef = 107
    const ObjCInterface = 108
    const ObjCObjectPointer = 109
    const FunctionNoProto = 110
    const FunctionProto = 111
    const ConstantArray = 112
    const CLVector = 113
    const IncompleteArray = 114
    const VariableArray = 115
    const DependentSizedArray = 116
    const MemberPointer = 117
    const Auto = 118

    #=
    * \brief Represents a type that was referred to using an elaborated type keyword.
    *
    * E.g., struct S, or via a qualified name, e.g., N::M::type, or both.
    =#
    const CXType_Elaborated = 119
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
baremodule CXXAccessSpecifiers
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
