# Automatically generated using Clang.jl wrap_c, version 0.0.0


const CXVirtualFileOverlay = Cvoid
const CXModuleMapDescriptor = Cvoid
const CXCompilationDatabase = Ptr{Cvoid}
const CXCompileCommands = Ptr{Cvoid}
const CXCompileCommand = Ptr{Cvoid}

# begin enum CXCompilationDatabase_Error
const CXCompilationDatabase_Error = UInt32
const CXCompilationDatabase_NoError = 0 |> UInt32
const CXCompilationDatabase_CanNotLoadDatabase = 1 |> UInt32
# end enum CXCompilationDatabase_Error

# begin enum CXErrorCode
const CXErrorCode = UInt32
const CXError_Success = 0 |> UInt32
const CXError_Failure = 1 |> UInt32
const CXError_Crashed = 2 |> UInt32
const CXError_InvalidArguments = 3 |> UInt32
const CXError_ASTReadError = 4 |> UInt32
# end enum CXErrorCode

struct CXString
    data::Ptr{Cvoid}
    private_flags::UInt32
end

struct CXStringSet
    Strings::Ptr{CXString}
    Count::UInt32
end

const CXTranslationUnit = Ptr{Cvoid}

struct CXComment
    ASTNode::Ptr{Cvoid}
    TranslationUnit::CXTranslationUnit
end

# begin enum CXCommentKind
const CXCommentKind = UInt32
const CXComment_Null = 0 |> UInt32
const CXComment_Text = 1 |> UInt32
const CXComment_InlineCommand = 2 |> UInt32
const CXComment_HTMLStartTag = 3 |> UInt32
const CXComment_HTMLEndTag = 4 |> UInt32
const CXComment_Paragraph = 5 |> UInt32
const CXComment_BlockCommand = 6 |> UInt32
const CXComment_ParamCommand = 7 |> UInt32
const CXComment_TParamCommand = 8 |> UInt32
const CXComment_VerbatimBlockCommand = 9 |> UInt32
const CXComment_VerbatimBlockLine = 10 |> UInt32
const CXComment_VerbatimLine = 11 |> UInt32
const CXComment_FullComment = 12 |> UInt32
# end enum CXCommentKind

# begin enum CXCommentInlineCommandRenderKind
const CXCommentInlineCommandRenderKind = UInt32
const CXCommentInlineCommandRenderKind_Normal = 0 |> UInt32
const CXCommentInlineCommandRenderKind_Bold = 1 |> UInt32
const CXCommentInlineCommandRenderKind_Monospaced = 2 |> UInt32
const CXCommentInlineCommandRenderKind_Emphasized = 3 |> UInt32
# end enum CXCommentInlineCommandRenderKind

# begin enum CXCommentParamPassDirection
const CXCommentParamPassDirection = UInt32
const CXCommentParamPassDirection_In = 0 |> UInt32
const CXCommentParamPassDirection_Out = 1 |> UInt32
const CXCommentParamPassDirection_InOut = 2 |> UInt32
# end enum CXCommentParamPassDirection

const CINDEX_VERSION_MAJOR = 0
const CINDEX_VERSION_MINOR = 45

# Skipping MacroDefinition: CINDEX_VERSION_ENCODE ( major , minor ) ( ( ( major ) * 10000 ) + ( ( minor ) * 1 ) )
# Skipping MacroDefinition: CINDEX_VERSION CINDEX_VERSION_ENCODE ( CINDEX_VERSION_MAJOR , CINDEX_VERSION_MINOR )
# Skipping MacroDefinition: CINDEX_VERSION_STRINGIZE_ ( major , minor ) # major "." # minor
# Skipping MacroDefinition: CINDEX_VERSION_STRINGIZE ( major , minor ) CINDEX_VERSION_STRINGIZE_ ( major , minor )
# Skipping MacroDefinition: CINDEX_VERSION_STRING CINDEX_VERSION_STRINGIZE ( CINDEX_VERSION_MAJOR , CINDEX_VERSION_MINOR )

const CXIndex = Ptr{Cvoid}
const CXTargetInfo = Cvoid
const CXClientData = Ptr{Cvoid}

struct CXUnsavedFile
    Filename::Cstring
    Contents::Cstring
    Length::Culong
end

# begin enum CXAvailabilityKind
const CXAvailabilityKind = UInt32
const CXAvailability_Available = 0 |> UInt32
const CXAvailability_Deprecated = 1 |> UInt32
const CXAvailability_NotAvailable = 2 |> UInt32
const CXAvailability_NotAccessible = 3 |> UInt32
# end enum CXAvailabilityKind

struct CXVersion
    Major::Cint
    Minor::Cint
    Subminor::Cint
end

# begin enum CXCursor_ExceptionSpecificationKind
const CXCursor_ExceptionSpecificationKind = UInt32
const CXCursor_ExceptionSpecificationKind_None = 0 |> UInt32
const CXCursor_ExceptionSpecificationKind_DynamicNone = 1 |> UInt32
const CXCursor_ExceptionSpecificationKind_Dynamic = 2 |> UInt32
const CXCursor_ExceptionSpecificationKind_MSAny = 3 |> UInt32
const CXCursor_ExceptionSpecificationKind_BasicNoexcept = 4 |> UInt32
const CXCursor_ExceptionSpecificationKind_ComputedNoexcept = 5 |> UInt32
const CXCursor_ExceptionSpecificationKind_Unevaluated = 6 |> UInt32
const CXCursor_ExceptionSpecificationKind_Uninstantiated = 7 |> UInt32
const CXCursor_ExceptionSpecificationKind_Unparsed = 8 |> UInt32
# end enum CXCursor_ExceptionSpecificationKind

# begin enum CXGlobalOptFlags
const CXGlobalOptFlags = UInt32
const CXGlobalOpt_None = 0 |> UInt32
const CXGlobalOpt_ThreadBackgroundPriorityForIndexing = 1 |> UInt32
const CXGlobalOpt_ThreadBackgroundPriorityForEditing = 2 |> UInt32
const CXGlobalOpt_ThreadBackgroundPriorityForAll = 3 |> UInt32
# end enum CXGlobalOptFlags

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

# begin enum CXDiagnostic
const CXDiagnostic = UInt32
const CXDiagnostic_Ignored = 0 |> UInt32
const CXDiagnostic_Note = 1 |> UInt32
const CXDiagnostic_Warning = 2 |> UInt32
const CXDiagnostic_Error = 3 |> UInt32
const CXDiagnostic_Fatal = 4 |> UInt32
# end enum CXDiagnostic

