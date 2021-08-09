module LibClang

using Clang_jll
export Clang_jll

using CEnum

const Ctime_t = Int


@cenum CXErrorCode::UInt32 begin
    CXError_Success = 0
    CXError_Failure = 1
    CXError_Crashed = 2
    CXError_InvalidArguments = 3
    CXError_ASTReadError = 4
end

struct CXString
    data::Ptr{Cvoid}
    private_flags::Cuint
end

struct CXStringSet
    Strings::Ptr{CXString}
    Count::Cuint
end

function clang_getCString(string)
    @ccall libclang.clang_getCString(string::CXString)::Cstring
end

function clang_disposeString(string)
    @ccall libclang.clang_disposeString(string::CXString)::Cvoid
end

function clang_disposeStringSet(set)
    @ccall libclang.clang_disposeStringSet(set::Ptr{CXStringSet})::Cvoid
end

function clang_getBuildSessionTimestamp()
    @ccall libclang.clang_getBuildSessionTimestamp()::Culonglong
end

mutable struct CXVirtualFileOverlayImpl end

const CXVirtualFileOverlay = Ptr{CXVirtualFileOverlayImpl}

function clang_VirtualFileOverlay_create(options)
    @ccall libclang.clang_VirtualFileOverlay_create(options::Cuint)::CXVirtualFileOverlay
end

function clang_VirtualFileOverlay_addFileMapping(arg1, virtualPath, realPath)
    @ccall libclang.clang_VirtualFileOverlay_addFileMapping(arg1::CXVirtualFileOverlay, virtualPath::Cstring, realPath::Cstring)::CXErrorCode
end

function clang_VirtualFileOverlay_setCaseSensitivity(arg1, caseSensitive)
    @ccall libclang.clang_VirtualFileOverlay_setCaseSensitivity(arg1::CXVirtualFileOverlay, caseSensitive::Cint)::CXErrorCode
end

function clang_VirtualFileOverlay_writeToBuffer(arg1, options, out_buffer_ptr, out_buffer_size)
    @ccall libclang.clang_VirtualFileOverlay_writeToBuffer(arg1::CXVirtualFileOverlay, options::Cuint, out_buffer_ptr::Ptr{Cstring}, out_buffer_size::Ptr{Cuint})::CXErrorCode
end

function clang_free(buffer)
    @ccall libclang.clang_free(buffer::Ptr{Cvoid})::Cvoid
end

function clang_VirtualFileOverlay_dispose(arg1)
    @ccall libclang.clang_VirtualFileOverlay_dispose(arg1::CXVirtualFileOverlay)::Cvoid
end

mutable struct CXModuleMapDescriptorImpl end

const CXModuleMapDescriptor = Ptr{CXModuleMapDescriptorImpl}

function clang_ModuleMapDescriptor_create(options)
    @ccall libclang.clang_ModuleMapDescriptor_create(options::Cuint)::CXModuleMapDescriptor
end

function clang_ModuleMapDescriptor_setFrameworkModuleName(arg1, name)
    @ccall libclang.clang_ModuleMapDescriptor_setFrameworkModuleName(arg1::CXModuleMapDescriptor, name::Cstring)::CXErrorCode
end

function clang_ModuleMapDescriptor_setUmbrellaHeader(arg1, name)
    @ccall libclang.clang_ModuleMapDescriptor_setUmbrellaHeader(arg1::CXModuleMapDescriptor, name::Cstring)::CXErrorCode
end

function clang_ModuleMapDescriptor_writeToBuffer(arg1, options, out_buffer_ptr, out_buffer_size)
    @ccall libclang.clang_ModuleMapDescriptor_writeToBuffer(arg1::CXModuleMapDescriptor, options::Cuint, out_buffer_ptr::Ptr{Cstring}, out_buffer_size::Ptr{Cuint})::CXErrorCode
end

function clang_ModuleMapDescriptor_dispose(arg1)
    @ccall libclang.clang_ModuleMapDescriptor_dispose(arg1::CXModuleMapDescriptor)::Cvoid
end

const CXIndex = Ptr{Cvoid}

mutable struct CXTargetInfoImpl end

const CXTargetInfo = Ptr{CXTargetInfoImpl}

mutable struct CXTranslationUnitImpl end

const CXTranslationUnit = Ptr{CXTranslationUnitImpl}

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

function clang_createIndex(excludeDeclarationsFromPCH, displayDiagnostics)
    @ccall libclang.clang_createIndex(excludeDeclarationsFromPCH::Cint, displayDiagnostics::Cint)::CXIndex
end

function clang_disposeIndex(index)
    @ccall libclang.clang_disposeIndex(index::CXIndex)::Cvoid
end

@cenum CXGlobalOptFlags::UInt32 begin
    CXGlobalOpt_None = 0
    CXGlobalOpt_ThreadBackgroundPriorityForIndexing = 1
    CXGlobalOpt_ThreadBackgroundPriorityForEditing = 2
    CXGlobalOpt_ThreadBackgroundPriorityForAll = 3
end

function clang_CXIndex_setGlobalOptions(arg1, options)
    @ccall libclang.clang_CXIndex_setGlobalOptions(arg1::CXIndex, options::Cuint)::Cvoid
end

function clang_CXIndex_getGlobalOptions(arg1)
    @ccall libclang.clang_CXIndex_getGlobalOptions(arg1::CXIndex)::Cuint
end

function clang_CXIndex_setInvocationEmissionPathOption(arg1, Path)
    @ccall libclang.clang_CXIndex_setInvocationEmissionPathOption(arg1::CXIndex, Path::Cstring)::Cvoid
end

const CXFile = Ptr{Cvoid}

function clang_getFileName(SFile)
    @ccall libclang.clang_getFileName(SFile::CXFile)::CXString
end

function clang_getFileTime(SFile)
    @ccall libclang.clang_getFileTime(SFile::CXFile)::Ctime_t
end

struct CXFileUniqueID
    data::NTuple{3, Culonglong}
end

function clang_getFileUniqueID(file, outID)
    @ccall libclang.clang_getFileUniqueID(file::CXFile, outID::Ptr{CXFileUniqueID})::Cint
end

function clang_isFileMultipleIncludeGuarded(tu, file)
    @ccall libclang.clang_isFileMultipleIncludeGuarded(tu::CXTranslationUnit, file::CXFile)::Cuint
end

function clang_getFile(tu, file_name)
    @ccall libclang.clang_getFile(tu::CXTranslationUnit, file_name::Cstring)::CXFile
end

function clang_getFileContents(tu, file, size)
    @ccall libclang.clang_getFileContents(tu::CXTranslationUnit, file::CXFile, size::Ptr{Csize_t})::Cstring
end

function clang_File_isEqual(file1, file2)
    @ccall libclang.clang_File_isEqual(file1::CXFile, file2::CXFile)::Cint
end

function clang_File_tryGetRealPathName(file)
    @ccall libclang.clang_File_tryGetRealPathName(file::CXFile)::CXString
end

struct CXSourceLocation
    ptr_data::NTuple{2, Ptr{Cvoid}}
    int_data::Cuint
end

struct CXSourceRange
    ptr_data::NTuple{2, Ptr{Cvoid}}
    begin_int_data::Cuint
    end_int_data::Cuint
end

function clang_getNullLocation()
    @ccall libclang.clang_getNullLocation()::CXSourceLocation
end

function clang_equalLocations(loc1, loc2)
    @ccall libclang.clang_equalLocations(loc1::CXSourceLocation, loc2::CXSourceLocation)::Cuint
end

function clang_getLocation(tu, file, line, column)
    @ccall libclang.clang_getLocation(tu::CXTranslationUnit, file::CXFile, line::Cuint, column::Cuint)::CXSourceLocation
end

function clang_getLocationForOffset(tu, file, offset)
    @ccall libclang.clang_getLocationForOffset(tu::CXTranslationUnit, file::CXFile, offset::Cuint)::CXSourceLocation
end

function clang_Location_isInSystemHeader(location)
    @ccall libclang.clang_Location_isInSystemHeader(location::CXSourceLocation)::Cint
end

function clang_Location_isFromMainFile(location)
    @ccall libclang.clang_Location_isFromMainFile(location::CXSourceLocation)::Cint
end

function clang_getNullRange()
    @ccall libclang.clang_getNullRange()::CXSourceRange
end

function clang_getRange(_begin, _end)
    @ccall libclang.clang_getRange(_begin::CXSourceLocation, _end::CXSourceLocation)::CXSourceRange
end

function clang_equalRanges(range1, range2)
    @ccall libclang.clang_equalRanges(range1::CXSourceRange, range2::CXSourceRange)::Cuint
end

function clang_Range_isNull(range)
    @ccall libclang.clang_Range_isNull(range::CXSourceRange)::Cint
end

function clang_getExpansionLocation(location, file, line, column, offset)
    @ccall libclang.clang_getExpansionLocation(location::CXSourceLocation, file::Ptr{CXFile}, line::Ptr{Cuint}, column::Ptr{Cuint}, offset::Ptr{Cuint})::Cvoid
end

function clang_getPresumedLocation(location, filename, line, column)
    @ccall libclang.clang_getPresumedLocation(location::CXSourceLocation, filename::Ptr{CXString}, line::Ptr{Cuint}, column::Ptr{Cuint})::Cvoid
end

function clang_getInstantiationLocation(location, file, line, column, offset)
    @ccall libclang.clang_getInstantiationLocation(location::CXSourceLocation, file::Ptr{CXFile}, line::Ptr{Cuint}, column::Ptr{Cuint}, offset::Ptr{Cuint})::Cvoid
end

function clang_getSpellingLocation(location, file, line, column, offset)
    @ccall libclang.clang_getSpellingLocation(location::CXSourceLocation, file::Ptr{CXFile}, line::Ptr{Cuint}, column::Ptr{Cuint}, offset::Ptr{Cuint})::Cvoid
end

function clang_getFileLocation(location, file, line, column, offset)
    @ccall libclang.clang_getFileLocation(location::CXSourceLocation, file::Ptr{CXFile}, line::Ptr{Cuint}, column::Ptr{Cuint}, offset::Ptr{Cuint})::Cvoid
