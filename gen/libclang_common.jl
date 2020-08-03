# Automatically generated using Clang.jl


const CXVirtualFileOverlayImpl = Cvoid
const CXVirtualFileOverlay = Ptr{CXVirtualFileOverlayImpl}
const CXModuleMapDescriptorImpl = Cvoid
const CXModuleMapDescriptor = Ptr{CXModuleMapDescriptorImpl}
const CXCompilationDatabase = Ptr{Cvoid}
const CXCompileCommands = Ptr{Cvoid}
const CXCompileCommand = Ptr{Cvoid}

@cenum CXCompilationDatabase_Error::UInt32 begin
    CXCompilationDatabase_NoError = 0
    CXCompilationDatabase_CanNotLoadDatabase = 1
end

@cenum CXErrorCode::UInt32 begin
    CXError_Success = 0
    CXError_Failure = 1
    CXError_Crashed = 2
    CXError_InvalidArguments = 3
    CXError_ASTReadError = 4
end


struct CXString
    data::Ptr{Cvoid}
    private_flags::UInt32
end

struct CXStringSet
    Strings::Ptr{CXString}
    Count::UInt32
end

const CXTranslationUnitImpl = Cvoid
const CXTranslationUnit = Ptr{CXTranslationUnitImpl}

struct CXComment
    ASTNode::Ptr{Cvoid}
    TranslationUnit::CXTranslationUnit
end

@cenum CXCommentKind::UInt32 begin
    CXComment_Null = 0
    CXComment_Text = 1
    CXComment_InlineCommand = 2
    CXComment_HTMLStartTag = 3
    CXComment_HTMLEndTag = 4
    CXComment_Paragraph = 5
    CXComment_BlockCommand = 6
    CXComment_ParamCommand = 7
    CXComment_TParamCommand = 8
    CXComment_VerbatimBlockCommand = 9
    CXComment_VerbatimBlockLine = 10
    CXComment_VerbatimLine = 11
    CXComment_FullComment = 12
end

@cenum CXCommentInlineCommandRenderKind::UInt32 begin
    CXCommentInlineCommandRenderKind_Normal = 0
    CXCommentInlineCommandRenderKind_Bold = 1
    CXCommentInlineCommandRenderKind_Monospaced = 2
    CXCommentInlineCommandRenderKind_Emphasized = 3
end

@cenum CXCommentParamPassDirection::UInt32 begin
    CXCommentParamPassDirection_In = 0
    CXCommentParamPassDirection_Out = 1
    CXCommentParamPassDirection_InOut = 2
end


const CINDEX_VERSION_MAJOR = 0
const CINDEX_VERSION_MINOR = 59

# Skipping MacroDefinition: CINDEX_VERSION_ENCODE ( major , minor ) ( ( ( major ) * 10000 ) + ( ( minor ) * 1 ) )
# Skipping MacroDefinition: CINDEX_VERSION CINDEX_VERSION_ENCODE ( CINDEX_VERSION_MAJOR , CINDEX_VERSION_MINOR )
# Skipping MacroDefinition: CINDEX_VERSION_STRINGIZE_ ( major , minor ) # major "." # minor
# Skipping MacroDefinition: CINDEX_VERSION_STRINGIZE ( major , minor ) CINDEX_VERSION_STRINGIZE_ ( major , minor )
# Skipping MacroDefinition: CINDEX_VERSION_STRING CINDEX_VERSION_STRINGIZE ( CINDEX_VERSION_MAJOR , CINDEX_VERSION_MINOR )

const CXIndex = Ptr{Cvoid}
const CXTargetInfoImpl = Cvoid
const CXTargetInfo = Ptr{CXTargetInfoImpl}
const CXClientData = Ptr{Cvoid}

struct CXUnsavedFile
    Filename::Cstring
    Contents::Cstring
    Length::Culong
end

@cenum CXAvailabilityKind::UInt32 begin
    CXAvailability_Available = 0
    CXAvailability_Deprecated = 1
    CXAvailability_NotAvailable = 2
    CXAvailability_NotAccessible = 3
end


struct CXVersion
    Major::Cint
    Minor::Cint
    Subminor::Cint
end

@cenum CXCursor_ExceptionSpecificationKind::UInt32 begin
    CXCursor_ExceptionSpecificationKind_None = 0
    CXCursor_ExceptionSpecificationKind_DynamicNone = 1
    CXCursor_ExceptionSpecificationKind_Dynamic = 2
    CXCursor_ExceptionSpecificationKind_MSAny = 3
    CXCursor_ExceptionSpecificationKind_BasicNoexcept = 4
    CXCursor_ExceptionSpecificationKind_ComputedNoexcept = 5
    CXCursor_ExceptionSpecificationKind_Unevaluated = 6
    CXCursor_ExceptionSpecificationKind_Uninstantiated = 7
    CXCursor_ExceptionSpecificationKind_Unparsed = 8
    CXCursor_ExceptionSpecificationKind_NoThrow = 9
end

@cenum CXGlobalOptFlags::UInt32 begin
    CXGlobalOpt_None = 0
    CXGlobalOpt_ThreadBackgroundPriorityForIndexing = 1
    CXGlobalOpt_ThreadBackgroundPriorityForEditing = 2
    CXGlobalOpt_ThreadBackgroundPriorityForAll = 3
end


const CXFile = Ptr{Cvoid}

struct CXFileUniqueID
    data::NTuple{3, Culonglong}
end

struct CXSourceLocation
    ptr_data::NTuple{2, Ptr{Cvoid}}
    int_data::UInt32
end

struct CXSourceRange
    ptr_data::NTuple{2, Ptr{Cvoid}}
    begin_int_data::UInt32
    end_int_data::UInt32
end

struct CXSourceRangeList
    count::UInt32
    ranges::Ptr{CXSourceRange}
end

@cenum CXDiagnosticSeverity::UInt32 begin
    CXDiagnostic_Ignored = 0
    CXDiagnostic_Note = 1
    CXDiagnostic_Warning = 2
    CXDiagnostic_Error = 3
    CXDiagnostic_Fatal = 4
end


const CXDiagnostic = Ptr{Cvoid}
const CXDiagnosticSet = Ptr{Cvoid}