const CXDiagnosticSet = Ptr{Cvoid}

# begin enum CXLoadDiag_Error
const CXLoadDiag_Error = UInt32
const CXLoadDiag_None = 0 |> UInt32
const CXLoadDiag_Unknown = 1 |> UInt32
const CXLoadDiag_CannotLoad = 2 |> UInt32
const CXLoadDiag_InvalidFile = 3 |> UInt32
# end enum CXLoadDiag_Error

# begin enum CXDiagnosticDisplayOptions
const CXDiagnosticDisplayOptions = UInt32
const CXDiagnostic_DisplaySourceLocation = 1 |> UInt32
const CXDiagnostic_DisplayColumn = 2 |> UInt32
const CXDiagnostic_DisplaySourceRanges = 4 |> UInt32
const CXDiagnostic_DisplayOption = 8 |> UInt32
const CXDiagnostic_DisplayCategoryId = 16 |> UInt32
const CXDiagnostic_DisplayCategoryName = 32 |> UInt32
# end enum CXDiagnosticDisplayOptions

# begin enum CXTranslationUnit_Flags
const CXTranslationUnit_Flags = UInt32
const CXTranslationUnit_None = 0 |> UInt32
const CXTranslationUnit_DetailedPreprocessingRecord = 1 |> UInt32
const CXTranslationUnit_Incomplete = 2 |> UInt32
const CXTranslationUnit_PrecompiledPreamble = 4 |> UInt32
const CXTranslationUnit_CacheCompletionResults = 8 |> UInt32
const CXTranslationUnit_ForSerialization = 16 |> UInt32
const CXTranslationUnit_CXXChainedPCH = 32 |> UInt32
const CXTranslationUnit_SkipFunctionBodies = 64 |> UInt32
const CXTranslationUnit_IncludeBriefCommentsInCodeCompletion = 128 |> UInt32
const CXTranslationUnit_CreatePreambleOnFirstParse = 256 |> UInt32
const CXTranslationUnit_KeepGoing = 512 |> UInt32
const CXTranslationUnit_SingleFileParse = 1024 |> UInt32
# end enum CXTranslationUnit_Flags

# begin enum CXSaveTranslationUnit_Flags
const CXSaveTranslationUnit_Flags = UInt32
const CXSaveTranslationUnit_None = 0 |> UInt32
# end enum CXSaveTranslationUnit_Flags

# begin enum CXSaveError
const CXSaveError = UInt32
const CXSaveError_None = 0 |> UInt32
const CXSaveError_Unknown = 1 |> UInt32
const CXSaveError_TranslationErrors = 2 |> UInt32
const CXSaveError_InvalidTU = 3 |> UInt32
# end enum CXSaveError

# begin enum CXReparse_Flags
const CXReparse_Flags = UInt32
const CXReparse_None = 0 |> UInt32
# end enum CXReparse_Flags

# begin enum CXTUResourceUsageKind
const CXTUResourceUsageKind = UInt32
const CXTUResourceUsage_AST = 1 |> UInt32
const CXTUResourceUsage_Identifiers = 2 |> UInt32
const CXTUResourceUsage_Selectors = 3 |> UInt32
const CXTUResourceUsage_GlobalCompletionResults = 4 |> UInt32
const CXTUResourceUsage_SourceManagerContentCache = 5 |> UInt32
const CXTUResourceUsage_AST_SideTables = 6 |> UInt32
const CXTUResourceUsage_SourceManager_Membuffer_Malloc = 7 |> UInt32
const CXTUResourceUsage_SourceManager_Membuffer_MMap = 8 |> UInt32
const CXTUResourceUsage_ExternalASTSource_Membuffer_Malloc = 9 |> UInt32
const CXTUResourceUsage_ExternalASTSource_Membuffer_MMap = 10 |> UInt32
const CXTUResourceUsage_Preprocessor = 11 |> UInt32
const CXTUResourceUsage_PreprocessingRecord = 12 |> UInt32
const CXTUResourceUsage_SourceManager_DataStructures = 13 |> UInt32
const CXTUResourceUsage_Preprocessor_HeaderSearch = 14 |> UInt32
const CXTUResourceUsage_MEMORY_IN_BYTES_BEGIN = 1 |> UInt32
const CXTUResourceUsage_MEMORY_IN_BYTES_END = 14 |> UInt32
const CXTUResourceUsage_First = 1 |> UInt32
const CXTUResourceUsage_Last = 14 |> UInt32
# end enum CXTUResourceUsageKind

struct CXTUResourceUsageEntry
    kind::Cvoid
    amount::Culong
end

struct CXTUResourceUsage
    data::Ptr{Cvoid}
    numEntries::UInt32
    entries::Ptr{CXTUResourceUsageEntry}
end