end

function clang_getRangeStart(range)
    @ccall libclang.clang_getRangeStart(range::CXSourceRange)::CXSourceLocation
end

function clang_getRangeEnd(range)
    @ccall libclang.clang_getRangeEnd(range::CXSourceRange)::CXSourceLocation
end

struct CXSourceRangeList
    count::Cuint
    ranges::Ptr{CXSourceRange}
end

function clang_getSkippedRanges(tu, file)
    @ccall libclang.clang_getSkippedRanges(tu::CXTranslationUnit, file::CXFile)::Ptr{CXSourceRangeList}
end

function clang_getAllSkippedRanges(tu)
    @ccall libclang.clang_getAllSkippedRanges(tu::CXTranslationUnit)::Ptr{CXSourceRangeList}
end

function clang_disposeSourceRangeList(ranges)
    @ccall libclang.clang_disposeSourceRangeList(ranges::Ptr{CXSourceRangeList})::Cvoid
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

function clang_getNumDiagnosticsInSet(Diags)
    @ccall libclang.clang_getNumDiagnosticsInSet(Diags::CXDiagnosticSet)::Cuint
end

function clang_getDiagnosticInSet(Diags, Index)
    @ccall libclang.clang_getDiagnosticInSet(Diags::CXDiagnosticSet, Index::Cuint)::CXDiagnostic
end

@cenum CXLoadDiag_Error::UInt32 begin
    CXLoadDiag_None = 0
    CXLoadDiag_Unknown = 1
    CXLoadDiag_CannotLoad = 2
    CXLoadDiag_InvalidFile = 3
end

function clang_loadDiagnostics(file, error, errorString)
    @ccall libclang.clang_loadDiagnostics(file::Cstring, error::Ptr{CXLoadDiag_Error}, errorString::Ptr{CXString})::CXDiagnosticSet
end

function clang_disposeDiagnosticSet(Diags)
    @ccall libclang.clang_disposeDiagnosticSet(Diags::CXDiagnosticSet)::Cvoid
end

function clang_getChildDiagnostics(D)
    @ccall libclang.clang_getChildDiagnostics(D::CXDiagnostic)::CXDiagnosticSet
end

function clang_getNumDiagnostics(Unit)
    @ccall libclang.clang_getNumDiagnostics(Unit::CXTranslationUnit)::Cuint
end

function clang_getDiagnostic(Unit, Index)
    @ccall libclang.clang_getDiagnostic(Unit::CXTranslationUnit, Index::Cuint)::CXDiagnostic
end

function clang_getDiagnosticSetFromTU(Unit)
    @ccall libclang.clang_getDiagnosticSetFromTU(Unit::CXTranslationUnit)::CXDiagnosticSet
end

function clang_disposeDiagnostic(Diagnostic)
    @ccall libclang.clang_disposeDiagnostic(Diagnostic::CXDiagnostic)::Cvoid
end

@cenum CXDiagnosticDisplayOptions::UInt32 begin
    CXDiagnostic_DisplaySourceLocation = 1
    CXDiagnostic_DisplayColumn = 2
    CXDiagnostic_DisplaySourceRanges = 4
    CXDiagnostic_DisplayOption = 8
    CXDiagnostic_DisplayCategoryId = 16
    CXDiagnostic_DisplayCategoryName = 32
end

function clang_formatDiagnostic(Diagnostic, Options)
    @ccall libclang.clang_formatDiagnostic(Diagnostic::CXDiagnostic, Options::Cuint)::CXString
end

function clang_defaultDiagnosticDisplayOptions()
    @ccall libclang.clang_defaultDiagnosticDisplayOptions()::Cuint
end

function clang_getDiagnosticSeverity(arg1)
    @ccall libclang.clang_getDiagnosticSeverity(arg1::CXDiagnostic)::CXDiagnosticSeverity
end

function clang_getDiagnosticLocation(arg1)
    @ccall libclang.clang_getDiagnosticLocation(arg1::CXDiagnostic)::CXSourceLocation
end

function clang_getDiagnosticSpelling(arg1)
    @ccall libclang.clang_getDiagnosticSpelling(arg1::CXDiagnostic)::CXString
end

function clang_getDiagnosticOption(Diag, Disable)
    @ccall libclang.clang_getDiagnosticOption(Diag::CXDiagnostic, Disable::Ptr{CXString})::CXString
end

function clang_getDiagnosticCategory(arg1)
    @ccall libclang.clang_getDiagnosticCategory(arg1::CXDiagnostic)::Cuint
end

function clang_getDiagnosticCategoryName(Category)
    @ccall libclang.clang_getDiagnosticCategoryName(Category::Cuint)::CXString
end

function clang_getDiagnosticCategoryText(arg1)
    @ccall libclang.clang_getDiagnosticCategoryText(arg1::CXDiagnostic)::CXString
end

function clang_getDiagnosticNumRanges(arg1)
    @ccall libclang.clang_getDiagnosticNumRanges(arg1::CXDiagnostic)::Cuint
end

function clang_getDiagnosticRange(Diagnostic, Range)
    @ccall libclang.clang_getDiagnosticRange(Diagnostic::CXDiagnostic, Range::Cuint)::CXSourceRange
end

function clang_getDiagnosticNumFixIts(Diagnostic)
    @ccall libclang.clang_getDiagnosticNumFixIts(Diagnostic::CXDiagnostic)::Cuint
end

function clang_getDiagnosticFixIt(Diagnostic, FixIt, ReplacementRange)
    @ccall libclang.clang_getDiagnosticFixIt(Diagnostic::CXDiagnostic, FixIt::Cuint, ReplacementRange::Ptr{CXSourceRange})::CXString
end

function clang_getTranslationUnitSpelling(CTUnit)
    @ccall libclang.clang_getTranslationUnitSpelling(CTUnit::CXTranslationUnit)::CXString
end

function clang_createTranslationUnitFromSourceFile(CIdx, source_filename, num_clang_command_line_args, clang_command_line_args, num_unsaved_files, unsaved_files)
    @ccall libclang.clang_createTranslationUnitFromSourceFile(CIdx::CXIndex, source_filename::Cstring, num_clang_command_line_args::Cint, clang_command_line_args::Ptr{Cstring}, num_unsaved_files::Cuint, unsaved_files::Ptr{CXUnsavedFile})::CXTranslationUnit
end

function clang_createTranslationUnit(CIdx, ast_filename)
    @ccall libclang.clang_createTranslationUnit(CIdx::CXIndex, ast_filename::Cstring)::CXTranslationUnit
end

function clang_createTranslationUnit2(CIdx, ast_filename, out_TU)
    @ccall libclang.clang_createTranslationUnit2(CIdx::CXIndex, ast_filename::Cstring, out_TU::Ptr{CXTranslationUnit})::CXErrorCode
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
    CXTranslationUnit_RetainExcludedConditionalBlocks = 32768
end

function clang_defaultEditingTranslationUnitOptions()
    @ccall libclang.clang_defaultEditingTranslationUnitOptions()::Cuint
end

function clang_parseTranslationUnit(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options)
    @ccall libclang.clang_parseTranslationUnit(CIdx::CXIndex, source_filename::Cstring, command_line_args::Ptr{Cstring}, num_command_line_args::Cint, unsaved_files::Ptr{CXUnsavedFile}, num_unsaved_files::Cuint, options::Cuint)::CXTranslationUnit
end