@cenum CXLoadDiag_Error::UInt32 begin
    CXLoadDiag_None = 0
    CXLoadDiag_Unknown = 1
    CXLoadDiag_CannotLoad = 2
    CXLoadDiag_InvalidFile = 3
end

@cenum CXDiagnosticDisplayOptions::UInt32 begin
    CXDiagnostic_DisplaySourceLocation = 1
    CXDiagnostic_DisplayColumn = 2
    CXDiagnostic_DisplaySourceRanges = 4
    CXDiagnostic_DisplayOption = 8
    CXDiagnostic_DisplayCategoryId = 16
    CXDiagnostic_DisplayCategoryName = 32
end

@cenum CXTranslationUnit_Flags::UInt32 begin
    CXTranslationUnit_None = 0
    CXTranslationUnit_DetailedPreprocessingRecord = 1
    CXTranslationUnit_Incomplete = 2
    CXTranslationUnit_PrecompiledPreamble = 4
    CXTranslationUnit_CacheCompletionResults = 8
    CXTranslationUnit_ForSerialization = 16
    CXTranslationUnit_CXXChainedPCH = 32
    CXTranslationUnit_SkipFunctionBodies = 64
    CXTranslationUnit_IncludeBriefCommentsInCodeCompletion = 128
    CXTranslationUnit_CreatePreambleOnFirstParse = 256
    CXTranslationUnit_KeepGoing = 512
    CXTranslationUnit_SingleFileParse = 1024
    CXTranslationUnit_LimitSkipFunctionBodiesToPreamble = 2048
    CXTranslationUnit_IncludeAttributedTypes = 4096
    CXTranslationUnit_VisitImplicitAttributes = 8192
    CXTranslationUnit_IgnoreNonErrorsFromIncludedFiles = 16384
end

@cenum CXSaveTranslationUnit_Flags::UInt32 begin
    CXSaveTranslationUnit_None = 0
end

@cenum CXSaveError::UInt32 begin
    CXSaveError_None = 0
    CXSaveError_Unknown = 1
    CXSaveError_TranslationErrors = 2
    CXSaveError_InvalidTU = 3
end

@cenum CXReparse_Flags::UInt32 begin
    CXReparse_None = 0
end

@cenum CXTUResourceUsageKind::UInt32 begin
    CXTUResourceUsage_AST = 1
    CXTUResourceUsage_Identifiers = 2
    CXTUResourceUsage_Selectors = 3
    CXTUResourceUsage_GlobalCompletionResults = 4
    CXTUResourceUsage_SourceManagerContentCache = 5
    CXTUResourceUsage_AST_SideTables = 6
    CXTUResourceUsage_SourceManager_Membuffer_Malloc = 7
    CXTUResourceUsage_SourceManager_Membuffer_MMap = 8
    CXTUResourceUsage_ExternalASTSource_Membuffer_Malloc = 9
    CXTUResourceUsage_ExternalASTSource_Membuffer_MMap = 10
    CXTUResourceUsage_Preprocessor = 11
    CXTUResourceUsage_PreprocessingRecord = 12
    CXTUResourceUsage_SourceManager_DataStructures = 13
    CXTUResourceUsage_Preprocessor_HeaderSearch = 14
    CXTUResourceUsage_MEMORY_IN_BYTES_BEGIN = 1
    CXTUResourceUsage_MEMORY_IN_BYTES_END = 14
    CXTUResourceUsage_First = 1
    CXTUResourceUsage_Last = 14
end


struct CXTUResourceUsageEntry
    kind::CXTUResourceUsageKind
    amount::Culong
end

struct CXTUResourceUsage
    data::Ptr{Cvoid}
    numEntries::UInt32
    entries::Ptr{CXTUResourceUsageEntry}
end