# begin enum CXCursorKind
const CXCursorKind = UInt32
const CXCursor_UnexposedDecl = 1 |> UInt32
const CXCursor_StructDecl = 2 |> UInt32
const CXCursor_UnionDecl = 3 |> UInt32
const CXCursor_ClassDecl = 4 |> UInt32
const CXCursor_EnumDecl = 5 |> UInt32
const CXCursor_FieldDecl = 6 |> UInt32
const CXCursor_EnumConstantDecl = 7 |> UInt32
const CXCursor_FunctionDecl = 8 |> UInt32
const CXCursor_VarDecl = 9 |> UInt32
const CXCursor_ParmDecl = 10 |> UInt32
const CXCursor_ObjCInterfaceDecl = 11 |> UInt32
const CXCursor_ObjCCategoryDecl = 12 |> UInt32
const CXCursor_ObjCProtocolDecl = 13 |> UInt32
const CXCursor_ObjCPropertyDecl = 14 |> UInt32
const CXCursor_ObjCIvarDecl = 15 |> UInt32
const CXCursor_ObjCInstanceMethodDecl = 16 |> UInt32
const CXCursor_ObjCClassMethodDecl = 17 |> UInt32
const CXCursor_ObjCImplementationDecl = 18 |> UInt32
const CXCursor_ObjCCategoryImplDecl = 19 |> UInt32
const CXCursor_TypedefDecl = 20 |> UInt32
const CXCursor_CXXMethod = 21 |> UInt32
const CXCursor_Namespace = 22 |> UInt32
const CXCursor_LinkageSpec = 23 |> UInt32
const CXCursor_Constructor = 24 |> UInt32
const CXCursor_Destructor = 25 |> UInt32
const CXCursor_ConversionFunction = 26 |> UInt32
const CXCursor_TemplateTypeParameter = 27 |> UInt32
const CXCursor_NonTypeTemplateParameter = 28 |> UInt32
const CXCursor_TemplateTemplateParameter = 29 |> UInt32
const CXCursor_FunctionTemplate = 30 |> UInt32
const CXCursor_ClassTemplate = 31 |> UInt32
const CXCursor_ClassTemplatePartialSpecialization = 32 |> UInt32
const CXCursor_NamespaceAlias = 33 |> UInt32
const CXCursor_UsingDirective = 34 |> UInt32
const CXCursor_UsingDeclaration = 35 |> UInt32
const CXCursor_TypeAliasDecl = 36 |> UInt32
const CXCursor_ObjCSynthesizeDecl = 37 |> UInt32
const CXCursor_ObjCDynamicDecl = 38 |> UInt32
const CXCursor_CXXAccessSpecifier = 39 |> UInt32
const CXCursor_FirstDecl = 1 |> UInt32
const CXCursor_LastDecl = 39 |> UInt32
const CXCursor_FirstRef = 40 |> UInt32
const CXCursor_ObjCSuperClassRef = 40 |> UInt32
const CXCursor_ObjCProtocolRef = 41 |> UInt32
const CXCursor_ObjCClassRef = 42 |> UInt32
const CXCursor_TypeRef = 43 |> UInt32
const CXCursor_CXXBaseSpecifier = 44 |> UInt32
const CXCursor_TemplateRef = 45 |> UInt32
const CXCursor_NamespaceRef = 46 |> UInt32
const CXCursor_MemberRef = 47 |> UInt32
const CXCursor_LabelRef = 48 |> UInt32
const CXCursor_OverloadedDeclRef = 49 |> UInt32
const CXCursor_VariableRef = 50 |> UInt32
const CXCursor_LastRef = 50 |> UInt32
const CXCursor_FirstInvalid = 70 |> UInt32
const CXCursor_InvalidFile = 70 |> UInt32
const CXCursor_NoDeclFound = 71 |> UInt32
const CXCursor_NotImplemented = 72 |> UInt32
const CXCursor_InvalidCode = 73 |> UInt32
const CXCursor_LastInvalid = 73 |> UInt32
const CXCursor_FirstExpr = 100 |> UInt32
const CXCursor_UnexposedExpr = 100 |> UInt32
const CXCursor_DeclRefExpr = 101 |> UInt32
const CXCursor_MemberRefExpr = 102 |> UInt32
const CXCursor_CallExpr = 103 |> UInt32
const CXCursor_ObjCMessageExpr = 104 |> UInt32
const CXCursor_BlockExpr = 105 |> UInt32
const CXCursor_IntegerLiteral = 106 |> UInt32
const CXCursor_FloatingLiteral = 107 |> UInt32
const CXCursor_ImaginaryLiteral = 108 |> UInt32
const CXCursor_StringLiteral = 109 |> UInt32
const CXCursor_CharacterLiteral = 110 |> UInt32
const CXCursor_ParenExpr = 111 |> UInt32
const CXCursor_UnaryOperator = 112 |> UInt32
const CXCursor_ArraySubscriptExpr = 113 |> UInt32
const CXCursor_BinaryOperator = 114 |> UInt32
const CXCursor_CompoundAssignOperator = 115 |> UInt32
const CXCursor_ConditionalOperator = 116 |> UInt32
const CXCursor_CStyleCastExpr = 117 |> UInt32
const CXCursor_CompoundLiteralExpr = 118 |> UInt32
const CXCursor_InitListExpr = 119 |> UInt32
const CXCursor_AddrLabelExpr = 120 |> UInt32
const CXCursor_StmtExpr = 121 |> UInt32
const CXCursor_GenericSelectionExpr = 122 |> UInt32
const CXCursor_GNUNullExpr = 123 |> UInt32
const CXCursor_CXXStaticCastExpr = 124 |> UInt32
const CXCursor_CXXDynamicCastExpr = 125 |> UInt32
const CXCursor_CXXReinterpretCastExpr = 126 |> UInt32
const CXCursor_CXXConstCastExpr = 127 |> UInt32
const CXCursor_CXXFunctionalCastExpr = 128 |> UInt32
const CXCursor_CXXTypeidExpr = 129 |> UInt32
const CXCursor_CXXBoolLiteralExpr = 130 |> UInt32
const CXCursor_CXXNullPtrLiteralExpr = 131 |> UInt32
const CXCursor_CXXThisExpr = 132 |> UInt32
const CXCursor_CXXThrowExpr = 133 |> UInt32
const CXCursor_CXXNewExpr = 134 |> UInt32
const CXCursor_CXXDeleteExpr = 135 |> UInt32
const CXCursor_UnaryExpr = 136 |> UInt32
const CXCursor_ObjCStringLiteral = 137 |> UInt32
const CXCursor_ObjCEncodeExpr = 138 |> UInt32
const CXCursor_ObjCSelectorExpr = 139 |> UInt32
const CXCursor_ObjCProtocolExpr = 140 |> UInt32
const CXCursor_ObjCBridgedCastExpr = 141 |> UInt32
const CXCursor_PackExpansionExpr = 142 |> UInt32
const CXCursor_SizeOfPackExpr = 143 |> UInt32
const CXCursor_LambdaExpr = 144 |> UInt32
const CXCursor_ObjCBoolLiteralExpr = 145 |> UInt32
const CXCursor_ObjCSelfExpr = 146 |> UInt32
const CXCursor_OMPArraySectionExpr = 147 |> UInt32
const CXCursor_ObjCAvailabilityCheckExpr = 148 |> UInt32
const CXCursor_LastExpr = 148 |> UInt32
const CXCursor_FirstStmt = 200 |> UInt32
const CXCursor_UnexposedStmt = 200 |> UInt32
const CXCursor_LabelStmt = 201 |> UInt32
const CXCursor_CompoundStmt = 202 |> UInt32
const CXCursor_CaseStmt = 203 |> UInt32
const CXCursor_DefaultStmt = 204 |> UInt32
const CXCursor_IfStmt = 205 |> UInt32
const CXCursor_SwitchStmt = 206 |> UInt32
const CXCursor_WhileStmt = 207 |> UInt32
const CXCursor_DoStmt = 208 |> UInt32
const CXCursor_ForStmt = 209 |> UInt32
const CXCursor_GotoStmt = 210 |> UInt32
const CXCursor_IndirectGotoStmt = 211 |> UInt32
const CXCursor_ContinueStmt = 212 |> UInt32
const CXCursor_BreakStmt = 213 |> UInt32
const CXCursor_ReturnStmt = 214 |> UInt32
const CXCursor_GCCAsmStmt = 215 |> UInt32
const CXCursor_AsmStmt = 215 |> UInt32
const CXCursor_ObjCAtTryStmt = 216 |> UInt32
const CXCursor_ObjCAtCatchStmt = 217 |> UInt32
const CXCursor_ObjCAtFinallyStmt = 218 |> UInt32
const CXCursor_ObjCAtThrowStmt = 219 |> UInt32
const CXCursor_ObjCAtSynchronizedStmt = 220 |> UInt32
const CXCursor_ObjCAutoreleasePoolStmt = 221 |> UInt32
const CXCursor_ObjCForCollectionStmt = 222 |> UInt32
const CXCursor_CXXCatchStmt = 223 |> UInt32
const CXCursor_CXXTryStmt = 224 |> UInt32
const CXCursor_CXXForRangeStmt = 225 |> UInt32
const CXCursor_SEHTryStmt = 226 |> UInt32
const CXCursor_SEHExceptStmt = 227 |> UInt32
const CXCursor_SEHFinallyStmt = 228 |> UInt32
const CXCursor_MSAsmStmt = 229 |> UInt32
const CXCursor_NullStmt = 230 |> UInt32
const CXCursor_DeclStmt = 231 |> UInt32
const CXCursor_OMPParallelDirective = 232 |> UInt32
const CXCursor_OMPSimdDirective = 233 |> UInt32
const CXCursor_OMPForDirective = 234 |> UInt32
const CXCursor_OMPSectionsDirective = 235 |> UInt32
const CXCursor_OMPSectionDirective = 236 |> UInt32
const CXCursor_OMPSingleDirective = 237 |> UInt32
const CXCursor_OMPParallelForDirective = 238 |> UInt32
const CXCursor_OMPParallelSectionsDirective = 239 |> UInt32
const CXCursor_OMPTaskDirective = 240 |> UInt32
const CXCursor_OMPMasterDirective = 241 |> UInt32
const CXCursor_OMPCriticalDirective = 242 |> UInt32
const CXCursor_OMPTaskyieldDirective = 243 |> UInt32
const CXCursor_OMPBarrierDirective = 244 |> UInt32
const CXCursor_OMPTaskwaitDirective = 245 |> UInt32
const CXCursor_OMPFlushDirective = 246 |> UInt32
const CXCursor_SEHLeaveStmt = 247 |> UInt32
const CXCursor_OMPOrderedDirective = 248 |> UInt32
const CXCursor_OMPAtomicDirective = 249 |> UInt32
const CXCursor_OMPForSimdDirective = 250 |> UInt32
const CXCursor_OMPParallelForSimdDirective = 251 |> UInt32
const CXCursor_OMPTargetDirective = 252 |> UInt32
const CXCursor_OMPTeamsDirective = 253 |> UInt32
const CXCursor_OMPTaskgroupDirective = 254 |> UInt32
const CXCursor_OMPCancellationPointDirective = 255 |> UInt32
const CXCursor_OMPCancelDirective = 256 |> UInt32
const CXCursor_OMPTargetDataDirective = 257 |> UInt32
const CXCursor_OMPTaskLoopDirective = 258 |> UInt32
const CXCursor_OMPTaskLoopSimdDirective = 259 |> UInt32
const CXCursor_OMPDistributeDirective = 260 |> UInt32
const CXCursor_OMPTargetEnterDataDirective = 261 |> UInt32
const CXCursor_OMPTargetExitDataDirective = 262 |> UInt32
const CXCursor_OMPTargetParallelDirective = 263 |> UInt32
const CXCursor_OMPTargetParallelForDirective = 264 |> UInt32
const CXCursor_OMPTargetUpdateDirective = 265 |> UInt32
const CXCursor_OMPDistributeParallelForDirective = 266 |> UInt32
const CXCursor_OMPDistributeParallelForSimdDirective = 267 |> UInt32
const CXCursor_OMPDistributeSimdDirective = 268 |> UInt32
const CXCursor_OMPTargetParallelForSimdDirective = 269 |> UInt32
const CXCursor_OMPTargetSimdDirective = 270 |> UInt32
const CXCursor_OMPTeamsDistributeDirective = 271 |> UInt32
const CXCursor_OMPTeamsDistributeSimdDirective = 272 |> UInt32
const CXCursor_OMPTeamsDistributeParallelForSimdDirective = 273 |> UInt32
const CXCursor_OMPTeamsDistributeParallelForDirective = 274 |> UInt32
const CXCursor_OMPTargetTeamsDirective = 275 |> UInt32
const CXCursor_OMPTargetTeamsDistributeDirective = 276 |> UInt32
const CXCursor_OMPTargetTeamsDistributeParallelForDirective = 277 |> UInt32
const CXCursor_OMPTargetTeamsDistributeParallelForSimdDirective = 278 |> UInt32
const CXCursor_OMPTargetTeamsDistributeSimdDirective = 279 |> UInt32
const CXCursor_LastStmt = 279 |> UInt32
const CXCursor_TranslationUnit = 300 |> UInt32
const CXCursor_FirstAttr = 400 |> UInt32
const CXCursor_UnexposedAttr = 400 |> UInt32
const CXCursor_IBActionAttr = 401 |> UInt32
const CXCursor_IBOutletAttr = 402 |> UInt32
const CXCursor_IBOutletCollectionAttr = 403 |> UInt32
const CXCursor_CXXFinalAttr = 404 |> UInt32
const CXCursor_CXXOverrideAttr = 405 |> UInt32
const CXCursor_AnnotateAttr = 406 |> UInt32
const CXCursor_AsmLabelAttr = 407 |> UInt32
const CXCursor_PackedAttr = 408 |> UInt32
const CXCursor_PureAttr = 409 |> UInt32
const CXCursor_ConstAttr = 410 |> UInt32
const CXCursor_NoDuplicateAttr = 411 |> UInt32
const CXCursor_CUDAConstantAttr = 412 |> UInt32
const CXCursor_CUDADeviceAttr = 413 |> UInt32
const CXCursor_CUDAGlobalAttr = 414 |> UInt32
const CXCursor_CUDAHostAttr = 415 |> UInt32
const CXCursor_CUDASharedAttr = 416 |> UInt32
const CXCursor_VisibilityAttr = 417 |> UInt32
const CXCursor_DLLExport = 418 |> UInt32
const CXCursor_DLLImport = 419 |> UInt32
const CXCursor_LastAttr = 419 |> UInt32
const CXCursor_PreprocessingDirective = 500 |> UInt32
const CXCursor_MacroDefinition = 501 |> UInt32
const CXCursor_MacroExpansion = 502 |> UInt32
const CXCursor_MacroInstantiation = 502 |> UInt32
const CXCursor_InclusionDirective = 503 |> UInt32
const CXCursor_FirstPreprocessing = 500 |> UInt32
const CXCursor_LastPreprocessing = 503 |> UInt32
const CXCursor_ModuleImportDecl = 600 |> UInt32
const CXCursor_TypeAliasTemplateDecl = 601 |> UInt32
const CXCursor_StaticAssert = 602 |> UInt32
const CXCursor_FriendDecl = 603 |> UInt32
const CXCursor_FirstExtraDecl = 600 |> UInt32
const CXCursor_LastExtraDecl = 603 |> UInt32
const CXCursor_OverloadCandidate = 700 |> UInt32
# end enum CXCursorKind