function clang_parseTranslationUnit2(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
    @ccall libclang.clang_parseTranslationUnit2(CIdx::CXIndex, source_filename::Cstring, command_line_args::Ptr{Cstring}, num_command_line_args::Cint, unsaved_files::Ptr{CXUnsavedFile}, num_unsaved_files::Cuint, options::Cuint, out_TU::Ptr{CXTranslationUnit})::CXErrorCode
end

function clang_parseTranslationUnit2FullArgv(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
    @ccall libclang.clang_parseTranslationUnit2FullArgv(CIdx::CXIndex, source_filename::Cstring, command_line_args::Ptr{Cstring}, num_command_line_args::Cint, unsaved_files::Ptr{CXUnsavedFile}, num_unsaved_files::Cuint, options::Cuint, out_TU::Ptr{CXTranslationUnit})::CXErrorCode
end

@cenum CXSaveTranslationUnit_Flags::UInt32 begin
    CXSaveTranslationUnit_None = 0
end

function clang_defaultSaveOptions(TU)
    @ccall libclang.clang_defaultSaveOptions(TU::CXTranslationUnit)::Cuint
end

@cenum CXSaveError::UInt32 begin
    CXSaveError_None = 0
    CXSaveError_Unknown = 1
    CXSaveError_TranslationErrors = 2
    CXSaveError_InvalidTU = 3
end

function clang_saveTranslationUnit(TU, FileName, options)
    @ccall libclang.clang_saveTranslationUnit(TU::CXTranslationUnit, FileName::Cstring, options::Cuint)::Cint
end

function clang_suspendTranslationUnit(arg1)
    @ccall libclang.clang_suspendTranslationUnit(arg1::CXTranslationUnit)::Cuint
end

function clang_disposeTranslationUnit(arg1)
    @ccall libclang.clang_disposeTranslationUnit(arg1::CXTranslationUnit)::Cvoid
end

@cenum CXReparse_Flags::UInt32 begin
    CXReparse_None = 0
end

function clang_defaultReparseOptions(TU)
    @ccall libclang.clang_defaultReparseOptions(TU::CXTranslationUnit)::Cuint
end

function clang_reparseTranslationUnit(TU, num_unsaved_files, unsaved_files, options)
    @ccall libclang.clang_reparseTranslationUnit(TU::CXTranslationUnit, num_unsaved_files::Cuint, unsaved_files::Ptr{CXUnsavedFile}, options::Cuint)::Cint
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

function clang_getTUResourceUsageName(kind)
    @ccall libclang.clang_getTUResourceUsageName(kind::CXTUResourceUsageKind)::Cstring
end

struct CXTUResourceUsageEntry
    kind::CXTUResourceUsageKind
    amount::Culong
end

struct CXTUResourceUsage
    data::Ptr{Cvoid}
    numEntries::Cuint
    entries::Ptr{CXTUResourceUsageEntry}
end

function clang_getCXTUResourceUsage(TU)
    @ccall libclang.clang_getCXTUResourceUsage(TU::CXTranslationUnit)::CXTUResourceUsage
end

function clang_disposeCXTUResourceUsage(usage)
    @ccall libclang.clang_disposeCXTUResourceUsage(usage::CXTUResourceUsage)::Cvoid
end

function clang_getTranslationUnitTargetInfo(CTUnit)
    @ccall libclang.clang_getTranslationUnitTargetInfo(CTUnit::CXTranslationUnit)::CXTargetInfo
end

function clang_TargetInfo_dispose(Info)
    @ccall libclang.clang_TargetInfo_dispose(Info::CXTargetInfo)::Cvoid
end

function clang_TargetInfo_getTriple(Info)
    @ccall libclang.clang_TargetInfo_getTriple(Info::CXTargetInfo)::CXString
end

function clang_TargetInfo_getPointerWidth(Info)
    @ccall libclang.clang_TargetInfo_getPointerWidth(Info::CXTargetInfo)::Cint
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
    CXCursor_CXXAddrspaceCastExpr = 129
    CXCursor_CXXTypeidExpr = 130
    CXCursor_CXXBoolLiteralExpr = 131
    CXCursor_CXXNullPtrLiteralExpr = 132
    CXCursor_CXXThisExpr = 133
    CXCursor_CXXThrowExpr = 134
    CXCursor_CXXNewExpr = 135
    CXCursor_CXXDeleteExpr = 136
    CXCursor_UnaryExpr = 137
    CXCursor_ObjCStringLiteral = 138
    CXCursor_ObjCEncodeExpr = 139
    CXCursor_ObjCSelectorExpr = 140
    CXCursor_ObjCProtocolExpr = 141
    CXCursor_ObjCBridgedCastExpr = 142
    CXCursor_PackExpansionExpr = 143
    CXCursor_SizeOfPackExpr = 144
    CXCursor_LambdaExpr = 145
    CXCursor_ObjCBoolLiteralExpr = 146
    CXCursor_ObjCSelfExpr = 147
    CXCursor_OMPArraySectionExpr = 148
    CXCursor_ObjCAvailabilityCheckExpr = 149
    CXCursor_FixedPointLiteral = 150
    CXCursor_OMPArrayShapingExpr = 151
    CXCursor_OMPIteratorExpr = 152
    CXCursor_LastExpr = 152
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
    CXCursor_OMPMasterTaskLoopDirective = 281
    CXCursor_OMPParallelMasterTaskLoopDirective = 282
    CXCursor_OMPMasterTaskLoopSimdDirective = 283
    CXCursor_OMPParallelMasterTaskLoopSimdDirective = 284
    CXCursor_OMPParallelMasterDirective = 285
    CXCursor_OMPDepobjDirective = 286
    CXCursor_OMPScanDirective = 287
    CXCursor_LastStmt = 287
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

function clang_getNullCursor()
    @ccall libclang.clang_getNullCursor()::CXCursor
end

function clang_getTranslationUnitCursor(arg1)
    @ccall libclang.clang_getTranslationUnitCursor(arg1::CXTranslationUnit)::CXCursor
end

function clang_equalCursors(arg1, arg2)
    @ccall libclang.clang_equalCursors(arg1::CXCursor, arg2::CXCursor)::Cuint
end

function clang_Cursor_isNull(cursor)
    @ccall libclang.clang_Cursor_isNull(cursor::CXCursor)::Cint
end

function clang_hashCursor(arg1)
    @ccall libclang.clang_hashCursor(arg1::CXCursor)::Cuint
end

function clang_getCursorKind(arg1)
    @ccall libclang.clang_getCursorKind(arg1::CXCursor)::CXCursorKind
end

function clang_isDeclaration(arg1)
    @ccall libclang.clang_isDeclaration(arg1::CXCursorKind)::Cuint
end

function clang_isInvalidDeclaration(arg1)
    @ccall libclang.clang_isInvalidDeclaration(arg1::CXCursor)::Cuint
end

function clang_isReference(arg1)
    @ccall libclang.clang_isReference(arg1::CXCursorKind)::Cuint
end

function clang_isExpression(arg1)
    @ccall libclang.clang_isExpression(arg1::CXCursorKind)::Cuint
end

function clang_isStatement(arg1)
    @ccall libclang.clang_isStatement(arg1::CXCursorKind)::Cuint
end

function clang_isAttribute(arg1)
    @ccall libclang.clang_isAttribute(arg1::CXCursorKind)::Cuint
end

function clang_Cursor_hasAttrs(C)
    @ccall libclang.clang_Cursor_hasAttrs(C::CXCursor)::Cuint
end

function clang_isInvalid(arg1)
    @ccall libclang.clang_isInvalid(arg1::CXCursorKind)::Cuint
end

function clang_isTranslationUnit(arg1)
    @ccall libclang.clang_isTranslationUnit(arg1::CXCursorKind)::Cuint
end

function clang_isPreprocessing(arg1)
    @ccall libclang.clang_isPreprocessing(arg1::CXCursorKind)::Cuint
end

function clang_isUnexposed(arg1)
    @ccall libclang.clang_isUnexposed(arg1::CXCursorKind)::Cuint
end

@cenum CXLinkageKind::UInt32 begin
    CXLinkage_Invalid = 0
    CXLinkage_NoLinkage = 1
    CXLinkage_Internal = 2
    CXLinkage_UniqueExternal = 3
    CXLinkage_External = 4
end

function clang_getCursorLinkage(cursor)
    @ccall libclang.clang_getCursorLinkage(cursor::CXCursor)::CXLinkageKind
end

@cenum CXVisibilityKind::UInt32 begin
    CXVisibility_Invalid = 0
    CXVisibility_Hidden = 1
    CXVisibility_Protected = 2
    CXVisibility_Default = 3
end

function clang_getCursorVisibility(cursor)
    @ccall libclang.clang_getCursorVisibility(cursor::CXCursor)::CXVisibilityKind
end

function clang_getCursorAvailability(cursor)
    @ccall libclang.clang_getCursorAvailability(cursor::CXCursor)::CXAvailabilityKind
end

struct CXPlatformAvailability
    Platform::CXString
    Introduced::CXVersion
    Deprecated::CXVersion
    Obsoleted::CXVersion
    Unavailable::Cint
    Message::CXString
end

function clang_getCursorPlatformAvailability(cursor, always_deprecated, deprecated_message, always_unavailable, unavailable_message, availability, availability_size)
    @ccall libclang.clang_getCursorPlatformAvailability(cursor::CXCursor, always_deprecated::Ptr{Cint}, deprecated_message::Ptr{CXString}, always_unavailable::Ptr{Cint}, unavailable_message::Ptr{CXString}, availability::Ptr{CXPlatformAvailability}, availability_size::Cint)::Cint
end

function clang_disposeCXPlatformAvailability(availability)
    @ccall libclang.clang_disposeCXPlatformAvailability(availability::Ptr{CXPlatformAvailability})::Cvoid
end

@cenum CXLanguageKind::UInt32 begin
    CXLanguage_Invalid = 0
    CXLanguage_C = 1
    CXLanguage_ObjC = 2
    CXLanguage_CPlusPlus = 3
end

function clang_getCursorLanguage(cursor)
    @ccall libclang.clang_getCursorLanguage(cursor::CXCursor)::CXLanguageKind
end

@cenum CXTLSKind::UInt32 begin
    CXTLS_None = 0
    CXTLS_Dynamic = 1
    CXTLS_Static = 2
end

function clang_getCursorTLSKind(cursor)
    @ccall libclang.clang_getCursorTLSKind(cursor::CXCursor)::CXTLSKind
end

function clang_Cursor_getTranslationUnit(arg1)
    @ccall libclang.clang_Cursor_getTranslationUnit(arg1::CXCursor)::CXTranslationUnit
end

mutable struct CXCursorSetImpl end

const CXCursorSet = Ptr{CXCursorSetImpl}

function clang_createCXCursorSet()
    @ccall libclang.clang_createCXCursorSet()::CXCursorSet
end

function clang_disposeCXCursorSet(cset)
    @ccall libclang.clang_disposeCXCursorSet(cset::CXCursorSet)::Cvoid
end

function clang_CXCursorSet_contains(cset, cursor)
    @ccall libclang.clang_CXCursorSet_contains(cset::CXCursorSet, cursor::CXCursor)::Cuint
end

function clang_CXCursorSet_insert(cset, cursor)
    @ccall libclang.clang_CXCursorSet_insert(cset::CXCursorSet, cursor::CXCursor)::Cuint
end

function clang_getCursorSemanticParent(cursor)
    @ccall libclang.clang_getCursorSemanticParent(cursor::CXCursor)::CXCursor
end

function clang_getCursorLexicalParent(cursor)
    @ccall libclang.clang_getCursorLexicalParent(cursor::CXCursor)::CXCursor
end

function clang_getOverriddenCursors(cursor, overridden, num_overridden)
    @ccall libclang.clang_getOverriddenCursors(cursor::CXCursor, overridden::Ptr{Ptr{CXCursor}}, num_overridden::Ptr{Cuint})::Cvoid
end

function clang_disposeOverriddenCursors(overridden)
    @ccall libclang.clang_disposeOverriddenCursors(overridden::Ptr{CXCursor})::Cvoid
end

function clang_getIncludedFile(cursor)
    @ccall libclang.clang_getIncludedFile(cursor::CXCursor)::CXFile
end

function clang_getCursor(arg1, arg2)
    @ccall libclang.clang_getCursor(arg1::CXTranslationUnit, arg2::CXSourceLocation)::CXCursor
end

function clang_getCursorLocation(arg1)
    @ccall libclang.clang_getCursorLocation(arg1::CXCursor)::CXSourceLocation
end

function clang_getCursorExtent(arg1)
    @ccall libclang.clang_getCursorExtent(arg1::CXCursor)::CXSourceRange
end

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
    CXType_BFloat16 = 39
    CXType_FirstBuiltin = 2
    CXType_LastBuiltin = 39
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
    CXType_Atomic = 177
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

function clang_getCursorType(C)
    @ccall libclang.clang_getCursorType(C::CXCursor)::CXType
end

function clang_getTypeSpelling(CT)
    @ccall libclang.clang_getTypeSpelling(CT::CXType)::CXString
end

function clang_getTypedefDeclUnderlyingType(C)
    @ccall libclang.clang_getTypedefDeclUnderlyingType(C::CXCursor)::CXType
end

function clang_getEnumDeclIntegerType(C)
    @ccall libclang.clang_getEnumDeclIntegerType(C::CXCursor)::CXType
end

function clang_getEnumConstantDeclValue(C)
    @ccall libclang.clang_getEnumConstantDeclValue(C::CXCursor)::Clonglong
end

function clang_getEnumConstantDeclUnsignedValue(C)
    @ccall libclang.clang_getEnumConstantDeclUnsignedValue(C::CXCursor)::Culonglong
end

function clang_getFieldDeclBitWidth(C)
    @ccall libclang.clang_getFieldDeclBitWidth(C::CXCursor)::Cint
end

function clang_Cursor_getNumArguments(C)
    @ccall libclang.clang_Cursor_getNumArguments(C::CXCursor)::Cint
end

function clang_Cursor_getArgument(C, i)
    @ccall libclang.clang_Cursor_getArgument(C::CXCursor, i::Cuint)::CXCursor
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

function clang_Cursor_getNumTemplateArguments(C)
    @ccall libclang.clang_Cursor_getNumTemplateArguments(C::CXCursor)::Cint
end

function clang_Cursor_getTemplateArgumentKind(C, I)
    @ccall libclang.clang_Cursor_getTemplateArgumentKind(C::CXCursor, I::Cuint)::CXTemplateArgumentKind
end

function clang_Cursor_getTemplateArgumentType(C, I)
    @ccall libclang.clang_Cursor_getTemplateArgumentType(C::CXCursor, I::Cuint)::CXType
end

function clang_Cursor_getTemplateArgumentValue(C, I)
    @ccall libclang.clang_Cursor_getTemplateArgumentValue(C::CXCursor, I::Cuint)::Clonglong
end

function clang_Cursor_getTemplateArgumentUnsignedValue(C, I)
    @ccall libclang.clang_Cursor_getTemplateArgumentUnsignedValue(C::CXCursor, I::Cuint)::Culonglong
end

function clang_equalTypes(A, B)
    @ccall libclang.clang_equalTypes(A::CXType, B::CXType)::Cuint
end

function clang_getCanonicalType(T)
    @ccall libclang.clang_getCanonicalType(T::CXType)::CXType
end

function clang_isConstQualifiedType(T)
    @ccall libclang.clang_isConstQualifiedType(T::CXType)::Cuint
end

function clang_Cursor_isMacroFunctionLike(C)
    @ccall libclang.clang_Cursor_isMacroFunctionLike(C::CXCursor)::Cuint
end

function clang_Cursor_isMacroBuiltin(C)
    @ccall libclang.clang_Cursor_isMacroBuiltin(C::CXCursor)::Cuint
end

function clang_Cursor_isFunctionInlined(C)
    @ccall libclang.clang_Cursor_isFunctionInlined(C::CXCursor)::Cuint
end

function clang_isVolatileQualifiedType(T)
    @ccall libclang.clang_isVolatileQualifiedType(T::CXType)::Cuint
end

function clang_isRestrictQualifiedType(T)
    @ccall libclang.clang_isRestrictQualifiedType(T::CXType)::Cuint
end

function clang_getAddressSpace(T)
    @ccall libclang.clang_getAddressSpace(T::CXType)::Cuint
end

function clang_getTypedefName(CT)
    @ccall libclang.clang_getTypedefName(CT::CXType)::CXString
end

function clang_getPointeeType(T)
    @ccall libclang.clang_getPointeeType(T::CXType)::CXType
end

function clang_getTypeDeclaration(T)
    @ccall libclang.clang_getTypeDeclaration(T::CXType)::CXCursor
end

function clang_getDeclObjCTypeEncoding(C)
    @ccall libclang.clang_getDeclObjCTypeEncoding(C::CXCursor)::CXString
end

function clang_Type_getObjCEncoding(type)
    @ccall libclang.clang_Type_getObjCEncoding(type::CXType)::CXString
end

function clang_getTypeKindSpelling(K)
    @ccall libclang.clang_getTypeKindSpelling(K::CXTypeKind)::CXString
end

function clang_getFunctionTypeCallingConv(T)
    @ccall libclang.clang_getFunctionTypeCallingConv(T::CXType)::CXCallingConv
end

function clang_getResultType(T)
    @ccall libclang.clang_getResultType(T::CXType)::CXType
end

function clang_getExceptionSpecificationType(T)
    @ccall libclang.clang_getExceptionSpecificationType(T::CXType)::Cint
end

function clang_getNumArgTypes(T)
    @ccall libclang.clang_getNumArgTypes(T::CXType)::Cint
end

function clang_getArgType(T, i)
    @ccall libclang.clang_getArgType(T::CXType, i::Cuint)::CXType
end

function clang_Type_getObjCObjectBaseType(T)
    @ccall libclang.clang_Type_getObjCObjectBaseType(T::CXType)::CXType
end

function clang_Type_getNumObjCProtocolRefs(T)
    @ccall libclang.clang_Type_getNumObjCProtocolRefs(T::CXType)::Cuint
end

function clang_Type_getObjCProtocolDecl(T, i)
    @ccall libclang.clang_Type_getObjCProtocolDecl(T::CXType, i::Cuint)::CXCursor
end

function clang_Type_getNumObjCTypeArgs(T)
    @ccall libclang.clang_Type_getNumObjCTypeArgs(T::CXType)::Cuint
end

function clang_Type_getObjCTypeArg(T, i)
    @ccall libclang.clang_Type_getObjCTypeArg(T::CXType, i::Cuint)::CXType
end

function clang_isFunctionTypeVariadic(T)
    @ccall libclang.clang_isFunctionTypeVariadic(T::CXType)::Cuint
end

function clang_getCursorResultType(C)
    @ccall libclang.clang_getCursorResultType(C::CXCursor)::CXType
end

function clang_getCursorExceptionSpecificationType(C)
    @ccall libclang.clang_getCursorExceptionSpecificationType(C::CXCursor)::Cint
end

function clang_isPODType(T)
    @ccall libclang.clang_isPODType(T::CXType)::Cuint
end

function clang_getElementType(T)
    @ccall libclang.clang_getElementType(T::CXType)::CXType
end

function clang_getNumElements(T)
    @ccall libclang.clang_getNumElements(T::CXType)::Clonglong
end

function clang_getArrayElementType(T)
    @ccall libclang.clang_getArrayElementType(T::CXType)::CXType
end

function clang_getArraySize(T)
    @ccall libclang.clang_getArraySize(T::CXType)::Clonglong
end

function clang_Type_getNamedType(T)
    @ccall libclang.clang_Type_getNamedType(T::CXType)::CXType
end

function clang_Type_isTransparentTagTypedef(T)
    @ccall libclang.clang_Type_isTransparentTagTypedef(T::CXType)::Cuint
end

@cenum CXTypeNullabilityKind::UInt32 begin
    CXTypeNullability_NonNull = 0
    CXTypeNullability_Nullable = 1
    CXTypeNullability_Unspecified = 2
    CXTypeNullability_Invalid = 3
end

function clang_Type_getNullability(T)
    @ccall libclang.clang_Type_getNullability(T::CXType)::CXTypeNullabilityKind
end

@cenum CXTypeLayoutError::Int32 begin
    CXTypeLayoutError_Invalid = -1
    CXTypeLayoutError_Incomplete = -2
    CXTypeLayoutError_Dependent = -3
    CXTypeLayoutError_NotConstantSize = -4
    CXTypeLayoutError_InvalidFieldName = -5
    CXTypeLayoutError_Undeduced = -6
end

function clang_Type_getAlignOf(T)
    @ccall libclang.clang_Type_getAlignOf(T::CXType)::Clonglong
end

function clang_Type_getClassType(T)
    @ccall libclang.clang_Type_getClassType(T::CXType)::CXType
end

function clang_Type_getSizeOf(T)
    @ccall libclang.clang_Type_getSizeOf(T::CXType)::Clonglong
end

function clang_Type_getOffsetOf(T, S)
    @ccall libclang.clang_Type_getOffsetOf(T::CXType, S::Cstring)::Clonglong
end

function clang_Type_getModifiedType(T)
    @ccall libclang.clang_Type_getModifiedType(T::CXType)::CXType
end

function clang_Type_getValueType(CT)
    @ccall libclang.clang_Type_getValueType(CT::CXType)::CXType
end

function clang_Cursor_getOffsetOfField(C)
    @ccall libclang.clang_Cursor_getOffsetOfField(C::CXCursor)::Clonglong
end

function clang_Cursor_isAnonymous(C)
    @ccall libclang.clang_Cursor_isAnonymous(C::CXCursor)::Cuint
end

function clang_Cursor_isAnonymousRecordDecl(C)
    @ccall libclang.clang_Cursor_isAnonymousRecordDecl(C::CXCursor)::Cuint
end

function clang_Cursor_isInlineNamespace(C)
    @ccall libclang.clang_Cursor_isInlineNamespace(C::CXCursor)::Cuint
end

@cenum CXRefQualifierKind::UInt32 begin
    CXRefQualifier_None = 0
    CXRefQualifier_LValue = 1
    CXRefQualifier_RValue = 2
end

function clang_Type_getNumTemplateArguments(T)
    @ccall libclang.clang_Type_getNumTemplateArguments(T::CXType)::Cint
end

function clang_Type_getTemplateArgumentAsType(T, i)
    @ccall libclang.clang_Type_getTemplateArgumentAsType(T::CXType, i::Cuint)::CXType
end

function clang_Type_getCXXRefQualifier(T)
    @ccall libclang.clang_Type_getCXXRefQualifier(T::CXType)::CXRefQualifierKind
end

function clang_Cursor_isBitField(C)
    @ccall libclang.clang_Cursor_isBitField(C::CXCursor)::Cuint
end

function clang_isVirtualBase(arg1)
    @ccall libclang.clang_isVirtualBase(arg1::CXCursor)::Cuint
end

@cenum CX_CXXAccessSpecifier::UInt32 begin
    CX_CXXInvalidAccessSpecifier = 0
    CX_CXXPublic = 1
    CX_CXXProtected = 2
    CX_CXXPrivate = 3
end

function clang_getCXXAccessSpecifier(arg1)
    @ccall libclang.clang_getCXXAccessSpecifier(arg1::CXCursor)::CX_CXXAccessSpecifier
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

function clang_Cursor_getStorageClass(arg1)
    @ccall libclang.clang_Cursor_getStorageClass(arg1::CXCursor)::CX_StorageClass
end

function clang_getNumOverloadedDecls(cursor)
    @ccall libclang.clang_getNumOverloadedDecls(cursor::CXCursor)::Cuint
end

function clang_getOverloadedDecl(cursor, index)
    @ccall libclang.clang_getOverloadedDecl(cursor::CXCursor, index::Cuint)::CXCursor
end

function clang_getIBOutletCollectionType(arg1)
    @ccall libclang.clang_getIBOutletCollectionType(arg1::CXCursor)::CXType
end

@cenum CXChildVisitResult::UInt32 begin
    CXChildVisit_Break = 0
    CXChildVisit_Continue = 1
    CXChildVisit_Recurse = 2
end

# typedef enum CXChildVisitResult ( * CXCursorVisitor ) ( CXCursor cursor , CXCursor parent , CXClientData client_data )
const CXCursorVisitor = Ptr{Cvoid}

function clang_visitChildren(parent, visitor, client_data)
    @ccall libclang.clang_visitChildren(parent::CXCursor, visitor::CXCursorVisitor, client_data::CXClientData)::Cuint
end

function clang_getCursorUSR(arg1)
    @ccall libclang.clang_getCursorUSR(arg1::CXCursor)::CXString
end

function clang_constructUSR_ObjCClass(class_name)
    @ccall libclang.clang_constructUSR_ObjCClass(class_name::Cstring)::CXString
end

function clang_constructUSR_ObjCCategory(class_name, category_name)
    @ccall libclang.clang_constructUSR_ObjCCategory(class_name::Cstring, category_name::Cstring)::CXString
end

function clang_constructUSR_ObjCProtocol(protocol_name)
    @ccall libclang.clang_constructUSR_ObjCProtocol(protocol_name::Cstring)::CXString
end

function clang_constructUSR_ObjCIvar(name, classUSR)
    @ccall libclang.clang_constructUSR_ObjCIvar(name::Cstring, classUSR::CXString)::CXString
end

function clang_constructUSR_ObjCMethod(name, isInstanceMethod, classUSR)
    @ccall libclang.clang_constructUSR_ObjCMethod(name::Cstring, isInstanceMethod::Cuint, classUSR::CXString)::CXString
end

function clang_constructUSR_ObjCProperty(property, classUSR)
    @ccall libclang.clang_constructUSR_ObjCProperty(property::Cstring, classUSR::CXString)::CXString
end

function clang_getCursorSpelling(arg1)
    @ccall libclang.clang_getCursorSpelling(arg1::CXCursor)::CXString
end

function clang_Cursor_getSpellingNameRange(arg1, pieceIndex, options)
    @ccall libclang.clang_Cursor_getSpellingNameRange(arg1::CXCursor, pieceIndex::Cuint, options::Cuint)::CXSourceRange
end

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

function clang_PrintingPolicy_getProperty(Policy, Property)
    @ccall libclang.clang_PrintingPolicy_getProperty(Policy::CXPrintingPolicy, Property::CXPrintingPolicyProperty)::Cuint
end

function clang_PrintingPolicy_setProperty(Policy, Property, Value)
    @ccall libclang.clang_PrintingPolicy_setProperty(Policy::CXPrintingPolicy, Property::CXPrintingPolicyProperty, Value::Cuint)::Cvoid
end

function clang_getCursorPrintingPolicy(arg1)
    @ccall libclang.clang_getCursorPrintingPolicy(arg1::CXCursor)::CXPrintingPolicy
end

function clang_PrintingPolicy_dispose(Policy)
    @ccall libclang.clang_PrintingPolicy_dispose(Policy::CXPrintingPolicy)::Cvoid
end

function clang_getCursorPrettyPrinted(Cursor, Policy)
    @ccall libclang.clang_getCursorPrettyPrinted(Cursor::CXCursor, Policy::CXPrintingPolicy)::CXString
end

function clang_getCursorDisplayName(arg1)
    @ccall libclang.clang_getCursorDisplayName(arg1::CXCursor)::CXString
end

function clang_getCursorReferenced(arg1)
    @ccall libclang.clang_getCursorReferenced(arg1::CXCursor)::CXCursor
end

function clang_getCursorDefinition(arg1)
    @ccall libclang.clang_getCursorDefinition(arg1::CXCursor)::CXCursor
end

function clang_isCursorDefinition(arg1)
    @ccall libclang.clang_isCursorDefinition(arg1::CXCursor)::Cuint
end

function clang_getCanonicalCursor(arg1)
    @ccall libclang.clang_getCanonicalCursor(arg1::CXCursor)::CXCursor
end

function clang_Cursor_getObjCSelectorIndex(arg1)
    @ccall libclang.clang_Cursor_getObjCSelectorIndex(arg1::CXCursor)::Cint
end

function clang_Cursor_isDynamicCall(C)
    @ccall libclang.clang_Cursor_isDynamicCall(C::CXCursor)::Cint
end

function clang_Cursor_getReceiverType(C)
    @ccall libclang.clang_Cursor_getReceiverType(C::CXCursor)::CXType
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

function clang_Cursor_getObjCPropertyAttributes(C, reserved)
    @ccall libclang.clang_Cursor_getObjCPropertyAttributes(C::CXCursor, reserved::Cuint)::Cuint
end

function clang_Cursor_getObjCPropertyGetterName(C)
    @ccall libclang.clang_Cursor_getObjCPropertyGetterName(C::CXCursor)::CXString
end

function clang_Cursor_getObjCPropertySetterName(C)
    @ccall libclang.clang_Cursor_getObjCPropertySetterName(C::CXCursor)::CXString
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

function clang_Cursor_getObjCDeclQualifiers(C)
    @ccall libclang.clang_Cursor_getObjCDeclQualifiers(C::CXCursor)::Cuint
end

function clang_Cursor_isObjCOptional(C)
    @ccall libclang.clang_Cursor_isObjCOptional(C::CXCursor)::Cuint
end

function clang_Cursor_isVariadic(C)
    @ccall libclang.clang_Cursor_isVariadic(C::CXCursor)::Cuint
end

function clang_Cursor_isExternalSymbol(C, language, definedIn, isGenerated)
    @ccall libclang.clang_Cursor_isExternalSymbol(C::CXCursor, language::Ptr{CXString}, definedIn::Ptr{CXString}, isGenerated::Ptr{Cuint})::Cuint
end

function clang_Cursor_getCommentRange(C)
    @ccall libclang.clang_Cursor_getCommentRange(C::CXCursor)::CXSourceRange
end

function clang_Cursor_getRawCommentText(C)
    @ccall libclang.clang_Cursor_getRawCommentText(C::CXCursor)::CXString
end

function clang_Cursor_getBriefCommentText(C)
    @ccall libclang.clang_Cursor_getBriefCommentText(C::CXCursor)::CXString
end

function clang_Cursor_getMangling(arg1)
    @ccall libclang.clang_Cursor_getMangling(arg1::CXCursor)::CXString
end

function clang_Cursor_getCXXManglings(arg1)
    @ccall libclang.clang_Cursor_getCXXManglings(arg1::CXCursor)::Ptr{CXStringSet}
end

function clang_Cursor_getObjCManglings(arg1)
    @ccall libclang.clang_Cursor_getObjCManglings(arg1::CXCursor)::Ptr{CXStringSet}
end

const CXModule = Ptr{Cvoid}

function clang_Cursor_getModule(C)
    @ccall libclang.clang_Cursor_getModule(C::CXCursor)::CXModule
end

function clang_getModuleForFile(arg1, arg2)
    @ccall libclang.clang_getModuleForFile(arg1::CXTranslationUnit, arg2::CXFile)::CXModule
end

function clang_Module_getASTFile(Module)
    @ccall libclang.clang_Module_getASTFile(Module::CXModule)::CXFile
end

function clang_Module_getParent(Module)
    @ccall libclang.clang_Module_getParent(Module::CXModule)::CXModule
end

function clang_Module_getName(Module)
    @ccall libclang.clang_Module_getName(Module::CXModule)::CXString
end

function clang_Module_getFullName(Module)
    @ccall libclang.clang_Module_getFullName(Module::CXModule)::CXString
end

function clang_Module_isSystem(Module)
    @ccall libclang.clang_Module_isSystem(Module::CXModule)::Cint
end

function clang_Module_getNumTopLevelHeaders(arg1, Module)
    @ccall libclang.clang_Module_getNumTopLevelHeaders(arg1::CXTranslationUnit, Module::CXModule)::Cuint
end

function clang_Module_getTopLevelHeader(arg1, Module, Index)
    @ccall libclang.clang_Module_getTopLevelHeader(arg1::CXTranslationUnit, Module::CXModule, Index::Cuint)::CXFile
end

function clang_CXXConstructor_isConvertingConstructor(C)
    @ccall libclang.clang_CXXConstructor_isConvertingConstructor(C::CXCursor)::Cuint
end

function clang_CXXConstructor_isCopyConstructor(C)
    @ccall libclang.clang_CXXConstructor_isCopyConstructor(C::CXCursor)::Cuint
end

function clang_CXXConstructor_isDefaultConstructor(C)
    @ccall libclang.clang_CXXConstructor_isDefaultConstructor(C::CXCursor)::Cuint
end

function clang_CXXConstructor_isMoveConstructor(C)
    @ccall libclang.clang_CXXConstructor_isMoveConstructor(C::CXCursor)::Cuint
end

function clang_CXXField_isMutable(C)
    @ccall libclang.clang_CXXField_isMutable(C::CXCursor)::Cuint
end

function clang_CXXMethod_isDefaulted(C)
    @ccall libclang.clang_CXXMethod_isDefaulted(C::CXCursor)::Cuint
end

function clang_CXXMethod_isPureVirtual(C)
    @ccall libclang.clang_CXXMethod_isPureVirtual(C::CXCursor)::Cuint
end

function clang_CXXMethod_isStatic(C)
    @ccall libclang.clang_CXXMethod_isStatic(C::CXCursor)::Cuint
end

function clang_CXXMethod_isVirtual(C)
    @ccall libclang.clang_CXXMethod_isVirtual(C::CXCursor)::Cuint
end

function clang_CXXRecord_isAbstract(C)
    @ccall libclang.clang_CXXRecord_isAbstract(C::CXCursor)::Cuint
end

function clang_EnumDecl_isScoped(C)
    @ccall libclang.clang_EnumDecl_isScoped(C::CXCursor)::Cuint
end

function clang_CXXMethod_isConst(C)
    @ccall libclang.clang_CXXMethod_isConst(C::CXCursor)::Cuint
end

function clang_getTemplateCursorKind(C)
    @ccall libclang.clang_getTemplateCursorKind(C::CXCursor)::CXCursorKind
end

function clang_getSpecializedCursorTemplate(C)
    @ccall libclang.clang_getSpecializedCursorTemplate(C::CXCursor)::CXCursor
end

function clang_getCursorReferenceNameRange(C, NameFlags, PieceIndex)
    @ccall libclang.clang_getCursorReferenceNameRange(C::CXCursor, NameFlags::Cuint, PieceIndex::Cuint)::CXSourceRange
end

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
    int_data::NTuple{4, Cuint}
    ptr_data::Ptr{Cvoid}
end

function clang_getToken(TU, Location)
    @ccall libclang.clang_getToken(TU::CXTranslationUnit, Location::CXSourceLocation)::Ptr{CXToken}
end

function clang_getTokenKind(arg1)
    @ccall libclang.clang_getTokenKind(arg1::CXToken)::CXTokenKind
end

function clang_getTokenSpelling(arg1, arg2)
    @ccall libclang.clang_getTokenSpelling(arg1::CXTranslationUnit, arg2::CXToken)::CXString
end

function clang_getTokenLocation(arg1, arg2)
    @ccall libclang.clang_getTokenLocation(arg1::CXTranslationUnit, arg2::CXToken)::CXSourceLocation
end

function clang_getTokenExtent(arg1, arg2)
    @ccall libclang.clang_getTokenExtent(arg1::CXTranslationUnit, arg2::CXToken)::CXSourceRange
end

function clang_tokenize(TU, Range, Tokens, NumTokens)
    @ccall libclang.clang_tokenize(TU::CXTranslationUnit, Range::CXSourceRange, Tokens::Ptr{Ptr{CXToken}}, NumTokens::Ptr{Cuint})::Cvoid
end

function clang_annotateTokens(TU, Tokens, NumTokens, Cursors)
    @ccall libclang.clang_annotateTokens(TU::CXTranslationUnit, Tokens::Ptr{CXToken}, NumTokens::Cuint, Cursors::Ptr{CXCursor})::Cvoid
end

function clang_disposeTokens(TU, Tokens, NumTokens)
    @ccall libclang.clang_disposeTokens(TU::CXTranslationUnit, Tokens::Ptr{CXToken}, NumTokens::Cuint)::Cvoid
end

function clang_getCursorKindSpelling(Kind)
    @ccall libclang.clang_getCursorKindSpelling(Kind::CXCursorKind)::CXString
end

function clang_getDefinitionSpellingAndExtent(arg1, startBuf, endBuf, startLine, startColumn, endLine, endColumn)
    @ccall libclang.clang_getDefinitionSpellingAndExtent(arg1::CXCursor, startBuf::Ptr{Cstring}, endBuf::Ptr{Cstring}, startLine::Ptr{Cuint}, startColumn::Ptr{Cuint}, endLine::Ptr{Cuint}, endColumn::Ptr{Cuint})::Cvoid
end

function clang_enableStackTraces()
    @ccall libclang.clang_enableStackTraces()::Cvoid
end

function clang_executeOnThread(fn, user_data, stack_size)
    @ccall libclang.clang_executeOnThread(fn::Ptr{Cvoid}, user_data::Ptr{Cvoid}, stack_size::Cuint)::Cvoid
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

function clang_getCompletionChunkKind(completion_string, chunk_number)
    @ccall libclang.clang_getCompletionChunkKind(completion_string::CXCompletionString, chunk_number::Cuint)::CXCompletionChunkKind
end

function clang_getCompletionChunkText(completion_string, chunk_number)
    @ccall libclang.clang_getCompletionChunkText(completion_string::CXCompletionString, chunk_number::Cuint)::CXString
end

function clang_getCompletionChunkCompletionString(completion_string, chunk_number)
    @ccall libclang.clang_getCompletionChunkCompletionString(completion_string::CXCompletionString, chunk_number::Cuint)::CXCompletionString
end

function clang_getNumCompletionChunks(completion_string)
    @ccall libclang.clang_getNumCompletionChunks(completion_string::CXCompletionString)::Cuint
end

function clang_getCompletionPriority(completion_string)
    @ccall libclang.clang_getCompletionPriority(completion_string::CXCompletionString)::Cuint
end

function clang_getCompletionAvailability(completion_string)
    @ccall libclang.clang_getCompletionAvailability(completion_string::CXCompletionString)::CXAvailabilityKind
end

function clang_getCompletionNumAnnotations(completion_string)
    @ccall libclang.clang_getCompletionNumAnnotations(completion_string::CXCompletionString)::Cuint
end

function clang_getCompletionAnnotation(completion_string, annotation_number)
    @ccall libclang.clang_getCompletionAnnotation(completion_string::CXCompletionString, annotation_number::Cuint)::CXString
end

function clang_getCompletionParent(completion_string, kind)
    @ccall libclang.clang_getCompletionParent(completion_string::CXCompletionString, kind::Ptr{CXCursorKind})::CXString
end

function clang_getCompletionBriefComment(completion_string)
    @ccall libclang.clang_getCompletionBriefComment(completion_string::CXCompletionString)::CXString
end

function clang_getCursorCompletionString(cursor)
    @ccall libclang.clang_getCursorCompletionString(cursor::CXCursor)::CXCompletionString
end

struct CXCodeCompleteResults
    Results::Ptr{CXCompletionResult}
    NumResults::Cuint
end

function clang_getCompletionNumFixIts(results, completion_index)
    @ccall libclang.clang_getCompletionNumFixIts(results::Ptr{CXCodeCompleteResults}, completion_index::Cuint)::Cuint
end

function clang_getCompletionFixIt(results, completion_index, fixit_index, replacement_range)
    @ccall libclang.clang_getCompletionFixIt(results::Ptr{CXCodeCompleteResults}, completion_index::Cuint, fixit_index::Cuint, replacement_range::Ptr{CXSourceRange})::CXString
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

function clang_defaultCodeCompleteOptions()
    @ccall libclang.clang_defaultCodeCompleteOptions()::Cuint
end

function clang_codeCompleteAt(TU, complete_filename, complete_line, complete_column, unsaved_files, num_unsaved_files, options)
    @ccall libclang.clang_codeCompleteAt(TU::CXTranslationUnit, complete_filename::Cstring, complete_line::Cuint, complete_column::Cuint, unsaved_files::Ptr{CXUnsavedFile}, num_unsaved_files::Cuint, options::Cuint)::Ptr{CXCodeCompleteResults}
end

function clang_sortCodeCompletionResults(Results, NumResults)
    @ccall libclang.clang_sortCodeCompletionResults(Results::Ptr{CXCompletionResult}, NumResults::Cuint)::Cvoid
end

function clang_disposeCodeCompleteResults(Results)
    @ccall libclang.clang_disposeCodeCompleteResults(Results::Ptr{CXCodeCompleteResults})::Cvoid
end

function clang_codeCompleteGetNumDiagnostics(Results)
    @ccall libclang.clang_codeCompleteGetNumDiagnostics(Results::Ptr{CXCodeCompleteResults})::Cuint
end

function clang_codeCompleteGetDiagnostic(Results, Index)
    @ccall libclang.clang_codeCompleteGetDiagnostic(Results::Ptr{CXCodeCompleteResults}, Index::Cuint)::CXDiagnostic
end

function clang_codeCompleteGetContexts(Results)
    @ccall libclang.clang_codeCompleteGetContexts(Results::Ptr{CXCodeCompleteResults})::Culonglong
end

function clang_codeCompleteGetContainerKind(Results, IsIncomplete)
    @ccall libclang.clang_codeCompleteGetContainerKind(Results::Ptr{CXCodeCompleteResults}, IsIncomplete::Ptr{Cuint})::CXCursorKind
end

function clang_codeCompleteGetContainerUSR(Results)
    @ccall libclang.clang_codeCompleteGetContainerUSR(Results::Ptr{CXCodeCompleteResults})::CXString
end

function clang_codeCompleteGetObjCSelector(Results)
    @ccall libclang.clang_codeCompleteGetObjCSelector(Results::Ptr{CXCodeCompleteResults})::CXString
end

function clang_getClangVersion()
    @ccall libclang.clang_getClangVersion()::CXString
end

function clang_toggleCrashRecovery(isEnabled)
    @ccall libclang.clang_toggleCrashRecovery(isEnabled::Cuint)::Cvoid
end

# typedef void ( * CXInclusionVisitor ) ( CXFile included_file , CXSourceLocation * inclusion_stack , unsigned include_len , CXClientData client_data )
const CXInclusionVisitor = Ptr{Cvoid}

function clang_getInclusions(tu, visitor, client_data)
    @ccall libclang.clang_getInclusions(tu::CXTranslationUnit, visitor::CXInclusionVisitor, client_data::CXClientData)::Cvoid
end

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

function clang_Cursor_Evaluate(C)
    @ccall libclang.clang_Cursor_Evaluate(C::CXCursor)::CXEvalResult
end

function clang_EvalResult_getKind(E)
    @ccall libclang.clang_EvalResult_getKind(E::CXEvalResult)::CXEvalResultKind
end

function clang_EvalResult_getAsInt(E)
    @ccall libclang.clang_EvalResult_getAsInt(E::CXEvalResult)::Cint
end

function clang_EvalResult_getAsLongLong(E)
    @ccall libclang.clang_EvalResult_getAsLongLong(E::CXEvalResult)::Clonglong
end

function clang_EvalResult_isUnsignedInt(E)
    @ccall libclang.clang_EvalResult_isUnsignedInt(E::CXEvalResult)::Cuint
end

function clang_EvalResult_getAsUnsigned(E)
    @ccall libclang.clang_EvalResult_getAsUnsigned(E::CXEvalResult)::Culonglong
end

function clang_EvalResult_getAsDouble(E)
    @ccall libclang.clang_EvalResult_getAsDouble(E::CXEvalResult)::Cdouble
end

function clang_EvalResult_getAsStr(E)
    @ccall libclang.clang_EvalResult_getAsStr(E::CXEvalResult)::Cstring
end

function clang_EvalResult_dispose(E)
    @ccall libclang.clang_EvalResult_dispose(E::CXEvalResult)::Cvoid
end

const CXRemapping = Ptr{Cvoid}

function clang_getRemappings(path)
    @ccall libclang.clang_getRemappings(path::Cstring)::CXRemapping
end

function clang_getRemappingsFromFileList(filePaths, numFiles)
    @ccall libclang.clang_getRemappingsFromFileList(filePaths::Ptr{Cstring}, numFiles::Cuint)::CXRemapping
end

function clang_remap_getNumFiles(arg1)
    @ccall libclang.clang_remap_getNumFiles(arg1::CXRemapping)::Cuint
end

function clang_remap_getFilenames(arg1, index, original, transformed)
    @ccall libclang.clang_remap_getFilenames(arg1::CXRemapping, index::Cuint, original::Ptr{CXString}, transformed::Ptr{CXString})::Cvoid
end

function clang_remap_dispose(arg1)
    @ccall libclang.clang_remap_dispose(arg1::CXRemapping)::Cvoid
end

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

function clang_findReferencesInFile(cursor, file, visitor)
    @ccall libclang.clang_findReferencesInFile(cursor::CXCursor, file::CXFile, visitor::CXCursorAndRangeVisitor)::CXResult
end

function clang_findIncludesInFile(TU, file, visitor)
    @ccall libclang.clang_findIncludesInFile(TU::CXTranslationUnit, file::CXFile, visitor::CXCursorAndRangeVisitor)::CXResult
end

const CXIdxClientFile = Ptr{Cvoid}

const CXIdxClientEntity = Ptr{Cvoid}

const CXIdxClientContainer = Ptr{Cvoid}

const CXIdxClientASTFile = Ptr{Cvoid}

struct CXIdxLoc
    ptr_data::NTuple{2, Ptr{Cvoid}}
    int_data::Cuint
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
    numAttributes::Cuint
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
    numAttributes::Cuint
    flags::Cuint
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
    numProtocols::Cuint
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
    numBases::Cuint
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

function clang_index_isEntityObjCContainerKind(arg1)
    @ccall libclang.clang_index_isEntityObjCContainerKind(arg1::CXIdxEntityKind)::Cint
end

function clang_index_getObjCContainerDeclInfo(arg1)
    @ccall libclang.clang_index_getObjCContainerDeclInfo(arg1::Ptr{CXIdxDeclInfo})::Ptr{CXIdxObjCContainerDeclInfo}
end

function clang_index_getObjCInterfaceDeclInfo(arg1)
    @ccall libclang.clang_index_getObjCInterfaceDeclInfo(arg1::Ptr{CXIdxDeclInfo})::Ptr{CXIdxObjCInterfaceDeclInfo}
end

function clang_index_getObjCCategoryDeclInfo(arg1)
    @ccall libclang.clang_index_getObjCCategoryDeclInfo(arg1::Ptr{CXIdxDeclInfo})::Ptr{CXIdxObjCCategoryDeclInfo}
end

function clang_index_getObjCProtocolRefListInfo(arg1)
    @ccall libclang.clang_index_getObjCProtocolRefListInfo(arg1::Ptr{CXIdxDeclInfo})::Ptr{CXIdxObjCProtocolRefListInfo}
end

function clang_index_getObjCPropertyDeclInfo(arg1)
    @ccall libclang.clang_index_getObjCPropertyDeclInfo(arg1::Ptr{CXIdxDeclInfo})::Ptr{CXIdxObjCPropertyDeclInfo}
end

function clang_index_getIBOutletCollectionAttrInfo(arg1)
    @ccall libclang.clang_index_getIBOutletCollectionAttrInfo(arg1::Ptr{CXIdxAttrInfo})::Ptr{CXIdxIBOutletCollectionAttrInfo}
end

function clang_index_getCXXClassDeclInfo(arg1)
    @ccall libclang.clang_index_getCXXClassDeclInfo(arg1::Ptr{CXIdxDeclInfo})::Ptr{CXIdxCXXClassDeclInfo}
end

function clang_index_getClientContainer(arg1)
    @ccall libclang.clang_index_getClientContainer(arg1::Ptr{CXIdxContainerInfo})::CXIdxClientContainer
end

function clang_index_setClientContainer(arg1, arg2)
    @ccall libclang.clang_index_setClientContainer(arg1::Ptr{CXIdxContainerInfo}, arg2::CXIdxClientContainer)::Cvoid
end

function clang_index_getClientEntity(arg1)
    @ccall libclang.clang_index_getClientEntity(arg1::Ptr{CXIdxEntityInfo})::CXIdxClientEntity
end

function clang_index_setClientEntity(arg1, arg2)
    @ccall libclang.clang_index_setClientEntity(arg1::Ptr{CXIdxEntityInfo}, arg2::CXIdxClientEntity)::Cvoid
end

const CXIndexAction = Ptr{Cvoid}

function clang_IndexAction_create(CIdx)
    @ccall libclang.clang_IndexAction_create(CIdx::CXIndex)::CXIndexAction
end

function clang_IndexAction_dispose(arg1)
    @ccall libclang.clang_IndexAction_dispose(arg1::CXIndexAction)::Cvoid
end

@cenum CXIndexOptFlags::UInt32 begin
    CXIndexOpt_None = 0
    CXIndexOpt_SuppressRedundantRefs = 1
    CXIndexOpt_IndexFunctionLocalSymbols = 2
    CXIndexOpt_IndexImplicitTemplateInstantiations = 4
    CXIndexOpt_SuppressWarnings = 8
    CXIndexOpt_SkipParsedBodiesInSession = 16
end

function clang_indexSourceFile(arg1, client_data, index_callbacks, index_callbacks_size, index_options, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, out_TU, TU_options)
    @ccall libclang.clang_indexSourceFile(arg1::CXIndexAction, client_data::CXClientData, index_callbacks::Ptr{IndexerCallbacks}, index_callbacks_size::Cuint, index_options::Cuint, source_filename::Cstring, command_line_args::Ptr{Cstring}, num_command_line_args::Cint, unsaved_files::Ptr{CXUnsavedFile}, num_unsaved_files::Cuint, out_TU::Ptr{CXTranslationUnit}, TU_options::Cuint)::Cint
end

function clang_indexSourceFileFullArgv(arg1, client_data, index_callbacks, index_callbacks_size, index_options, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, out_TU, TU_options)
    @ccall libclang.clang_indexSourceFileFullArgv(arg1::CXIndexAction, client_data::CXClientData, index_callbacks::Ptr{IndexerCallbacks}, index_callbacks_size::Cuint, index_options::Cuint, source_filename::Cstring, command_line_args::Ptr{Cstring}, num_command_line_args::Cint, unsaved_files::Ptr{CXUnsavedFile}, num_unsaved_files::Cuint, out_TU::Ptr{CXTranslationUnit}, TU_options::Cuint)::Cint
end

function clang_indexTranslationUnit(arg1, client_data, index_callbacks, index_callbacks_size, index_options, arg6)
    @ccall libclang.clang_indexTranslationUnit(arg1::CXIndexAction, client_data::CXClientData, index_callbacks::Ptr{IndexerCallbacks}, index_callbacks_size::Cuint, index_options::Cuint, arg6::CXTranslationUnit)::Cint
end

function clang_indexLoc_getFileLocation(loc, indexFile, file, line, column, offset)
    @ccall libclang.clang_indexLoc_getFileLocation(loc::CXIdxLoc, indexFile::Ptr{CXIdxClientFile}, file::Ptr{CXFile}, line::Ptr{Cuint}, column::Ptr{Cuint}, offset::Ptr{Cuint})::Cvoid
end

function clang_indexLoc_getCXSourceLocation(loc)
    @ccall libclang.clang_indexLoc_getCXSourceLocation(loc::CXIdxLoc)::CXSourceLocation
end

# typedef enum CXVisitorResult ( * CXFieldVisitor ) ( CXCursor C , CXClientData client_data )
const CXFieldVisitor = Ptr{Cvoid}

function clang_Type_visitFields(T, visitor, client_data)
    @ccall libclang.clang_Type_visitFields(T::CXType, visitor::CXFieldVisitor, client_data::CXClientData)::Cuint
end

struct CXComment
    ASTNode::Ptr{Cvoid}
    TranslationUnit::CXTranslationUnit
end

function clang_Cursor_getParsedComment(C)
    @ccall libclang.clang_Cursor_getParsedComment(C::CXCursor)::CXComment
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
    CXCommentInlineCommandRenderKind_Anchor = 4
end

@cenum CXCommentParamPassDirection::UInt32 begin
    CXCommentParamPassDirection_In = 0
    CXCommentParamPassDirection_Out = 1
    CXCommentParamPassDirection_InOut = 2
end

function clang_Comment_getKind(Comment)
    @ccall libclang.clang_Comment_getKind(Comment::CXComment)::CXCommentKind
end

function clang_Comment_getNumChildren(Comment)
    @ccall libclang.clang_Comment_getNumChildren(Comment::CXComment)::Cuint
end

function clang_Comment_getChild(Comment, ChildIdx)
    @ccall libclang.clang_Comment_getChild(Comment::CXComment, ChildIdx::Cuint)::CXComment
end

function clang_Comment_isWhitespace(Comment)
    @ccall libclang.clang_Comment_isWhitespace(Comment::CXComment)::Cuint
end

function clang_InlineContentComment_hasTrailingNewline(Comment)
    @ccall libclang.clang_InlineContentComment_hasTrailingNewline(Comment::CXComment)::Cuint
end

function clang_TextComment_getText(Comment)
    @ccall libclang.clang_TextComment_getText(Comment::CXComment)::CXString
end

function clang_InlineCommandComment_getCommandName(Comment)
    @ccall libclang.clang_InlineCommandComment_getCommandName(Comment::CXComment)::CXString
end

function clang_InlineCommandComment_getRenderKind(Comment)
    @ccall libclang.clang_InlineCommandComment_getRenderKind(Comment::CXComment)::CXCommentInlineCommandRenderKind
end

function clang_InlineCommandComment_getNumArgs(Comment)
    @ccall libclang.clang_InlineCommandComment_getNumArgs(Comment::CXComment)::Cuint
end

function clang_InlineCommandComment_getArgText(Comment, ArgIdx)
    @ccall libclang.clang_InlineCommandComment_getArgText(Comment::CXComment, ArgIdx::Cuint)::CXString
end

function clang_HTMLTagComment_getTagName(Comment)
    @ccall libclang.clang_HTMLTagComment_getTagName(Comment::CXComment)::CXString
end

function clang_HTMLStartTagComment_isSelfClosing(Comment)
    @ccall libclang.clang_HTMLStartTagComment_isSelfClosing(Comment::CXComment)::Cuint
end

function clang_HTMLStartTag_getNumAttrs(Comment)
    @ccall libclang.clang_HTMLStartTag_getNumAttrs(Comment::CXComment)::Cuint
end

function clang_HTMLStartTag_getAttrName(Comment, AttrIdx)
    @ccall libclang.clang_HTMLStartTag_getAttrName(Comment::CXComment, AttrIdx::Cuint)::CXString
end

function clang_HTMLStartTag_getAttrValue(Comment, AttrIdx)
    @ccall libclang.clang_HTMLStartTag_getAttrValue(Comment::CXComment, AttrIdx::Cuint)::CXString
end

function clang_BlockCommandComment_getCommandName(Comment)
    @ccall libclang.clang_BlockCommandComment_getCommandName(Comment::CXComment)::CXString
end

function clang_BlockCommandComment_getNumArgs(Comment)
    @ccall libclang.clang_BlockCommandComment_getNumArgs(Comment::CXComment)::Cuint
end

function clang_BlockCommandComment_getArgText(Comment, ArgIdx)
    @ccall libclang.clang_BlockCommandComment_getArgText(Comment::CXComment, ArgIdx::Cuint)::CXString
end

function clang_BlockCommandComment_getParagraph(Comment)
    @ccall libclang.clang_BlockCommandComment_getParagraph(Comment::CXComment)::CXComment
end

function clang_ParamCommandComment_getParamName(Comment)
    @ccall libclang.clang_ParamCommandComment_getParamName(Comment::CXComment)::CXString
end

function clang_ParamCommandComment_isParamIndexValid(Comment)
    @ccall libclang.clang_ParamCommandComment_isParamIndexValid(Comment::CXComment)::Cuint
end

function clang_ParamCommandComment_getParamIndex(Comment)
    @ccall libclang.clang_ParamCommandComment_getParamIndex(Comment::CXComment)::Cuint
end

function clang_ParamCommandComment_isDirectionExplicit(Comment)
    @ccall libclang.clang_ParamCommandComment_isDirectionExplicit(Comment::CXComment)::Cuint
end

function clang_ParamCommandComment_getDirection(Comment)
    @ccall libclang.clang_ParamCommandComment_getDirection(Comment::CXComment)::CXCommentParamPassDirection
end

function clang_TParamCommandComment_getParamName(Comment)
    @ccall libclang.clang_TParamCommandComment_getParamName(Comment::CXComment)::CXString
end

function clang_TParamCommandComment_isParamPositionValid(Comment)
    @ccall libclang.clang_TParamCommandComment_isParamPositionValid(Comment::CXComment)::Cuint
end

function clang_TParamCommandComment_getDepth(Comment)
    @ccall libclang.clang_TParamCommandComment_getDepth(Comment::CXComment)::Cuint
end

function clang_TParamCommandComment_getIndex(Comment, Depth)
    @ccall libclang.clang_TParamCommandComment_getIndex(Comment::CXComment, Depth::Cuint)::Cuint
end

function clang_VerbatimBlockLineComment_getText(Comment)
    @ccall libclang.clang_VerbatimBlockLineComment_getText(Comment::CXComment)::CXString
end

function clang_VerbatimLineComment_getText(Comment)
    @ccall libclang.clang_VerbatimLineComment_getText(Comment::CXComment)::CXString
end

function clang_HTMLTagComment_getAsString(Comment)
    @ccall libclang.clang_HTMLTagComment_getAsString(Comment::CXComment)::CXString
end

function clang_FullComment_getAsHTML(Comment)
    @ccall libclang.clang_FullComment_getAsHTML(Comment::CXComment)::CXString
end

function clang_FullComment_getAsXML(Comment)
    @ccall libclang.clang_FullComment_getAsXML(Comment::CXComment)::CXString
end

const CXCompilationDatabase = Ptr{Cvoid}

const CXCompileCommands = Ptr{Cvoid}

const CXCompileCommand = Ptr{Cvoid}

@cenum CXCompilationDatabase_Error::UInt32 begin
    CXCompilationDatabase_NoError = 0
    CXCompilationDatabase_CanNotLoadDatabase = 1
end

function clang_CompilationDatabase_fromDirectory(BuildDir, ErrorCode)
    @ccall libclang.clang_CompilationDatabase_fromDirectory(BuildDir::Cstring, ErrorCode::Ptr{CXCompilationDatabase_Error})::CXCompilationDatabase
end

function clang_CompilationDatabase_dispose(arg1)
    @ccall libclang.clang_CompilationDatabase_dispose(arg1::CXCompilationDatabase)::Cvoid
end

function clang_CompilationDatabase_getCompileCommands(arg1, CompleteFileName)
    @ccall libclang.clang_CompilationDatabase_getCompileCommands(arg1::CXCompilationDatabase, CompleteFileName::Cstring)::CXCompileCommands
end

function clang_CompilationDatabase_getAllCompileCommands(arg1)
    @ccall libclang.clang_CompilationDatabase_getAllCompileCommands(arg1::CXCompilationDatabase)::CXCompileCommands
end

function clang_CompileCommands_dispose(arg1)
    @ccall libclang.clang_CompileCommands_dispose(arg1::CXCompileCommands)::Cvoid
end

function clang_CompileCommands_getSize(arg1)
    @ccall libclang.clang_CompileCommands_getSize(arg1::CXCompileCommands)::Cuint
end

function clang_CompileCommands_getCommand(arg1, I)
    @ccall libclang.clang_CompileCommands_getCommand(arg1::CXCompileCommands, I::Cuint)::CXCompileCommand
end

function clang_CompileCommand_getDirectory(arg1)
    @ccall libclang.clang_CompileCommand_getDirectory(arg1::CXCompileCommand)::CXString
end

function clang_CompileCommand_getFilename(arg1)
    @ccall libclang.clang_CompileCommand_getFilename(arg1::CXCompileCommand)::CXString
end

function clang_CompileCommand_getNumArgs(arg1)
    @ccall libclang.clang_CompileCommand_getNumArgs(arg1::CXCompileCommand)::Cuint
end

function clang_CompileCommand_getArg(arg1, I)
    @ccall libclang.clang_CompileCommand_getArg(arg1::CXCompileCommand, I::Cuint)::CXString
end

function clang_CompileCommand_getNumMappedSources(arg1)
    @ccall libclang.clang_CompileCommand_getNumMappedSources(arg1::CXCompileCommand)::Cuint
end

function clang_CompileCommand_getMappedSourcePath(arg1, I)
    @warn "`clang_CompileCommand_getMappedSourcePath` Left here for backward compatibility.\nNo mapped sources exists in the C++ backend anymore.\nThis function just return Null `CXString`.\nSee:\n- [Remove unused CompilationDatabase::MappedSources](https://reviews.llvm.org/D32351)\n"
    @ccall libclang.clang_CompileCommand_getMappedSourcePath(arg1::CXCompileCommand, I::Cuint)::CXString
end

function clang_CompileCommand_getMappedSourceContent(arg1, I)
    @warn "`clang_CompileCommand_getMappedSourceContent` Left here for backward compatibility.\nNo mapped sources exists in the C++ backend anymore.\nThis function just return Null `CXString`.\nSee:\n- [Remove unused CompilationDatabase::MappedSources](https://reviews.llvm.org/D32351)\n"
    @ccall libclang.clang_CompileCommand_getMappedSourceContent(arg1::CXCompileCommand, I::Cuint)::CXString
end

function clang_install_aborting_llvm_fatal_error_handler()
    @ccall libclang.clang_install_aborting_llvm_fatal_error_handler()::Cvoid
end

function clang_uninstall_llvm_fatal_error_handler()
    @ccall libclang.clang_uninstall_llvm_fatal_error_handler()::Cvoid
end

const CINDEX_VERSION_MAJOR = 0

const CINDEX_VERSION_MINOR = 60

CINDEX_VERSION_ENCODE(major, minor) = major * 10000 + minor * 1

# exports
const PREFIXES = ["CX", "clang_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

end # module