@cenum CXCursorKind::UInt32 begin
    CXCursor_UnexposedDecl = 1
    CXCursor_StructDecl = 2
    CXCursor_UnionDecl = 3
    CXCursor_ClassDecl = 4
    CXCursor_EnumDecl = 5
    CXCursor_FieldDecl = 6
    CXCursor_EnumConstantDecl = 7
    CXCursor_FunctionDecl = 8
    CXCursor_VarDecl = 9
    CXCursor_ParmDecl = 10
    CXCursor_ObjCInterfaceDecl = 11
    CXCursor_ObjCCategoryDecl = 12
    CXCursor_ObjCProtocolDecl = 13
    CXCursor_ObjCPropertyDecl = 14
    CXCursor_ObjCIvarDecl = 15
    CXCursor_ObjCInstanceMethodDecl = 16
    CXCursor_ObjCClassMethodDecl = 17
    CXCursor_ObjCImplementationDecl = 18
    CXCursor_ObjCCategoryImplDecl = 19
    CXCursor_TypedefDecl = 20
    CXCursor_CXXMethod = 21
    CXCursor_Namespace = 22
    CXCursor_LinkageSpec = 23
    CXCursor_Constructor = 24
    CXCursor_Destructor = 25
    CXCursor_ConversionFunction = 26
    CXCursor_TemplateTypeParameter = 27
    CXCursor_NonTypeTemplateParameter = 28
    CXCursor_TemplateTemplateParameter = 29
    CXCursor_FunctionTemplate = 30
    CXCursor_ClassTemplate = 31
    CXCursor_ClassTemplatePartialSpecialization = 32
    CXCursor_NamespaceAlias = 33
    CXCursor_UsingDirective = 34
    CXCursor_UsingDeclaration = 35
    CXCursor_TypeAliasDecl = 36
    CXCursor_ObjCSynthesizeDecl = 37
    CXCursor_ObjCDynamicDecl = 38
    CXCursor_CXXAccessSpecifier = 39
    CXCursor_FirstDecl = 1
    CXCursor_LastDecl = 39
    CXCursor_FirstRef = 40
    CXCursor_ObjCSuperClassRef = 40
    CXCursor_ObjCProtocolRef = 41
    CXCursor_ObjCClassRef = 42
    CXCursor_TypeRef = 43
    CXCursor_CXXBaseSpecifier = 44
    CXCursor_TemplateRef = 45
    CXCursor_NamespaceRef = 46
    CXCursor_MemberRef = 47
    CXCursor_LabelRef = 48
    CXCursor_OverloadedDeclRef = 49
    CXCursor_VariableRef = 50
    CXCursor_LastRef = 50
    CXCursor_FirstInvalid = 70
    CXCursor_InvalidFile = 70
    CXCursor_NoDeclFound = 71
    CXCursor_NotImplemented = 72
    CXCursor_InvalidCode = 73
    CXCursor_LastInvalid = 73
    CXCursor_FirstExpr = 100
    CXCursor_UnexposedExpr = 100
    CXCursor_DeclRefExpr = 101
    CXCursor_MemberRefExpr = 102
    CXCursor_CallExpr = 103
    CXCursor_ObjCMessageExpr = 104
    CXCursor_BlockExpr = 105
    CXCursor_IntegerLiteral = 106
    CXCursor_FloatingLiteral = 107
    CXCursor_ImaginaryLiteral = 108
    CXCursor_StringLiteral = 109
    CXCursor_CharacterLiteral = 110
    CXCursor_ParenExpr = 111
    CXCursor_UnaryOperator = 112
    CXCursor_ArraySubscriptExpr = 113
    CXCursor_BinaryOperator = 114
    CXCursor_CompoundAssignOperator = 115
    CXCursor_ConditionalOperator = 116
    CXCursor_CStyleCastExpr = 117
    CXCursor_CompoundLiteralExpr = 118
    CXCursor_InitListExpr = 119
    CXCursor_AddrLabelExpr = 120
    CXCursor_StmtExpr = 121
    CXCursor_GenericSelectionExpr = 122
    CXCursor_GNUNullExpr = 123
    CXCursor_CXXStaticCastExpr = 124
    CXCursor_CXXDynamicCastExpr = 125
    CXCursor_CXXReinterpretCastExpr = 126
    CXCursor_CXXConstCastExpr = 127
    CXCursor_CXXFunctionalCastExpr = 128
    CXCursor_CXXTypeidExpr = 129
    CXCursor_CXXBoolLiteralExpr = 130
    CXCursor_CXXNullPtrLiteralExpr = 131
    CXCursor_CXXThisExpr = 132
    CXCursor_CXXThrowExpr = 133
    CXCursor_CXXNewExpr = 134
    CXCursor_CXXDeleteExpr = 135
    CXCursor_UnaryExpr = 136
    CXCursor_ObjCStringLiteral = 137
    CXCursor_ObjCEncodeExpr = 138
    CXCursor_ObjCSelectorExpr = 139
    CXCursor_ObjCProtocolExpr = 140
    CXCursor_ObjCBridgedCastExpr = 141
    CXCursor_PackExpansionExpr = 142
    CXCursor_SizeOfPackExpr = 143
    CXCursor_LambdaExpr = 144
    CXCursor_ObjCBoolLiteralExpr = 145
    CXCursor_ObjCSelfExpr = 146
    CXCursor_OMPArraySectionExpr = 147
    CXCursor_ObjCAvailabilityCheckExpr = 148
    CXCursor_FixedPointLiteral = 149
    CXCursor_LastExpr = 149
    CXCursor_FirstStmt = 200
    CXCursor_UnexposedStmt = 200
    CXCursor_LabelStmt = 201
    CXCursor_CompoundStmt = 202
    CXCursor_CaseStmt = 203
    CXCursor_DefaultStmt = 204
    CXCursor_IfStmt = 205
    CXCursor_SwitchStmt = 206
    CXCursor_WhileStmt = 207
    CXCursor_DoStmt = 208
    CXCursor_ForStmt = 209
    CXCursor_GotoStmt = 210
    CXCursor_IndirectGotoStmt = 211
    CXCursor_ContinueStmt = 212
    CXCursor_BreakStmt = 213
    CXCursor_ReturnStmt = 214
    CXCursor_GCCAsmStmt = 215
    CXCursor_AsmStmt = 215
    CXCursor_ObjCAtTryStmt = 216
    CXCursor_ObjCAtCatchStmt = 217
    CXCursor_ObjCAtFinallyStmt = 218
    CXCursor_ObjCAtThrowStmt = 219
    CXCursor_ObjCAtSynchronizedStmt = 220
    CXCursor_ObjCAutoreleasePoolStmt = 221
    CXCursor_ObjCForCollectionStmt = 222
    CXCursor_CXXCatchStmt = 223
    CXCursor_CXXTryStmt = 224
    CXCursor_CXXForRangeStmt = 225
    CXCursor_SEHTryStmt = 226
    CXCursor_SEHExceptStmt = 227
    CXCursor_SEHFinallyStmt = 228
    CXCursor_MSAsmStmt = 229
    CXCursor_NullStmt = 230
    CXCursor_DeclStmt = 231
    CXCursor_OMPParallelDirective = 232
    CXCursor_OMPSimdDirective = 233
    CXCursor_OMPForDirective = 234
    CXCursor_OMPSectionsDirective = 235
    CXCursor_OMPSectionDirective = 236
    CXCursor_OMPSingleDirective = 237
    CXCursor_OMPParallelForDirective = 238
    CXCursor_OMPParallelSectionsDirective = 239
    CXCursor_OMPTaskDirective = 240
    CXCursor_OMPMasterDirective = 241
    CXCursor_OMPCriticalDirective = 242
    CXCursor_OMPTaskyieldDirective = 243
    CXCursor_OMPBarrierDirective = 244
    CXCursor_OMPTaskwaitDirective = 245
    CXCursor_OMPFlushDirective = 246
    CXCursor_SEHLeaveStmt = 247
    CXCursor_OMPOrderedDirective = 248
    CXCursor_OMPAtomicDirective = 249
    CXCursor_OMPForSimdDirective = 250
    CXCursor_OMPParallelForSimdDirective = 251
    CXCursor_OMPTargetDirective = 252
    CXCursor_OMPTeamsDirective = 253
    CXCursor_OMPTaskgroupDirective = 254
    CXCursor_OMPCancellationPointDirective = 255
    CXCursor_OMPCancelDirective = 256
    CXCursor_OMPTargetDataDirective = 257
    CXCursor_OMPTaskLoopDirective = 258
    CXCursor_OMPTaskLoopSimdDirective = 259
    CXCursor_OMPDistributeDirective = 260
    CXCursor_OMPTargetEnterDataDirective = 261
    CXCursor_OMPTargetExitDataDirective = 262
    CXCursor_OMPTargetParallelDirective = 263
    CXCursor_OMPTargetParallelForDirective = 264
    CXCursor_OMPTargetUpdateDirective = 265
    CXCursor_OMPDistributeParallelForDirective = 266
    CXCursor_OMPDistributeParallelForSimdDirective = 267
    CXCursor_OMPDistributeSimdDirective = 268
    CXCursor_OMPTargetParallelForSimdDirective = 269
    CXCursor_OMPTargetSimdDirective = 270
    CXCursor_OMPTeamsDistributeDirective = 271
    CXCursor_OMPTeamsDistributeSimdDirective = 272
    CXCursor_OMPTeamsDistributeParallelForSimdDirective = 273
    CXCursor_OMPTeamsDistributeParallelForDirective = 274
    CXCursor_OMPTargetTeamsDirective = 275
    CXCursor_OMPTargetTeamsDistributeDirective = 276
    CXCursor_OMPTargetTeamsDistributeParallelForDirective = 277
    CXCursor_OMPTargetTeamsDistributeParallelForSimdDirective = 278
    CXCursor_OMPTargetTeamsDistributeSimdDirective = 279
    CXCursor_BuiltinBitCastExpr = 280
    CXCursor_LastStmt = 280
    CXCursor_TranslationUnit = 300
    CXCursor_FirstAttr = 400
    CXCursor_UnexposedAttr = 400
    CXCursor_IBActionAttr = 401
    CXCursor_IBOutletAttr = 402
    CXCursor_IBOutletCollectionAttr = 403
    CXCursor_CXXFinalAttr = 404
    CXCursor_CXXOverrideAttr = 405
    CXCursor_AnnotateAttr = 406
    CXCursor_AsmLabelAttr = 407
    CXCursor_PackedAttr = 408
    CXCursor_PureAttr = 409
    CXCursor_ConstAttr = 410
    CXCursor_NoDuplicateAttr = 411
    CXCursor_CUDAConstantAttr = 412
    CXCursor_CUDADeviceAttr = 413
    CXCursor_CUDAGlobalAttr = 414
    CXCursor_CUDAHostAttr = 415
    CXCursor_CUDASharedAttr = 416
    CXCursor_VisibilityAttr = 417
    CXCursor_DLLExport = 418
    CXCursor_DLLImport = 419
    CXCursor_NSReturnsRetained = 420
    CXCursor_NSReturnsNotRetained = 421
    CXCursor_NSReturnsAutoreleased = 422
    CXCursor_NSConsumesSelf = 423
    CXCursor_NSConsumed = 424
    CXCursor_ObjCException = 425
    CXCursor_ObjCNSObject = 426
    CXCursor_ObjCIndependentClass = 427
    CXCursor_ObjCPreciseLifetime = 428
    CXCursor_ObjCReturnsInnerPointer = 429
    CXCursor_ObjCRequiresSuper = 430
    CXCursor_ObjCRootClass = 431
    CXCursor_ObjCSubclassingRestricted = 432
    CXCursor_ObjCExplicitProtocolImpl = 433
    CXCursor_ObjCDesignatedInitializer = 434
    CXCursor_ObjCRuntimeVisible = 435
    CXCursor_ObjCBoxable = 436
    CXCursor_FlagEnum = 437
    CXCursor_ConvergentAttr = 438
    CXCursor_WarnUnusedAttr = 439
    CXCursor_WarnUnusedResultAttr = 440
    CXCursor_AlignedAttr = 441
    CXCursor_LastAttr = 441
    CXCursor_PreprocessingDirective = 500
    CXCursor_MacroDefinition = 501
    CXCursor_MacroExpansion = 502
    CXCursor_MacroInstantiation = 502
    CXCursor_InclusionDirective = 503
    CXCursor_FirstPreprocessing = 500
    CXCursor_LastPreprocessing = 503
    CXCursor_ModuleImportDecl = 600
    CXCursor_TypeAliasTemplateDecl = 601
    CXCursor_StaticAssert = 602
    CXCursor_FriendDecl = 603
    CXCursor_FirstExtraDecl = 600
    CXCursor_LastExtraDecl = 603
    CXCursor_OverloadCandidate = 700