struct CXCursor
    kind::Cvoid
    xdata::Cint
    data::NTuple{3, Ptr{Cvoid}}
end

# begin enum CXLinkageKind
const CXLinkageKind = UInt32
const CXLinkage_Invalid = 0 |> UInt32
const CXLinkage_NoLinkage = 1 |> UInt32
const CXLinkage_Internal = 2 |> UInt32
const CXLinkage_UniqueExternal = 3 |> UInt32
const CXLinkage_External = 4 |> UInt32
# end enum CXLinkageKind

# begin enum CXVisibilityKind
const CXVisibilityKind = UInt32
const CXVisibility_Invalid = 0 |> UInt32
const CXVisibility_Hidden = 1 |> UInt32
const CXVisibility_Protected = 2 |> UInt32
const CXVisibility_Default = 3 |> UInt32
# end enum CXVisibilityKind

struct CXPlatformAvailability
    Platform::CXString
    Introduced::CXVersion
    Deprecated::CXVersion
    Obsoleted::CXVersion
    Unavailable::Cint
    Message::CXString
end

# begin enum CXLanguageKind
const CXLanguageKind = UInt32
const CXLanguage_Invalid = 0 |> UInt32
const CXLanguage_C = 1 |> UInt32
const CXLanguage_ObjC = 2 |> UInt32
const CXLanguage_CPlusPlus = 3 |> UInt32
# end enum CXLanguageKind

# begin enum CXTLSKind
const CXTLSKind = UInt32
const CXTLS_None = 0 |> UInt32
const CXTLS_Dynamic = 1 |> UInt32
const CXTLS_Static = 2 |> UInt32
# end enum CXTLSKind

const CXCursorSet = Cvoid

# begin enum CXTypeKind
const CXTypeKind = UInt32
const CXType_Invalid = 0 |> UInt32
const CXType_Unexposed = 1 |> UInt32
const CXType_Void = 2 |> UInt32
const CXType_Bool = 3 |> UInt32
const CXType_Char_U = 4 |> UInt32
const CXType_UChar = 5 |> UInt32
const CXType_Char16 = 6 |> UInt32
const CXType_Char32 = 7 |> UInt32
const CXType_UShort = 8 |> UInt32
const CXType_UInt = 9 |> UInt32
const CXType_ULong = 10 |> UInt32
const CXType_ULongLong = 11 |> UInt32
const CXType_UInt128 = 12 |> UInt32
const CXType_Char_S = 13 |> UInt32
const CXType_SChar = 14 |> UInt32
const CXType_WChar = 15 |> UInt32
const CXType_Short = 16 |> UInt32
const CXType_Int = 17 |> UInt32
const CXType_Long = 18 |> UInt32
const CXType_LongLong = 19 |> UInt32
const CXType_Int128 = 20 |> UInt32
const CXType_Float = 21 |> UInt32
const CXType_Double = 22 |> UInt32
const CXType_LongDouble = 23 |> UInt32
const CXType_NullPtr = 24 |> UInt32
const CXType_Overload = 25 |> UInt32
const CXType_Dependent = 26 |> UInt32
const CXType_ObjCId = 27 |> UInt32
const CXType_ObjCClass = 28 |> UInt32
const CXType_ObjCSel = 29 |> UInt32
const CXType_Float128 = 30 |> UInt32
const CXType_Half = 31 |> UInt32
const CXType_Float16 = 32 |> UInt32
const CXType_FirstBuiltin = 2 |> UInt32
const CXType_LastBuiltin = 32 |> UInt32
const CXType_Complex = 100 |> UInt32
const CXType_Pointer = 101 |> UInt32
const CXType_BlockPointer = 102 |> UInt32
const CXType_LValueReference = 103 |> UInt32
const CXType_RValueReference = 104 |> UInt32
const CXType_Record = 105 |> UInt32
const CXType_Enum = 106 |> UInt32
const CXType_Typedef = 107 |> UInt32
const CXType_ObjCInterface = 108 |> UInt32
const CXType_ObjCObjectPointer = 109 |> UInt32
const CXType_FunctionNoProto = 110 |> UInt32
const CXType_FunctionProto = 111 |> UInt32
const CXType_ConstantArray = 112 |> UInt32
const CXType_Vector = 113 |> UInt32
const CXType_IncompleteArray = 114 |> UInt32
const CXType_VariableArray = 115 |> UInt32
const CXType_DependentSizedArray = 116 |> UInt32
const CXType_MemberPointer = 117 |> UInt32
const CXType_Auto = 118 |> UInt32
const CXType_Elaborated = 119 |> UInt32
const CXType_Pipe = 120 |> UInt32
const CXType_OCLImage1dRO = 121 |> UInt32
const CXType_OCLImage1dArrayRO = 122 |> UInt32
const CXType_OCLImage1dBufferRO = 123 |> UInt32
const CXType_OCLImage2dRO = 124 |> UInt32
const CXType_OCLImage2dArrayRO = 125 |> UInt32
const CXType_OCLImage2dDepthRO = 126 |> UInt32
const CXType_OCLImage2dArrayDepthRO = 127 |> UInt32
const CXType_OCLImage2dMSAARO = 128 |> UInt32
const CXType_OCLImage2dArrayMSAARO = 129 |> UInt32
const CXType_OCLImage2dMSAADepthRO = 130 |> UInt32
const CXType_OCLImage2dArrayMSAADepthRO = 131 |> UInt32
const CXType_OCLImage3dRO = 132 |> UInt32
const CXType_OCLImage1dWO = 133 |> UInt32
const CXType_OCLImage1dArrayWO = 134 |> UInt32
const CXType_OCLImage1dBufferWO = 135 |> UInt32
const CXType_OCLImage2dWO = 136 |> UInt32
const CXType_OCLImage2dArrayWO = 137 |> UInt32
const CXType_OCLImage2dDepthWO = 138 |> UInt32
const CXType_OCLImage2dArrayDepthWO = 139 |> UInt32
const CXType_OCLImage2dMSAAWO = 140 |> UInt32
const CXType_OCLImage2dArrayMSAAWO = 141 |> UInt32
const CXType_OCLImage2dMSAADepthWO = 142 |> UInt32
const CXType_OCLImage2dArrayMSAADepthWO = 143 |> UInt32
const CXType_OCLImage3dWO = 144 |> UInt32
const CXType_OCLImage1dRW = 145 |> UInt32
const CXType_OCLImage1dArrayRW = 146 |> UInt32
const CXType_OCLImage1dBufferRW = 147 |> UInt32
const CXType_OCLImage2dRW = 148 |> UInt32
const CXType_OCLImage2dArrayRW = 149 |> UInt32
const CXType_OCLImage2dDepthRW = 150 |> UInt32
const CXType_OCLImage2dArrayDepthRW = 151 |> UInt32
const CXType_OCLImage2dMSAARW = 152 |> UInt32
const CXType_OCLImage2dArrayMSAARW = 153 |> UInt32
const CXType_OCLImage2dMSAADepthRW = 154 |> UInt32
const CXType_OCLImage2dArrayMSAADepthRW = 155 |> UInt32
const CXType_OCLImage3dRW = 156 |> UInt32
const CXType_OCLSampler = 157 |> UInt32
const CXType_OCLEvent = 158 |> UInt32
const CXType_OCLQueue = 159 |> UInt32
const CXType_OCLReserveID = 160 |> UInt32
# end enum CXTypeKind