end


struct CXCursor
    kind::CXCursorKind
    xdata::Cint
    data::NTuple{3, Ptr{Cvoid}}
end

@cenum CXLinkageKind::UInt32 begin
    CXLinkage_Invalid = 0
    CXLinkage_NoLinkage = 1
    CXLinkage_Internal = 2
    CXLinkage_UniqueExternal = 3
    CXLinkage_External = 4
end

@cenum CXVisibilityKind::UInt32 begin
    CXVisibility_Invalid = 0
    CXVisibility_Hidden = 1
    CXVisibility_Protected = 2
    CXVisibility_Default = 3
end


struct CXPlatformAvailability
    Platform::CXString
    Introduced::CXVersion
    Deprecated::CXVersion
    Obsoleted::CXVersion
    Unavailable::Cint
    Message::CXString
end

@cenum CXLanguageKind::UInt32 begin
    CXLanguage_Invalid = 0
    CXLanguage_C = 1
    CXLanguage_ObjC = 2
    CXLanguage_CPlusPlus = 3
end

@cenum CXTLSKind::UInt32 begin
    CXTLS_None = 0
    CXTLS_Dynamic = 1
    CXTLS_Static = 2
end


const CXCursorSetImpl = Cvoid
const CXCursorSet = Ptr{CXCursorSetImpl}