# begin enum CXCallingConv
const CXCallingConv = UInt32
const CXCallingConv_Default = 0 |> UInt32
const CXCallingConv_C = 1 |> UInt32
const CXCallingConv_X86StdCall = 2 |> UInt32
const CXCallingConv_X86FastCall = 3 |> UInt32
const CXCallingConv_X86ThisCall = 4 |> UInt32
const CXCallingConv_X86Pascal = 5 |> UInt32
const CXCallingConv_AAPCS = 6 |> UInt32
const CXCallingConv_AAPCS_VFP = 7 |> UInt32
const CXCallingConv_X86RegCall = 8 |> UInt32
const CXCallingConv_IntelOclBicc = 9 |> UInt32
const CXCallingConv_Win64 = 10 |> UInt32
const CXCallingConv_X86_64Win64 = 10 |> UInt32
const CXCallingConv_X86_64SysV = 11 |> UInt32
const CXCallingConv_X86VectorCall = 12 |> UInt32
const CXCallingConv_Swift = 13 |> UInt32
const CXCallingConv_PreserveMost = 14 |> UInt32
const CXCallingConv_PreserveAll = 15 |> UInt32
const CXCallingConv_Invalid = 100 |> UInt32
const CXCallingConv_Unexposed = 200 |> UInt32
# end enum CXCallingConv

struct CXType
    kind::Cvoid
    data::NTuple{2, Ptr{Cvoid}}
end

# begin enum CXTemplateArgumentKind
const CXTemplateArgumentKind = UInt32
const CXTemplateArgumentKind_Null = 0 |> UInt32
const CXTemplateArgumentKind_Type = 1 |> UInt32
const CXTemplateArgumentKind_Declaration = 2 |> UInt32
const CXTemplateArgumentKind_NullPtr = 3 |> UInt32
const CXTemplateArgumentKind_Integral = 4 |> UInt32
const CXTemplateArgumentKind_Template = 5 |> UInt32
const CXTemplateArgumentKind_TemplateExpansion = 6 |> UInt32
const CXTemplateArgumentKind_Expression = 7 |> UInt32
const CXTemplateArgumentKind_Pack = 8 |> UInt32
const CXTemplateArgumentKind_Invalid = 9 |> UInt32
# end enum CXTemplateArgumentKind

# begin enum CXTypeLayoutError
const CXTypeLayoutError = Cint
const CXTypeLayoutError_Invalid = -1 |> Int32
const CXTypeLayoutError_Incomplete = -2 |> Int32
const CXTypeLayoutError_Dependent = -3 |> Int32
const CXTypeLayoutError_NotConstantSize = -4 |> Int32
const CXTypeLayoutError_InvalidFieldName = -5 |> Int32
# end enum CXTypeLayoutError

# begin enum CXRefQualifierKind
const CXRefQualifierKind = UInt32
const CXRefQualifier_None = 0 |> UInt32
const CXRefQualifier_LValue = 1 |> UInt32
const CXRefQualifier_RValue = 2 |> UInt32
# end enum CXRefQualifierKind

# begin enum CX_CXXAccessSpecifier
const CX_CXXAccessSpecifier = UInt32
const CX_CXXInvalidAccessSpecifier = 0 |> UInt32
const CX_CXXPublic = 1 |> UInt32
const CX_CXXProtected = 2 |> UInt32
const CX_CXXPrivate = 3 |> UInt32
# end enum CX_CXXAccessSpecifier

# begin enum CX_StorageClass
const CX_StorageClass = UInt32
const CX_SC_Invalid = 0 |> UInt32
const CX_SC_None = 1 |> UInt32
const CX_SC_Extern = 2 |> UInt32
const CX_SC_Static = 3 |> UInt32
const CX_SC_PrivateExtern = 4 |> UInt32
const CX_SC_OpenCLWorkGroupLocal = 5 |> UInt32
const CX_SC_Auto = 6 |> UInt32
const CX_SC_Register = 7 |> UInt32
# end enum CX_StorageClass

# begin enum CXCursorVisitor
const CXCursorVisitor = UInt32
const CXChildVisit_Break = 0 |> UInt32
const CXChildVisit_Continue = 1 |> UInt32
const CXChildVisit_Recurse = 2 |> UInt32
# end enum CXCursorVisitor

const CXCursorVisitorBlock = Cvoid

# begin enum CXObjCPropertyAttrKind
const CXObjCPropertyAttrKind = UInt32
const CXObjCPropertyAttr_noattr = 0 |> UInt32
const CXObjCPropertyAttr_readonly = 1 |> UInt32
const CXObjCPropertyAttr_getter = 2 |> UInt32
const CXObjCPropertyAttr_assign = 4 |> UInt32
const CXObjCPropertyAttr_readwrite = 8 |> UInt32
const CXObjCPropertyAttr_retain = 16 |> UInt32
const CXObjCPropertyAttr_copy = 32 |> UInt32
const CXObjCPropertyAttr_nonatomic = 64 |> UInt32
const CXObjCPropertyAttr_setter = 128 |> UInt32
const CXObjCPropertyAttr_atomic = 256 |> UInt32
const CXObjCPropertyAttr_weak = 512 |> UInt32
const CXObjCPropertyAttr_strong = 1024 |> UInt32
const CXObjCPropertyAttr_unsafe_unretained = 2048 |> UInt32
const CXObjCPropertyAttr_class = 4096 |> UInt32
# end enum CXObjCPropertyAttrKind

# begin enum CXObjCDeclQualifierKind
const CXObjCDeclQualifierKind = UInt32
const CXObjCDeclQualifier_None = 0 |> UInt32
const CXObjCDeclQualifier_In = 1 |> UInt32
const CXObjCDeclQualifier_Inout = 2 |> UInt32
const CXObjCDeclQualifier_Out = 4 |> UInt32
const CXObjCDeclQualifier_Bycopy = 8 |> UInt32
const CXObjCDeclQualifier_Byref = 16 |> UInt32
const CXObjCDeclQualifier_Oneway = 32 |> UInt32
# end enum CXObjCDeclQualifierKind

const CXModule = Ptr{Cvoid}

# begin enum CXNameRefFlags
const CXNameRefFlags = UInt32
const CXNameRange_WantQualifier = 1 |> UInt32
const CXNameRange_WantTemplateArgs = 2 |> UInt32
const CXNameRange_WantSinglePiece = 4 |> UInt32
# end enum CXNameRefFlags

# begin enum CXTokenKind
const CXTokenKind = UInt32
const CXToken_Punctuation = 0 |> UInt32
const CXToken_Keyword = 1 |> UInt32
const CXToken_Identifier = 2 |> UInt32
const CXToken_Literal = 3 |> UInt32
const CXToken_Comment = 4 |> UInt32
# end enum CXTokenKind

struct CXToken
    int_data::NTuple{4, UInt32}
    ptr_data::Ptr{Cvoid}
end

const CXCompletionString = Ptr{Cvoid}

struct CXCompletionResult
    CursorKind::Cvoid
    CompletionString::CXCompletionString
end

# begin enum CXCompletionChunkKind
const CXCompletionChunkKind = UInt32
const CXCompletionChunk_Optional = 0 |> UInt32
const CXCompletionChunk_TypedText = 1 |> UInt32
const CXCompletionChunk_Text = 2 |> UInt32
const CXCompletionChunk_Placeholder = 3 |> UInt32
const CXCompletionChunk_Informative = 4 |> UInt32
const CXCompletionChunk_CurrentParameter = 5 |> UInt32
const CXCompletionChunk_LeftParen = 6 |> UInt32
const CXCompletionChunk_RightParen = 7 |> UInt32
const CXCompletionChunk_LeftBracket = 8 |> UInt32
const CXCompletionChunk_RightBracket = 9 |> UInt32
const CXCompletionChunk_LeftBrace = 10 |> UInt32
const CXCompletionChunk_RightBrace = 11 |> UInt32
const CXCompletionChunk_LeftAngle = 12 |> UInt32
const CXCompletionChunk_RightAngle = 13 |> UInt32
const CXCompletionChunk_Comma = 14 |> UInt32
const CXCompletionChunk_ResultType = 15 |> UInt32
const CXCompletionChunk_Colon = 16 |> UInt32
const CXCompletionChunk_SemiColon = 17 |> UInt32
const CXCompletionChunk_Equal = 18 |> UInt32
const CXCompletionChunk_HorizontalSpace = 19 |> UInt32
const CXCompletionChunk_VerticalSpace = 20 |> UInt32
# end enum CXCompletionChunkKind

struct CXCodeCompleteResults
    Results::Ptr{CXCompletionResult}
    NumResults::UInt32
end

# begin enum CXCodeComplete_Flags
const CXCodeComplete_Flags = UInt32
const CXCodeComplete_IncludeMacros = 1 |> UInt32
const CXCodeComplete_IncludeCodePatterns = 2 |> UInt32
const CXCodeComplete_IncludeBriefComments = 4 |> UInt32
# end enum CXCodeComplete_Flags

# begin enum CXCompletionContext
const CXCompletionContext = UInt32
const CXCompletionContext_Unexposed = 0 |> UInt32
const CXCompletionContext_AnyType = 1 |> UInt32
const CXCompletionContext_AnyValue = 2 |> UInt32
const CXCompletionContext_ObjCObjectValue = 4 |> UInt32
const CXCompletionContext_ObjCSelectorValue = 8 |> UInt32
const CXCompletionContext_CXXClassTypeValue = 16 |> UInt32
const CXCompletionContext_DotMemberAccess = 32 |> UInt32
const CXCompletionContext_ArrowMemberAccess = 64 |> UInt32
const CXCompletionContext_ObjCPropertyAccess = 128 |> UInt32
const CXCompletionContext_EnumTag = 256 |> UInt32
const CXCompletionContext_UnionTag = 512 |> UInt32
const CXCompletionContext_StructTag = 1024 |> UInt32
const CXCompletionContext_ClassTag = 2048 |> UInt32
const CXCompletionContext_Namespace = 4096 |> UInt32
const CXCompletionContext_NestedNameSpecifier = 8192 |> UInt32
const CXCompletionContext_ObjCInterface = 16384 |> UInt32
const CXCompletionContext_ObjCProtocol = 32768 |> UInt32
const CXCompletionContext_ObjCCategory = 65536 |> UInt32
const CXCompletionContext_ObjCInstanceMessage = 131072 |> UInt32
const CXCompletionContext_ObjCClassMessage = 262144 |> UInt32
const CXCompletionContext_ObjCSelectorName = 524288 |> UInt32
const CXCompletionContext_MacroName = 1048576 |> UInt32
const CXCompletionContext_NaturalLanguage = 2097152 |> UInt32
const CXCompletionContext_Unknown = 4194303 |> UInt32
# end enum CXCompletionContext