@cenum CXTypeKind::UInt32 begin
    CXType_Invalid = 0
    CXType_Unexposed = 1
    CXType_Void = 2
    CXType_Bool = 3
    CXType_Char_U = 4
    CXType_UChar = 5
    CXType_Char16 = 6
    CXType_Char32 = 7
    CXType_UShort = 8
    CXType_UInt = 9
    CXType_ULong = 10
    CXType_ULongLong = 11
    CXType_UInt128 = 12
    CXType_Char_S = 13
    CXType_SChar = 14
    CXType_WChar = 15
    CXType_Short = 16
    CXType_Int = 17
    CXType_Long = 18
    CXType_LongLong = 19
    CXType_Int128 = 20
    CXType_Float = 21
    CXType_Double = 22
    CXType_LongDouble = 23
    CXType_NullPtr = 24
    CXType_Overload = 25
    CXType_Dependent = 26
    CXType_ObjCId = 27
    CXType_ObjCClass = 28
    CXType_ObjCSel = 29
    CXType_Float128 = 30
    CXType_Half = 31
    CXType_Float16 = 32
    CXType_ShortAccum = 33
    CXType_Accum = 34
    CXType_LongAccum = 35
    CXType_UShortAccum = 36
    CXType_UAccum = 37
    CXType_ULongAccum = 38
    CXType_FirstBuiltin = 2
    CXType_LastBuiltin = 38
    CXType_Complex = 100
    CXType_Pointer = 101
    CXType_BlockPointer = 102
    CXType_LValueReference = 103
    CXType_RValueReference = 104
    CXType_Record = 105
    CXType_Enum = 106
    CXType_Typedef = 107
    CXType_ObjCInterface = 108
    CXType_ObjCObjectPointer = 109
    CXType_FunctionNoProto = 110
    CXType_FunctionProto = 111
    CXType_ConstantArray = 112
    CXType_Vector = 113
    CXType_IncompleteArray = 114
    CXType_VariableArray = 115
    CXType_DependentSizedArray = 116
    CXType_MemberPointer = 117
    CXType_Auto = 118
    CXType_Elaborated = 119
    CXType_Pipe = 120
    CXType_OCLImage1dRO = 121
    CXType_OCLImage1dArrayRO = 122
    CXType_OCLImage1dBufferRO = 123
    CXType_OCLImage2dRO = 124
    CXType_OCLImage2dArrayRO = 125
    CXType_OCLImage2dDepthRO = 126
    CXType_OCLImage2dArrayDepthRO = 127
    CXType_OCLImage2dMSAARO = 128
    CXType_OCLImage2dArrayMSAARO = 129
    CXType_OCLImage2dMSAADepthRO = 130
    CXType_OCLImage2dArrayMSAADepthRO = 131
    CXType_OCLImage3dRO = 132
    CXType_OCLImage1dWO = 133
    CXType_OCLImage1dArrayWO = 134
    CXType_OCLImage1dBufferWO = 135
    CXType_OCLImage2dWO = 136
    CXType_OCLImage2dArrayWO = 137
    CXType_OCLImage2dDepthWO = 138
    CXType_OCLImage2dArrayDepthWO = 139
    CXType_OCLImage2dMSAAWO = 140
    CXType_OCLImage2dArrayMSAAWO = 141
    CXType_OCLImage2dMSAADepthWO = 142
    CXType_OCLImage2dArrayMSAADepthWO = 143
    CXType_OCLImage3dWO = 144
    CXType_OCLImage1dRW = 145
    CXType_OCLImage1dArrayRW = 146
    CXType_OCLImage1dBufferRW = 147
    CXType_OCLImage2dRW = 148
    CXType_OCLImage2dArrayRW = 149
    CXType_OCLImage2dDepthRW = 150
    CXType_OCLImage2dArrayDepthRW = 151
    CXType_OCLImage2dMSAARW = 152
    CXType_OCLImage2dArrayMSAARW = 153
    CXType_OCLImage2dMSAADepthRW = 154
    CXType_OCLImage2dArrayMSAADepthRW = 155
    CXType_OCLImage3dRW = 156
    CXType_OCLSampler = 157
    CXType_OCLEvent = 158
    CXType_OCLQueue = 159
    CXType_OCLReserveID = 160
    CXType_ObjCObject = 161
    CXType_ObjCTypeParam = 162
    CXType_Attributed = 163
    CXType_OCLIntelSubgroupAVCMcePayload = 164
    CXType_OCLIntelSubgroupAVCImePayload = 165
    CXType_OCLIntelSubgroupAVCRefPayload = 166
    CXType_OCLIntelSubgroupAVCSicPayload = 167
    CXType_OCLIntelSubgroupAVCMceResult = 168
    CXType_OCLIntelSubgroupAVCImeResult = 169
    CXType_OCLIntelSubgroupAVCRefResult = 170
    CXType_OCLIntelSubgroupAVCSicResult = 171
    CXType_OCLIntelSubgroupAVCImeResultSingleRefStreamout = 172
    CXType_OCLIntelSubgroupAVCImeResultDualRefStreamout = 173
    CXType_OCLIntelSubgroupAVCImeSingleRefStreamin = 174
    CXType_OCLIntelSubgroupAVCImeDualRefStreamin = 175
    CXType_ExtVector = 176
end

@cenum CXCallingConv::UInt32 begin
    CXCallingConv_Default = 0
    CXCallingConv_C = 1
    CXCallingConv_X86StdCall = 2
    CXCallingConv_X86FastCall = 3
    CXCallingConv_X86ThisCall = 4
    CXCallingConv_X86Pascal = 5
    CXCallingConv_AAPCS = 6
    CXCallingConv_AAPCS_VFP = 7
    CXCallingConv_X86RegCall = 8
    CXCallingConv_IntelOclBicc = 9
    CXCallingConv_Win64 = 10
    CXCallingConv_X86_64Win64 = 10
    CXCallingConv_X86_64SysV = 11
    CXCallingConv_X86VectorCall = 12
    CXCallingConv_Swift = 13
    CXCallingConv_PreserveMost = 14
    CXCallingConv_PreserveAll = 15
    CXCallingConv_AArch64VectorCall = 16
    CXCallingConv_Invalid = 100
    CXCallingConv_Unexposed = 200
end


struct CXType
    kind::CXTypeKind
    data::NTuple{2, Ptr{Cvoid}}
end