const CXInclusionVisitor = Ptr{Cvoid}

# begin enum CXEvalResultKind
const CXEvalResultKind = UInt32
const CXEval_Int = 1 |> UInt32
const CXEval_Float = 2 |> UInt32
const CXEval_ObjCStrLiteral = 3 |> UInt32
const CXEval_StrLiteral = 4 |> UInt32
const CXEval_CFStr = 5 |> UInt32
const CXEval_Other = 6 |> UInt32
const CXEval_UnExposed = 0 |> UInt32
# end enum CXEvalResultKind

const CXEvalResult = Ptr{Cvoid}
const CXRemapping = Ptr{Cvoid}

# begin enum CXVisitorResult
const CXVisitorResult = UInt32
const CXVisit_Break = 0 |> UInt32
const CXVisit_Continue = 1 |> UInt32
# end enum CXVisitorResult

struct CXCursorAndRangeVisitor
    context::Ptr{Cvoid}
    visit::Ptr{Cvoid}
end

# begin enum CXResult
const CXResult = UInt32
const CXResult_Success = 0 |> UInt32
const CXResult_Invalid = 1 |> UInt32
const CXResult_VisitBreak = 2 |> UInt32
# end enum CXResult

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

# begin enum CXIdxEntityKind
const CXIdxEntityKind = UInt32
const CXIdxEntity_Unexposed = 0 |> UInt32
const CXIdxEntity_Typedef = 1 |> UInt32
const CXIdxEntity_Function = 2 |> UInt32
const CXIdxEntity_Variable = 3 |> UInt32
const CXIdxEntity_Field = 4 |> UInt32
const CXIdxEntity_EnumConstant = 5 |> UInt32
const CXIdxEntity_ObjCClass = 6 |> UInt32
const CXIdxEntity_ObjCProtocol = 7 |> UInt32
const CXIdxEntity_ObjCCategory = 8 |> UInt32
const CXIdxEntity_ObjCInstanceMethod = 9 |> UInt32
const CXIdxEntity_ObjCClassMethod = 10 |> UInt32
const CXIdxEntity_ObjCProperty = 11 |> UInt32
const CXIdxEntity_ObjCIvar = 12 |> UInt32
const CXIdxEntity_Enum = 13 |> UInt32
const CXIdxEntity_Struct = 14 |> UInt32
const CXIdxEntity_Union = 15 |> UInt32
const CXIdxEntity_CXXClass = 16 |> UInt32
const CXIdxEntity_CXXNamespace = 17 |> UInt32
const CXIdxEntity_CXXNamespaceAlias = 18 |> UInt32
const CXIdxEntity_CXXStaticVariable = 19 |> UInt32
const CXIdxEntity_CXXStaticMethod = 20 |> UInt32
const CXIdxEntity_CXXInstanceMethod = 21 |> UInt32
const CXIdxEntity_CXXConstructor = 22 |> UInt32
const CXIdxEntity_CXXDestructor = 23 |> UInt32
const CXIdxEntity_CXXConversionFunction = 24 |> UInt32
const CXIdxEntity_CXXTypeAlias = 25 |> UInt32
const CXIdxEntity_CXXInterface = 26 |> UInt32
# end enum CXIdxEntityKind

# begin enum CXIdxEntityLanguage
const CXIdxEntityLanguage = UInt32
const CXIdxEntityLang_None = 0 |> UInt32
const CXIdxEntityLang_C = 1 |> UInt32
const CXIdxEntityLang_ObjC = 2 |> UInt32
const CXIdxEntityLang_CXX = 3 |> UInt32
const CXIdxEntityLang_Swift = 4 |> UInt32
# end enum CXIdxEntityLanguage

# begin enum CXIdxEntityCXXTemplateKind
const CXIdxEntityCXXTemplateKind = UInt32
const CXIdxEntity_NonTemplate = 0 |> UInt32
const CXIdxEntity_Template = 1 |> UInt32
const CXIdxEntity_TemplatePartialSpecialization = 2 |> UInt32
const CXIdxEntity_TemplateSpecialization = 3 |> UInt32
# end enum CXIdxEntityCXXTemplateKind

# begin enum CXIdxAttrKind
const CXIdxAttrKind = UInt32
const CXIdxAttr_Unexposed = 0 |> UInt32
const CXIdxAttr_IBAction = 1 |> UInt32
const CXIdxAttr_IBOutlet = 2 |> UInt32
const CXIdxAttr_IBOutletCollection = 3 |> UInt32
# end enum CXIdxAttrKind

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

# begin enum CXIdxDeclInfoFlags
const CXIdxDeclInfoFlags = UInt32
const CXIdxDeclFlag_Skipped = 1 |> UInt32
# end enum CXIdxDeclInfoFlags

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

# begin enum CXIdxObjCContainerKind
const CXIdxObjCContainerKind = UInt32
const CXIdxObjCContainer_ForwardRef = 0 |> UInt32
const CXIdxObjCContainer_Interface = 1 |> UInt32
const CXIdxObjCContainer_Implementation = 2 |> UInt32
# end enum CXIdxObjCContainerKind

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

# begin enum CXIdxEntityRefKind
const CXIdxEntityRefKind = UInt32
const CXIdxEntityRef_Direct = 1 |> UInt32
const CXIdxEntityRef_Implicit = 2 |> UInt32
# end enum CXIdxEntityRefKind

struct CXIdxEntityRefInfo
    kind::CXIdxEntityRefKind
    cursor::CXCursor
    loc::CXIdxLoc
    referencedEntity::Ptr{CXIdxEntityInfo}
    parentEntity::Ptr{CXIdxEntityInfo}
    container::Ptr{CXIdxContainerInfo}
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

# begin enum CXIndexOptFlags
const CXIndexOptFlags = UInt32
const CXIndexOpt_None = 0 |> UInt32
const CXIndexOpt_SuppressRedundantRefs = 1 |> UInt32
const CXIndexOpt_IndexFunctionLocalSymbols = 2 |> UInt32
const CXIndexOpt_IndexImplicitTemplateInstantiations = 4 |> UInt32
const CXIndexOpt_SuppressWarnings = 8 |> UInt32
const CXIndexOpt_SkipParsedBodiesInSession = 16 |> UInt32
# end enum CXIndexOptFlags

const CXFieldVisitor = Ptr{Cvoid}

# Skipping MacroDefinition: CINDEX_DEPRECATED __attribute__ ( ( deprecated ) )