@cenum CXTemplateArgumentKind::UInt32 begin
    CXTemplateArgumentKind_Null = 0
    CXTemplateArgumentKind_Type = 1
    CXTemplateArgumentKind_Declaration = 2
    CXTemplateArgumentKind_NullPtr = 3
    CXTemplateArgumentKind_Integral = 4
    CXTemplateArgumentKind_Template = 5
    CXTemplateArgumentKind_TemplateExpansion = 6
    CXTemplateArgumentKind_Expression = 7
    CXTemplateArgumentKind_Pack = 8
    CXTemplateArgumentKind_Invalid = 9
end

@cenum CXTypeNullabilityKind::UInt32 begin
    CXTypeNullability_NonNull = 0
    CXTypeNullability_Nullable = 1
    CXTypeNullability_Unspecified = 2
    CXTypeNullability_Invalid = 3
end

@cenum CXTypeLayoutError::Int32 begin
    CXTypeLayoutError_Invalid = -1
    CXTypeLayoutError_Incomplete = -2
    CXTypeLayoutError_Dependent = -3
    CXTypeLayoutError_NotConstantSize = -4
    CXTypeLayoutError_InvalidFieldName = -5
    CXTypeLayoutError_Undeduced = -6
end

@cenum CXRefQualifierKind::UInt32 begin
    CXRefQualifier_None = 0
    CXRefQualifier_LValue = 1
    CXRefQualifier_RValue = 2
end

@cenum CX_CXXAccessSpecifier::UInt32 begin
    CX_CXXInvalidAccessSpecifier = 0
    CX_CXXPublic = 1
    CX_CXXProtected = 2
    CX_CXXPrivate = 3
end

@cenum CX_StorageClass::UInt32 begin
    CX_SC_Invalid = 0
    CX_SC_None = 1
    CX_SC_Extern = 2
    CX_SC_Static = 3
    CX_SC_PrivateExtern = 4
    CX_SC_OpenCLWorkGroupLocal = 5
    CX_SC_Auto = 6
    CX_SC_Register = 7
end

@cenum CXChildVisitResult::UInt32 begin
    CXChildVisit_Break = 0
    CXChildVisit_Continue = 1
    CXChildVisit_Recurse = 2
end


const CXCursorVisitor = Ptr{Cvoid}
const CXCursorVisitorBlock = Cvoid
const CXPrintingPolicy = Ptr{Cvoid}

@cenum CXPrintingPolicyProperty::UInt32 begin
    CXPrintingPolicy_Indentation = 0
    CXPrintingPolicy_SuppressSpecifiers = 1
    CXPrintingPolicy_SuppressTagKeyword = 2
    CXPrintingPolicy_IncludeTagDefinition = 3
    CXPrintingPolicy_SuppressScope = 4
    CXPrintingPolicy_SuppressUnwrittenScope = 5
    CXPrintingPolicy_SuppressInitializers = 6
    CXPrintingPolicy_ConstantArraySizeAsWritten = 7
    CXPrintingPolicy_AnonymousTagLocations = 8
    CXPrintingPolicy_SuppressStrongLifetime = 9
    CXPrintingPolicy_SuppressLifetimeQualifiers = 10
    CXPrintingPolicy_SuppressTemplateArgsInCXXConstructors = 11
    CXPrintingPolicy_Bool = 12
    CXPrintingPolicy_Restrict = 13
    CXPrintingPolicy_Alignof = 14
    CXPrintingPolicy_UnderscoreAlignof = 15
    CXPrintingPolicy_UseVoidForZeroParams = 16
    CXPrintingPolicy_TerseOutput = 17
    CXPrintingPolicy_PolishForDeclaration = 18
    CXPrintingPolicy_Half = 19
    CXPrintingPolicy_MSWChar = 20
    CXPrintingPolicy_IncludeNewlines = 21
    CXPrintingPolicy_MSVCFormatting = 22
    CXPrintingPolicy_ConstantsAsWritten = 23
    CXPrintingPolicy_SuppressImplicitBase = 24
    CXPrintingPolicy_FullyQualifiedName = 25
    CXPrintingPolicy_LastProperty = 25
end

@cenum CXObjCPropertyAttrKind::UInt32 begin
    CXObjCPropertyAttr_noattr = 0
    CXObjCPropertyAttr_readonly = 1
    CXObjCPropertyAttr_getter = 2
    CXObjCPropertyAttr_assign = 4
    CXObjCPropertyAttr_readwrite = 8
    CXObjCPropertyAttr_retain = 16
    CXObjCPropertyAttr_copy = 32
    CXObjCPropertyAttr_nonatomic = 64
    CXObjCPropertyAttr_setter = 128
    CXObjCPropertyAttr_atomic = 256
    CXObjCPropertyAttr_weak = 512
    CXObjCPropertyAttr_strong = 1024
    CXObjCPropertyAttr_unsafe_unretained = 2048
    CXObjCPropertyAttr_class = 4096
end

@cenum CXObjCDeclQualifierKind::UInt32 begin
    CXObjCDeclQualifier_None = 0
    CXObjCDeclQualifier_In = 1
    CXObjCDeclQualifier_Inout = 2
    CXObjCDeclQualifier_Out = 4
    CXObjCDeclQualifier_Bycopy = 8
    CXObjCDeclQualifier_Byref = 16
    CXObjCDeclQualifier_Oneway = 32
end


const CXModule = Ptr{Cvoid}

@cenum CXNameRefFlags::UInt32 begin
    CXNameRange_WantQualifier = 1
    CXNameRange_WantTemplateArgs = 2
    CXNameRange_WantSinglePiece = 4
end

@cenum CXTokenKind::UInt32 begin
    CXToken_Punctuation = 0
    CXToken_Keyword = 1
    CXToken_Identifier = 2
    CXToken_Literal = 3
    CXToken_Comment = 4
end


struct CXToken
    int_data::NTuple{4, UInt32}
    ptr_data::Ptr{Cvoid}
end

const CXCompletionString = Ptr{Cvoid}

struct CXCompletionResult
    CursorKind::CXCursorKind
    CompletionString::CXCompletionString
end

@cenum CXCompletionChunkKind::UInt32 begin
    CXCompletionChunk_Optional = 0
    CXCompletionChunk_TypedText = 1
    CXCompletionChunk_Text = 2
    CXCompletionChunk_Placeholder = 3
    CXCompletionChunk_Informative = 4
    CXCompletionChunk_CurrentParameter = 5
    CXCompletionChunk_LeftParen = 6
    CXCompletionChunk_RightParen = 7
    CXCompletionChunk_LeftBracket = 8
    CXCompletionChunk_RightBracket = 9
    CXCompletionChunk_LeftBrace = 10
    CXCompletionChunk_RightBrace = 11
    CXCompletionChunk_LeftAngle = 12
    CXCompletionChunk_RightAngle = 13
    CXCompletionChunk_Comma = 14
    CXCompletionChunk_ResultType = 15
    CXCompletionChunk_Colon = 16
    CXCompletionChunk_SemiColon = 17
    CXCompletionChunk_Equal = 18
    CXCompletionChunk_HorizontalSpace = 19
    CXCompletionChunk_VerticalSpace = 20
end


struct CXCodeCompleteResults
    Results::Ptr{CXCompletionResult}
    NumResults::UInt32
end

@cenum CXCodeComplete_Flags::UInt32 begin
    CXCodeComplete_IncludeMacros = 1
    CXCodeComplete_IncludeCodePatterns = 2
    CXCodeComplete_IncludeBriefComments = 4
    CXCodeComplete_SkipPreamble = 8
    CXCodeComplete_IncludeCompletionsWithFixIts = 16
end

@cenum CXCompletionContext::UInt32 begin
    CXCompletionContext_Unexposed = 0
    CXCompletionContext_AnyType = 1
    CXCompletionContext_AnyValue = 2
    CXCompletionContext_ObjCObjectValue = 4
    CXCompletionContext_ObjCSelectorValue = 8
    CXCompletionContext_CXXClassTypeValue = 16
    CXCompletionContext_DotMemberAccess = 32
    CXCompletionContext_ArrowMemberAccess = 64
    CXCompletionContext_ObjCPropertyAccess = 128
    CXCompletionContext_EnumTag = 256
    CXCompletionContext_UnionTag = 512
    CXCompletionContext_StructTag = 1024
    CXCompletionContext_ClassTag = 2048
    CXCompletionContext_Namespace = 4096
    CXCompletionContext_NestedNameSpecifier = 8192
    CXCompletionContext_ObjCInterface = 16384
    CXCompletionContext_ObjCProtocol = 32768
    CXCompletionContext_ObjCCategory = 65536
    CXCompletionContext_ObjCInstanceMessage = 131072
    CXCompletionContext_ObjCClassMessage = 262144
    CXCompletionContext_ObjCSelectorName = 524288
    CXCompletionContext_MacroName = 1048576
    CXCompletionContext_NaturalLanguage = 2097152
    CXCompletionContext_IncludedFile = 4194304
    CXCompletionContext_Unknown = 8388607
end


const CXInclusionVisitor = Ptr{Cvoid}

@cenum CXEvalResultKind::UInt32 begin
    CXEval_Int = 1
    CXEval_Float = 2
    CXEval_ObjCStrLiteral = 3
    CXEval_StrLiteral = 4
    CXEval_CFStr = 5
    CXEval_Other = 6
    CXEval_UnExposed = 0
end


const CXEvalResult = Ptr{Cvoid}
const CXRemapping = Ptr{Cvoid}

@cenum CXVisitorResult::UInt32 begin
    CXVisit_Break = 0
    CXVisit_Continue = 1
end


struct CXCursorAndRangeVisitor
    context::Ptr{Cvoid}
    visit::Ptr{Cvoid}
end

@cenum CXResult::UInt32 begin
    CXResult_Success = 0
    CXResult_Invalid = 1
    CXResult_VisitBreak = 2
end


const CXCursorAndRangeVisitorBlock = Cvoid
const CXIdxClientFile = Ptr{Cvoid}
const CXIdxClientEntity = Ptr{Cvoid}
const CXIdxClientContainer = Ptr{Cvoid}
const CXIdxClientASTFile = Ptr{Cvoid}

struct CXIdxLoc
    ptr_data::NTuple{2, Ptr{Cvoid}}
    int_data::UInt32
end

struct CXIdxIncludedFileInfo
    hashLoc::CXIdxLoc
    filename::Cstring
    file::CXFile
    isImport::Cint
    isAngled::Cint
    isModuleImport::Cint
end

struct CXIdxImportedASTFileInfo
    file::CXFile
    _module::CXModule
    loc::CXIdxLoc
    isImplicit::Cint
end

@cenum CXIdxEntityKind::UInt32 begin
    CXIdxEntity_Unexposed = 0
    CXIdxEntity_Typedef = 1
    CXIdxEntity_Function = 2
    CXIdxEntity_Variable = 3
    CXIdxEntity_Field = 4
    CXIdxEntity_EnumConstant = 5
    CXIdxEntity_ObjCClass = 6
    CXIdxEntity_ObjCProtocol = 7
    CXIdxEntity_ObjCCategory = 8
    CXIdxEntity_ObjCInstanceMethod = 9
    CXIdxEntity_ObjCClassMethod = 10
    CXIdxEntity_ObjCProperty = 11
    CXIdxEntity_ObjCIvar = 12
    CXIdxEntity_Enum = 13
    CXIdxEntity_Struct = 14
    CXIdxEntity_Union = 15
    CXIdxEntity_CXXClass = 16
    CXIdxEntity_CXXNamespace = 17
    CXIdxEntity_CXXNamespaceAlias = 18
    CXIdxEntity_CXXStaticVariable = 19
    CXIdxEntity_CXXStaticMethod = 20
    CXIdxEntity_CXXInstanceMethod = 21
    CXIdxEntity_CXXConstructor = 22
    CXIdxEntity_CXXDestructor = 23
    CXIdxEntity_CXXConversionFunction = 24
    CXIdxEntity_CXXTypeAlias = 25
    CXIdxEntity_CXXInterface = 26
end

@cenum CXIdxEntityLanguage::UInt32 begin
    CXIdxEntityLang_None = 0
    CXIdxEntityLang_C = 1
    CXIdxEntityLang_ObjC = 2
    CXIdxEntityLang_CXX = 3
    CXIdxEntityLang_Swift = 4
end

@cenum CXIdxEntityCXXTemplateKind::UInt32 begin
    CXIdxEntity_NonTemplate = 0
    CXIdxEntity_Template = 1
    CXIdxEntity_TemplatePartialSpecialization = 2
    CXIdxEntity_TemplateSpecialization = 3
end

@cenum CXIdxAttrKind::UInt32 begin
    CXIdxAttr_Unexposed = 0
    CXIdxAttr_IBAction = 1
    CXIdxAttr_IBOutlet = 2
    CXIdxAttr_IBOutletCollection = 3
end


struct CXIdxAttrInfo
    kind::CXIdxAttrKind
    cursor::CXCursor
    loc::CXIdxLoc
end

struct CXIdxEntityInfo
    kind::CXIdxEntityKind
    templateKind::CXIdxEntityCXXTemplateKind
    lang::CXIdxEntityLanguage
    name::Cstring
    USR::Cstring
    cursor::CXCursor
    attributes::Ptr{Ptr{CXIdxAttrInfo}}
    numAttributes::UInt32
end

struct CXIdxContainerInfo
    cursor::CXCursor
end

struct CXIdxIBOutletCollectionAttrInfo
    attrInfo::Ptr{CXIdxAttrInfo}
    objcClass::Ptr{CXIdxEntityInfo}
    classCursor::CXCursor
    classLoc::CXIdxLoc
end

@cenum CXIdxDeclInfoFlags::UInt32 begin
    CXIdxDeclFlag_Skipped = 1
end


struct CXIdxDeclInfo
    entityInfo::Ptr{CXIdxEntityInfo}
    cursor::CXCursor
    loc::CXIdxLoc
    semanticContainer::Ptr{CXIdxContainerInfo}
    lexicalContainer::Ptr{CXIdxContainerInfo}
    isRedeclaration::Cint
    isDefinition::Cint
    isContainer::Cint
    declAsContainer::Ptr{CXIdxContainerInfo}
    isImplicit::Cint
    attributes::Ptr{Ptr{CXIdxAttrInfo}}
    numAttributes::UInt32
    flags::UInt32
end

@cenum CXIdxObjCContainerKind::UInt32 begin
    CXIdxObjCContainer_ForwardRef = 0
    CXIdxObjCContainer_Interface = 1
    CXIdxObjCContainer_Implementation = 2
end


struct CXIdxObjCContainerDeclInfo
    declInfo::Ptr{CXIdxDeclInfo}
    kind::CXIdxObjCContainerKind
end

struct CXIdxBaseClassInfo
    base::Ptr{CXIdxEntityInfo}
    cursor::CXCursor
    loc::CXIdxLoc
end

struct CXIdxObjCProtocolRefInfo
    protocol::Ptr{CXIdxEntityInfo}
    cursor::CXCursor
    loc::CXIdxLoc
end

struct CXIdxObjCProtocolRefListInfo
    protocols::Ptr{Ptr{CXIdxObjCProtocolRefInfo}}
    numProtocols::UInt32
end

struct CXIdxObjCInterfaceDeclInfo
    containerInfo::Ptr{CXIdxObjCContainerDeclInfo}
    superInfo::Ptr{CXIdxBaseClassInfo}
    protocols::Ptr{CXIdxObjCProtocolRefListInfo}
end

struct CXIdxObjCCategoryDeclInfo
    containerInfo::Ptr{CXIdxObjCContainerDeclInfo}
    objcClass::Ptr{CXIdxEntityInfo}
    classCursor::CXCursor
    classLoc::CXIdxLoc
    protocols::Ptr{CXIdxObjCProtocolRefListInfo}
end

struct CXIdxObjCPropertyDeclInfo
    declInfo::Ptr{CXIdxDeclInfo}
    getter::Ptr{CXIdxEntityInfo}
    setter::Ptr{CXIdxEntityInfo}
end

struct CXIdxCXXClassDeclInfo
    declInfo::Ptr{CXIdxDeclInfo}
    bases::Ptr{Ptr{CXIdxBaseClassInfo}}
    numBases::UInt32
end

@cenum CXIdxEntityRefKind::UInt32 begin
    CXIdxEntityRef_Direct = 1
    CXIdxEntityRef_Implicit = 2
end

@cenum CXSymbolRole::UInt32 begin
    CXSymbolRole_None = 0
    CXSymbolRole_Declaration = 1
    CXSymbolRole_Definition = 2
    CXSymbolRole_Reference = 4
    CXSymbolRole_Read = 8
    CXSymbolRole_Write = 16
    CXSymbolRole_Call = 32
    CXSymbolRole_Dynamic = 64
    CXSymbolRole_AddressOf = 128
    CXSymbolRole_Implicit = 256
end


struct CXIdxEntityRefInfo
    kind::CXIdxEntityRefKind
    cursor::CXCursor
    loc::CXIdxLoc
    referencedEntity::Ptr{CXIdxEntityInfo}
    parentEntity::Ptr{CXIdxEntityInfo}
    container::Ptr{CXIdxContainerInfo}
    role::CXSymbolRole
end

struct IndexerCallbacks
    abortQuery::Ptr{Cvoid}
    diagnostic::Ptr{Cvoid}
    enteredMainFile::Ptr{Cvoid}
    ppIncludedFile::Ptr{Cvoid}
    importedASTFile::Ptr{Cvoid}
    startedTranslationUnit::Ptr{Cvoid}
    indexDeclaration::Ptr{Cvoid}
    indexEntityReference::Ptr{Cvoid}
end

const CXIndexAction = Ptr{Cvoid}

@cenum CXIndexOptFlags::UInt32 begin
    CXIndexOpt_None = 0
    CXIndexOpt_SuppressRedundantRefs = 1
    CXIndexOpt_IndexFunctionLocalSymbols = 2
    CXIndexOpt_IndexImplicitTemplateInstantiations = 4
    CXIndexOpt_SuppressWarnings = 8
    CXIndexOpt_SkipParsedBodiesInSession = 16
end


const CXFieldVisitor = Ptr{Cvoid}

# Skipping MacroDefinition: CINDEX_DEPRECATED __attribute__ ( ( deprecated ) )
