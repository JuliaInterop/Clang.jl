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

mutable struct CXString
    data::Ptr{Cvoid}
    private_flags::Cuint
end

mutable struct CXStringSet
    Strings::Ptr{CXString}
    Count::Cuint
end

function clang_getCString(string)
    ccall((:clang_getCString, libclang), Cstring, (CXString,), string)
end

function clang_disposeString(string)
    ccall((:clang_disposeString, libclang), Cvoid, (CXString,), string)
end

function clang_disposeStringSet(set)
    ccall((:clang_disposeStringSet, libclang), Cvoid, (Ptr{CXStringSet},), set)
end

function clang_getBuildSessionTimestamp()
    ccall((:clang_getBuildSessionTimestamp, libclang), Culonglong, ())
end

mutable struct CXVirtualFileOverlayImpl end

const CXVirtualFileOverlay = Ptr{CXVirtualFileOverlayImpl}

function clang_VirtualFileOverlay_create(options)
    ccall((:clang_VirtualFileOverlay_create, libclang), CXVirtualFileOverlay, (Cuint,), options)
end

function clang_VirtualFileOverlay_addFileMapping(arg1, virtualPath, realPath)
    ccall((:clang_VirtualFileOverlay_addFileMapping, libclang), CXErrorCode, (CXVirtualFileOverlay, Cstring, Cstring), arg1, virtualPath, realPath)
end

function clang_VirtualFileOverlay_setCaseSensitivity(arg1, caseSensitive)
    ccall((:clang_VirtualFileOverlay_setCaseSensitivity, libclang), CXErrorCode, (CXVirtualFileOverlay, Cint), arg1, caseSensitive)
end

function clang_VirtualFileOverlay_writeToBuffer(arg1, options, out_buffer_ptr, out_buffer_size)
    ccall((:clang_VirtualFileOverlay_writeToBuffer, libclang), CXErrorCode, (CXVirtualFileOverlay, Cuint, Ptr{Cstring}, Ptr{Cuint}), arg1, options, out_buffer_ptr, out_buffer_size)
end

function clang_free(buffer)
    ccall((:clang_free, libclang), Cvoid, (Ptr{Cvoid},), buffer)
end

function clang_VirtualFileOverlay_dispose(arg1)
    ccall((:clang_VirtualFileOverlay_dispose, libclang), Cvoid, (CXVirtualFileOverlay,), arg1)
end

mutable struct CXModuleMapDescriptorImpl end

const CXModuleMapDescriptor = Ptr{CXModuleMapDescriptorImpl}

function clang_ModuleMapDescriptor_create(options)
    ccall((:clang_ModuleMapDescriptor_create, libclang), CXModuleMapDescriptor, (Cuint,), options)
end

function clang_ModuleMapDescriptor_setFrameworkModuleName(arg1, name)
    ccall((:clang_ModuleMapDescriptor_setFrameworkModuleName, libclang), CXErrorCode, (CXModuleMapDescriptor, Cstring), arg1, name)
end

function clang_ModuleMapDescriptor_setUmbrellaHeader(arg1, name)
    ccall((:clang_ModuleMapDescriptor_setUmbrellaHeader, libclang), CXErrorCode, (CXModuleMapDescriptor, Cstring), arg1, name)
end

function clang_ModuleMapDescriptor_writeToBuffer(arg1, options, out_buffer_ptr, out_buffer_size)
    ccall((:clang_ModuleMapDescriptor_writeToBuffer, libclang), CXErrorCode, (CXModuleMapDescriptor, Cuint, Ptr{Cstring}, Ptr{Cuint}), arg1, options, out_buffer_ptr, out_buffer_size)
end

function clang_ModuleMapDescriptor_dispose(arg1)
    ccall((:clang_ModuleMapDescriptor_dispose, libclang), Cvoid, (CXModuleMapDescriptor,), arg1)
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
    ccall((:clang_createIndex, libclang), CXIndex, (Cint, Cint), excludeDeclarationsFromPCH, displayDiagnostics)
end

function clang_disposeIndex(index)
    ccall((:clang_disposeIndex, libclang), Cvoid, (CXIndex,), index)
end

@cenum CXGlobalOptFlags::UInt32 begin
    CXGlobalOpt_None = 0
    CXGlobalOpt_ThreadBackgroundPriorityForIndexing = 1
    CXGlobalOpt_ThreadBackgroundPriorityForEditing = 2
    CXGlobalOpt_ThreadBackgroundPriorityForAll = 3
end

function clang_CXIndex_setGlobalOptions(arg1, options)
    ccall((:clang_CXIndex_setGlobalOptions, libclang), Cvoid, (CXIndex, Cuint), arg1, options)
end

function clang_CXIndex_getGlobalOptions(arg1)
    ccall((:clang_CXIndex_getGlobalOptions, libclang), Cuint, (CXIndex,), arg1)
end

function clang_CXIndex_setInvocationEmissionPathOption(arg1, Path)
    ccall((:clang_CXIndex_setInvocationEmissionPathOption, libclang), Cvoid, (CXIndex, Cstring), arg1, Path)
end

const CXFile = Ptr{Cvoid}

function clang_getFileName(SFile)
    ccall((:clang_getFileName, libclang), CXString, (CXFile,), SFile)
end

function clang_getFileTime(SFile)
    ccall((:clang_getFileTime, libclang), Ctime_t, (CXFile,), SFile)
end

mutable struct CXFileUniqueID
    data::NTuple{3, Culonglong}
end

function clang_getFileUniqueID(file, outID)
    ccall((:clang_getFileUniqueID, libclang), Cint, (CXFile, Ptr{CXFileUniqueID}), file, outID)
end

function clang_isFileMultipleIncludeGuarded(tu, file)
    ccall((:clang_isFileMultipleIncludeGuarded, libclang), Cuint, (CXTranslationUnit, CXFile), tu, file)
end

function clang_getFile(tu, file_name)
    ccall((:clang_getFile, libclang), CXFile, (CXTranslationUnit, Cstring), tu, file_name)
end

function clang_getFileContents(tu, file, size)
    ccall((:clang_getFileContents, libclang), Cstring, (CXTranslationUnit, CXFile, Ptr{Csize_t}), tu, file, size)
end

function clang_File_isEqual(file1, file2)
    ccall((:clang_File_isEqual, libclang), Cint, (CXFile, CXFile), file1, file2)
end

function clang_File_tryGetRealPathName(file)
    ccall((:clang_File_tryGetRealPathName, libclang), CXString, (CXFile,), file)
end

mutable struct CXSourceLocation
    ptr_data::NTuple{2, Ptr{Cvoid}}
    int_data::Cuint
end

mutable struct CXSourceRange
    ptr_data::NTuple{2, Ptr{Cvoid}}
    begin_int_data::Cuint
    end_int_data::Cuint
end

function clang_getNullLocation()
    ccall((:clang_getNullLocation, libclang), CXSourceLocation, ())
end

function clang_equalLocations(loc1, loc2)
    ccall((:clang_equalLocations, libclang), Cuint, (CXSourceLocation, CXSourceLocation), loc1, loc2)
end

function clang_getLocation(tu, file, line, column)
    ccall((:clang_getLocation, libclang), CXSourceLocation, (CXTranslationUnit, CXFile, Cuint, Cuint), tu, file, line, column)
end

function clang_getLocationForOffset(tu, file, offset)
    ccall((:clang_getLocationForOffset, libclang), CXSourceLocation, (CXTranslationUnit, CXFile, Cuint), tu, file, offset)
end

function clang_Location_isInSystemHeader(location)
    ccall((:clang_Location_isInSystemHeader, libclang), Cint, (CXSourceLocation,), location)
end

function clang_Location_isFromMainFile(location)
    ccall((:clang_Location_isFromMainFile, libclang), Cint, (CXSourceLocation,), location)
end

function clang_getNullRange()
    ccall((:clang_getNullRange, libclang), CXSourceRange, ())
end

function clang_getRange(_begin, _end)
    ccall((:clang_getRange, libclang), CXSourceRange, (CXSourceLocation, CXSourceLocation), _begin, _end)
end

function clang_equalRanges(range1, range2)
    ccall((:clang_equalRanges, libclang), Cuint, (CXSourceRange, CXSourceRange), range1, range2)
end

function clang_Range_isNull(range)
    ccall((:clang_Range_isNull, libclang), Cint, (CXSourceRange,), range)
end

function clang_getExpansionLocation(location, file, line, column, offset)
    ccall((:clang_getExpansionLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXFile}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), location, file, line, column, offset)
end

function clang_getPresumedLocation(location, filename, line, column)
    ccall((:clang_getPresumedLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXString}, Ptr{Cuint}, Ptr{Cuint}), location, filename, line, column)
end

function clang_getInstantiationLocation(location, file, line, column, offset)
    ccall((:clang_getInstantiationLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXFile}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), location, file, line, column, offset)
end

function clang_getSpellingLocation(location, file, line, column, offset)
    ccall((:clang_getSpellingLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXFile}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), location, file, line, column, offset)
end

function clang_getFileLocation(location, file, line, column, offset)
    ccall((:clang_getFileLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXFile}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), location, file, line, column, offset)
end

function clang_getRangeStart(range)
    ccall((:clang_getRangeStart, libclang), CXSourceLocation, (CXSourceRange,), range)
end

function clang_getRangeEnd(range)
    ccall((:clang_getRangeEnd, libclang), CXSourceLocation, (CXSourceRange,), range)
end

mutable struct CXSourceRangeList
    count::Cuint
    ranges::Ptr{CXSourceRange}
end

function clang_getSkippedRanges(tu, file)
    ccall((:clang_getSkippedRanges, libclang), Ptr{CXSourceRangeList}, (CXTranslationUnit, CXFile), tu, file)
end

function clang_getAllSkippedRanges(tu)
    ccall((:clang_getAllSkippedRanges, libclang), Ptr{CXSourceRangeList}, (CXTranslationUnit,), tu)
end

function clang_disposeSourceRangeList(ranges)
    ccall((:clang_disposeSourceRangeList, libclang), Cvoid, (Ptr{CXSourceRangeList},), ranges)
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
    ccall((:clang_getNumDiagnosticsInSet, libclang), Cuint, (CXDiagnosticSet,), Diags)
end

function clang_getDiagnosticInSet(Diags, Index)
    ccall((:clang_getDiagnosticInSet, libclang), CXDiagnostic, (CXDiagnosticSet, Cuint), Diags, Index)
end

@cenum CXLoadDiag_Error::UInt32 begin
    CXLoadDiag_None = 0
    CXLoadDiag_Unknown = 1
    CXLoadDiag_CannotLoad = 2
    CXLoadDiag_InvalidFile = 3
end

function clang_loadDiagnostics(file, error, errorString)
    ccall((:clang_loadDiagnostics, libclang), CXDiagnosticSet, (Cstring, Ptr{CXLoadDiag_Error}, Ptr{CXString}), file, error, errorString)
end

function clang_disposeDiagnosticSet(Diags)
    ccall((:clang_disposeDiagnosticSet, libclang), Cvoid, (CXDiagnosticSet,), Diags)
end

function clang_getChildDiagnostics(D)
    ccall((:clang_getChildDiagnostics, libclang), CXDiagnosticSet, (CXDiagnostic,), D)
end

function clang_getNumDiagnostics(Unit)
    ccall((:clang_getNumDiagnostics, libclang), Cuint, (CXTranslationUnit,), Unit)
end

function clang_getDiagnostic(Unit, Index)
    ccall((:clang_getDiagnostic, libclang), CXDiagnostic, (CXTranslationUnit, Cuint), Unit, Index)
end

function clang_getDiagnosticSetFromTU(Unit)
    ccall((:clang_getDiagnosticSetFromTU, libclang), CXDiagnosticSet, (CXTranslationUnit,), Unit)
end

function clang_disposeDiagnostic(Diagnostic)
    ccall((:clang_disposeDiagnostic, libclang), Cvoid, (CXDiagnostic,), Diagnostic)
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
    ccall((:clang_formatDiagnostic, libclang), CXString, (CXDiagnostic, Cuint), Diagnostic, Options)
end

function clang_defaultDiagnosticDisplayOptions()
    ccall((:clang_defaultDiagnosticDisplayOptions, libclang), Cuint, ())
end

function clang_getDiagnosticSeverity(arg1)
    ccall((:clang_getDiagnosticSeverity, libclang), CXDiagnosticSeverity, (CXDiagnostic,), arg1)
end

function clang_getDiagnosticLocation(arg1)
    ccall((:clang_getDiagnosticLocation, libclang), CXSourceLocation, (CXDiagnostic,), arg1)
end

function clang_getDiagnosticSpelling(arg1)
    ccall((:clang_getDiagnosticSpelling, libclang), CXString, (CXDiagnostic,), arg1)
end

function clang_getDiagnosticOption(Diag, Disable)
    ccall((:clang_getDiagnosticOption, libclang), CXString, (CXDiagnostic, Ptr{CXString}), Diag, Disable)
end

function clang_getDiagnosticCategory(arg1)
    ccall((:clang_getDiagnosticCategory, libclang), Cuint, (CXDiagnostic,), arg1)
end

function clang_getDiagnosticCategoryName(Category)
    ccall((:clang_getDiagnosticCategoryName, libclang), CXString, (Cuint,), Category)
end

function clang_getDiagnosticCategoryText(arg1)
    ccall((:clang_getDiagnosticCategoryText, libclang), CXString, (CXDiagnostic,), arg1)
end

function clang_getDiagnosticNumRanges(arg1)
    ccall((:clang_getDiagnosticNumRanges, libclang), Cuint, (CXDiagnostic,), arg1)
end

function clang_getDiagnosticRange(Diagnostic, Range)
    ccall((:clang_getDiagnosticRange, libclang), CXSourceRange, (CXDiagnostic, Cuint), Diagnostic, Range)
end

function clang_getDiagnosticNumFixIts(Diagnostic)
    ccall((:clang_getDiagnosticNumFixIts, libclang), Cuint, (CXDiagnostic,), Diagnostic)
end

function clang_getDiagnosticFixIt(Diagnostic, FixIt, ReplacementRange)
    ccall((:clang_getDiagnosticFixIt, libclang), CXString, (CXDiagnostic, Cuint, Ptr{CXSourceRange}), Diagnostic, FixIt, ReplacementRange)
end

function clang_getTranslationUnitSpelling(CTUnit)
    ccall((:clang_getTranslationUnitSpelling, libclang), CXString, (CXTranslationUnit,), CTUnit)
end

function clang_createTranslationUnitFromSourceFile(CIdx, source_filename, num_clang_command_line_args, clang_command_line_args, num_unsaved_files, unsaved_files)
    ccall((:clang_createTranslationUnitFromSourceFile, libclang), CXTranslationUnit, (CXIndex, Cstring, Cint, Ptr{Cstring}, Cuint, Ptr{CXUnsavedFile}), CIdx, source_filename, num_clang_command_line_args, clang_command_line_args, num_unsaved_files, unsaved_files)
end

function clang_createTranslationUnit(CIdx, ast_filename)
    ccall((:clang_createTranslationUnit, libclang), CXTranslationUnit, (CXIndex, Cstring), CIdx, ast_filename)
end

function clang_createTranslationUnit2(CIdx, ast_filename, out_TU)
    ccall((:clang_createTranslationUnit2, libclang), CXErrorCode, (CXIndex, Cstring, Ptr{CXTranslationUnit}), CIdx, ast_filename, out_TU)
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
    ccall((:clang_defaultEditingTranslationUnitOptions, libclang), Cuint, ())
end

function clang_parseTranslationUnit(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options)
    ccall((:clang_parseTranslationUnit, libclang), CXTranslationUnit, (CXIndex, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, Cuint, Cuint), CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options)
end

function clang_parseTranslationUnit2(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
    ccall((:clang_parseTranslationUnit2, libclang), CXErrorCode, (CXIndex, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, Cuint, Cuint, Ptr{CXTranslationUnit}), CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
end

function clang_parseTranslationUnit2FullArgv(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
    ccall((:clang_parseTranslationUnit2FullArgv, libclang), CXErrorCode, (CXIndex, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, Cuint, Cuint, Ptr{CXTranslationUnit}), CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
end

@cenum CXSaveTranslationUnit_Flags::UInt32 begin
    CXSaveTranslationUnit_None = 0
end

function clang_defaultSaveOptions(TU)
    ccall((:clang_defaultSaveOptions, libclang), Cuint, (CXTranslationUnit,), TU)
end

@cenum CXSaveError::UInt32 begin
    CXSaveError_None = 0
    CXSaveError_Unknown = 1
    CXSaveError_TranslationErrors = 2
    CXSaveError_InvalidTU = 3
end

function clang_saveTranslationUnit(TU, FileName, options)
    ccall((:clang_saveTranslationUnit, libclang), Cint, (CXTranslationUnit, Cstring, Cuint), TU, FileName, options)
end

function clang_suspendTranslationUnit(arg1)
    ccall((:clang_suspendTranslationUnit, libclang), Cuint, (CXTranslationUnit,), arg1)
end

function clang_disposeTranslationUnit(arg1)
    ccall((:clang_disposeTranslationUnit, libclang), Cvoid, (CXTranslationUnit,), arg1)
end

@cenum CXReparse_Flags::UInt32 begin
    CXReparse_None = 0
end

function clang_defaultReparseOptions(TU)
    ccall((:clang_defaultReparseOptions, libclang), Cuint, (CXTranslationUnit,), TU)
end

function clang_reparseTranslationUnit(TU, num_unsaved_files, unsaved_files, options)
    ccall((:clang_reparseTranslationUnit, libclang), Cint, (CXTranslationUnit, Cuint, Ptr{CXUnsavedFile}, Cuint), TU, num_unsaved_files, unsaved_files, options)
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
    ccall((:clang_getTUResourceUsageName, libclang), Cstring, (CXTUResourceUsageKind,), kind)
end

struct CXTUResourceUsageEntry
    kind::CXTUResourceUsageKind
    amount::Culong
end

mutable struct CXTUResourceUsage
    data::Ptr{Cvoid}
    numEntries::Cuint
    entries::Ptr{CXTUResourceUsageEntry}
end

function clang_getCXTUResourceUsage(TU)
    ccall((:clang_getCXTUResourceUsage, libclang), CXTUResourceUsage, (CXTranslationUnit,), TU)
end

function clang_disposeCXTUResourceUsage(usage)
    ccall((:clang_disposeCXTUResourceUsage, libclang), Cvoid, (CXTUResourceUsage,), usage)
end

function clang_getTranslationUnitTargetInfo(CTUnit)
    ccall((:clang_getTranslationUnitTargetInfo, libclang), CXTargetInfo, (CXTranslationUnit,), CTUnit)
end

function clang_TargetInfo_dispose(Info)
    ccall((:clang_TargetInfo_dispose, libclang), Cvoid, (CXTargetInfo,), Info)
end

function clang_TargetInfo_getTriple(Info)
    ccall((:clang_TargetInfo_getTriple, libclang), CXString, (CXTargetInfo,), Info)
end

function clang_TargetInfo_getPointerWidth(Info)
    ccall((:clang_TargetInfo_getPointerWidth, libclang), Cint, (CXTargetInfo,), Info)
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

mutable struct CXCursor
    kind::CXCursorKind
    xdata::Cint
    data::NTuple{3, Ptr{Cvoid}}
end

function clang_getNullCursor()
    ccall((:clang_getNullCursor, libclang), CXCursor, ())
end

function clang_getTranslationUnitCursor(arg1)
    ccall((:clang_getTranslationUnitCursor, libclang), CXCursor, (CXTranslationUnit,), arg1)
end

function clang_equalCursors(arg1, arg2)
    ccall((:clang_equalCursors, libclang), Cuint, (CXCursor, CXCursor), arg1, arg2)
end

function clang_Cursor_isNull(cursor)
    ccall((:clang_Cursor_isNull, libclang), Cint, (CXCursor,), cursor)
end

function clang_hashCursor(arg1)
    ccall((:clang_hashCursor, libclang), Cuint, (CXCursor,), arg1)
end

function clang_getCursorKind(arg1)
    ccall((:clang_getCursorKind, libclang), CXCursorKind, (CXCursor,), arg1)
end

function clang_isDeclaration(arg1)
    ccall((:clang_isDeclaration, libclang), Cuint, (CXCursorKind,), arg1)
end

function clang_isInvalidDeclaration(arg1)
    ccall((:clang_isInvalidDeclaration, libclang), Cuint, (CXCursor,), arg1)
end

function clang_isReference(arg1)
    ccall((:clang_isReference, libclang), Cuint, (CXCursorKind,), arg1)
end

function clang_isExpression(arg1)
    ccall((:clang_isExpression, libclang), Cuint, (CXCursorKind,), arg1)
end

function clang_isStatement(arg1)
    ccall((:clang_isStatement, libclang), Cuint, (CXCursorKind,), arg1)
end

function clang_isAttribute(arg1)
    ccall((:clang_isAttribute, libclang), Cuint, (CXCursorKind,), arg1)
end

function clang_Cursor_hasAttrs(C)
    ccall((:clang_Cursor_hasAttrs, libclang), Cuint, (CXCursor,), C)
end

function clang_isInvalid(arg1)
    ccall((:clang_isInvalid, libclang), Cuint, (CXCursorKind,), arg1)
end

function clang_isTranslationUnit(arg1)
    ccall((:clang_isTranslationUnit, libclang), Cuint, (CXCursorKind,), arg1)
end

function clang_isPreprocessing(arg1)
    ccall((:clang_isPreprocessing, libclang), Cuint, (CXCursorKind,), arg1)
end

function clang_isUnexposed(arg1)
    ccall((:clang_isUnexposed, libclang), Cuint, (CXCursorKind,), arg1)
end

@cenum CXLinkageKind::UInt32 begin
    CXLinkage_Invalid = 0
    CXLinkage_NoLinkage = 1
    CXLinkage_Internal = 2
    CXLinkage_UniqueExternal = 3
    CXLinkage_External = 4
end

function clang_getCursorLinkage(cursor)
    ccall((:clang_getCursorLinkage, libclang), CXLinkageKind, (CXCursor,), cursor)
end

@cenum CXVisibilityKind::UInt32 begin
    CXVisibility_Invalid = 0
    CXVisibility_Hidden = 1
    CXVisibility_Protected = 2
    CXVisibility_Default = 3
end

function clang_getCursorVisibility(cursor)
    ccall((:clang_getCursorVisibility, libclang), CXVisibilityKind, (CXCursor,), cursor)
end

function clang_getCursorAvailability(cursor)
    ccall((:clang_getCursorAvailability, libclang), CXAvailabilityKind, (CXCursor,), cursor)
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
    ccall((:clang_getCursorPlatformAvailability, libclang), Cint, (CXCursor, Ptr{Cint}, Ptr{CXString}, Ptr{Cint}, Ptr{CXString}, Ptr{CXPlatformAvailability}, Cint), cursor, always_deprecated, deprecated_message, always_unavailable, unavailable_message, availability, availability_size)
end

function clang_disposeCXPlatformAvailability(availability)
    ccall((:clang_disposeCXPlatformAvailability, libclang), Cvoid, (Ptr{CXPlatformAvailability},), availability)
end

@cenum CXLanguageKind::UInt32 begin
    CXLanguage_Invalid = 0
    CXLanguage_C = 1
    CXLanguage_ObjC = 2
    CXLanguage_CPlusPlus = 3
end

function clang_getCursorLanguage(cursor)
    ccall((:clang_getCursorLanguage, libclang), CXLanguageKind, (CXCursor,), cursor)
end

@cenum CXTLSKind::UInt32 begin
    CXTLS_None = 0
    CXTLS_Dynamic = 1
    CXTLS_Static = 2
end

function clang_getCursorTLSKind(cursor)
    ccall((:clang_getCursorTLSKind, libclang), CXTLSKind, (CXCursor,), cursor)
end

function clang_Cursor_getTranslationUnit(arg1)
    ccall((:clang_Cursor_getTranslationUnit, libclang), CXTranslationUnit, (CXCursor,), arg1)
end

mutable struct CXCursorSetImpl end

const CXCursorSet = Ptr{CXCursorSetImpl}

function clang_createCXCursorSet()
    ccall((:clang_createCXCursorSet, libclang), CXCursorSet, ())
end

function clang_disposeCXCursorSet(cset)
    ccall((:clang_disposeCXCursorSet, libclang), Cvoid, (CXCursorSet,), cset)
end

function clang_CXCursorSet_contains(cset, cursor)
    ccall((:clang_CXCursorSet_contains, libclang), Cuint, (CXCursorSet, CXCursor), cset, cursor)
end

function clang_CXCursorSet_insert(cset, cursor)
    ccall((:clang_CXCursorSet_insert, libclang), Cuint, (CXCursorSet, CXCursor), cset, cursor)
end

function clang_getCursorSemanticParent(cursor)
    ccall((:clang_getCursorSemanticParent, libclang), CXCursor, (CXCursor,), cursor)
end

function clang_getCursorLexicalParent(cursor)
    ccall((:clang_getCursorLexicalParent, libclang), CXCursor, (CXCursor,), cursor)
end

function clang_getOverriddenCursors(cursor, overridden, num_overridden)
    ccall((:clang_getOverriddenCursors, libclang), Cvoid, (CXCursor, Ptr{Ptr{CXCursor}}, Ptr{Cuint}), cursor, overridden, num_overridden)
end

function clang_disposeOverriddenCursors(overridden)
    ccall((:clang_disposeOverriddenCursors, libclang), Cvoid, (Ptr{CXCursor},), overridden)
end

function clang_getIncludedFile(cursor)
    ccall((:clang_getIncludedFile, libclang), CXFile, (CXCursor,), cursor)
end

function clang_getCursor(arg1, arg2)
    ccall((:clang_getCursor, libclang), CXCursor, (CXTranslationUnit, CXSourceLocation), arg1, arg2)
end

function clang_getCursorLocation(arg1)
    ccall((:clang_getCursorLocation, libclang), CXSourceLocation, (CXCursor,), arg1)
end

function clang_getCursorExtent(arg1)
    ccall((:clang_getCursorExtent, libclang), CXSourceRange, (CXCursor,), arg1)
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

mutable struct CXType
    kind::CXTypeKind
    data::NTuple{2, Ptr{Cvoid}}
end

function clang_getCursorType(C)
    ccall((:clang_getCursorType, libclang), CXType, (CXCursor,), C)
end

function clang_getTypeSpelling(CT)
    ccall((:clang_getTypeSpelling, libclang), CXString, (CXType,), CT)
end

function clang_getTypedefDeclUnderlyingType(C)
    ccall((:clang_getTypedefDeclUnderlyingType, libclang), CXType, (CXCursor,), C)
end

function clang_getEnumDeclIntegerType(C)
    ccall((:clang_getEnumDeclIntegerType, libclang), CXType, (CXCursor,), C)
end

function clang_getEnumConstantDeclValue(C)
    ccall((:clang_getEnumConstantDeclValue, libclang), Clonglong, (CXCursor,), C)
end

function clang_getEnumConstantDeclUnsignedValue(C)
    ccall((:clang_getEnumConstantDeclUnsignedValue, libclang), Culonglong, (CXCursor,), C)
end

function clang_getFieldDeclBitWidth(C)
    ccall((:clang_getFieldDeclBitWidth, libclang), Cint, (CXCursor,), C)
end

function clang_Cursor_getNumArguments(C)
    ccall((:clang_Cursor_getNumArguments, libclang), Cint, (CXCursor,), C)
end

function clang_Cursor_getArgument(C, i)
    ccall((:clang_Cursor_getArgument, libclang), CXCursor, (CXCursor, Cuint), C, i)
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
    ccall((:clang_Cursor_getNumTemplateArguments, libclang), Cint, (CXCursor,), C)
end

function clang_Cursor_getTemplateArgumentKind(C, I)
    ccall((:clang_Cursor_getTemplateArgumentKind, libclang), CXTemplateArgumentKind, (CXCursor, Cuint), C, I)
end

function clang_Cursor_getTemplateArgumentType(C, I)
    ccall((:clang_Cursor_getTemplateArgumentType, libclang), CXType, (CXCursor, Cuint), C, I)
end

function clang_Cursor_getTemplateArgumentValue(C, I)
    ccall((:clang_Cursor_getTemplateArgumentValue, libclang), Clonglong, (CXCursor, Cuint), C, I)
end

function clang_Cursor_getTemplateArgumentUnsignedValue(C, I)
    ccall((:clang_Cursor_getTemplateArgumentUnsignedValue, libclang), Culonglong, (CXCursor, Cuint), C, I)
end

function clang_equalTypes(A, B)
    ccall((:clang_equalTypes, libclang), Cuint, (CXType, CXType), A, B)
end

function clang_getCanonicalType(T)
    ccall((:clang_getCanonicalType, libclang), CXType, (CXType,), T)
end

function clang_isConstQualifiedType(T)
    ccall((:clang_isConstQualifiedType, libclang), Cuint, (CXType,), T)
end

function clang_Cursor_isMacroFunctionLike(C)
    ccall((:clang_Cursor_isMacroFunctionLike, libclang), Cuint, (CXCursor,), C)
end

function clang_Cursor_isMacroBuiltin(C)
    ccall((:clang_Cursor_isMacroBuiltin, libclang), Cuint, (CXCursor,), C)
end

function clang_Cursor_isFunctionInlined(C)
    ccall((:clang_Cursor_isFunctionInlined, libclang), Cuint, (CXCursor,), C)
end

function clang_isVolatileQualifiedType(T)
    ccall((:clang_isVolatileQualifiedType, libclang), Cuint, (CXType,), T)
end

function clang_isRestrictQualifiedType(T)
    ccall((:clang_isRestrictQualifiedType, libclang), Cuint, (CXType,), T)
end

function clang_getAddressSpace(T)
    ccall((:clang_getAddressSpace, libclang), Cuint, (CXType,), T)
end

function clang_getTypedefName(CT)
    ccall((:clang_getTypedefName, libclang), CXString, (CXType,), CT)
end

function clang_getPointeeType(T)
    ccall((:clang_getPointeeType, libclang), CXType, (CXType,), T)
end

function clang_getTypeDeclaration(T)
    ccall((:clang_getTypeDeclaration, libclang), CXCursor, (CXType,), T)
end

function clang_getDeclObjCTypeEncoding(C)
    ccall((:clang_getDeclObjCTypeEncoding, libclang), CXString, (CXCursor,), C)
end

function clang_Type_getObjCEncoding(type)
    ccall((:clang_Type_getObjCEncoding, libclang), CXString, (CXType,), type)
end

function clang_getTypeKindSpelling(K)
    ccall((:clang_getTypeKindSpelling, libclang), CXString, (CXTypeKind,), K)
end

function clang_getFunctionTypeCallingConv(T)
    ccall((:clang_getFunctionTypeCallingConv, libclang), CXCallingConv, (CXType,), T)
end

function clang_getResultType(T)
    ccall((:clang_getResultType, libclang), CXType, (CXType,), T)
end

function clang_getExceptionSpecificationType(T)
    ccall((:clang_getExceptionSpecificationType, libclang), Cint, (CXType,), T)
end

function clang_getNumArgTypes(T)
    ccall((:clang_getNumArgTypes, libclang), Cint, (CXType,), T)
end

function clang_getArgType(T, i)
    ccall((:clang_getArgType, libclang), CXType, (CXType, Cuint), T, i)
end

function clang_Type_getObjCObjectBaseType(T)
    ccall((:clang_Type_getObjCObjectBaseType, libclang), CXType, (CXType,), T)
end

function clang_Type_getNumObjCProtocolRefs(T)
    ccall((:clang_Type_getNumObjCProtocolRefs, libclang), Cuint, (CXType,), T)
end

function clang_Type_getObjCProtocolDecl(T, i)
    ccall((:clang_Type_getObjCProtocolDecl, libclang), CXCursor, (CXType, Cuint), T, i)
end

function clang_Type_getNumObjCTypeArgs(T)
    ccall((:clang_Type_getNumObjCTypeArgs, libclang), Cuint, (CXType,), T)
end

function clang_Type_getObjCTypeArg(T, i)
    ccall((:clang_Type_getObjCTypeArg, libclang), CXType, (CXType, Cuint), T, i)
end

function clang_isFunctionTypeVariadic(T)
    ccall((:clang_isFunctionTypeVariadic, libclang), Cuint, (CXType,), T)
end

function clang_getCursorResultType(C)
    ccall((:clang_getCursorResultType, libclang), CXType, (CXCursor,), C)
end

function clang_getCursorExceptionSpecificationType(C)
    ccall((:clang_getCursorExceptionSpecificationType, libclang), Cint, (CXCursor,), C)
end

function clang_isPODType(T)
    ccall((:clang_isPODType, libclang), Cuint, (CXType,), T)
end

function clang_getElementType(T)
    ccall((:clang_getElementType, libclang), CXType, (CXType,), T)
end

function clang_getNumElements(T)
    ccall((:clang_getNumElements, libclang), Clonglong, (CXType,), T)
end

function clang_getArrayElementType(T)
    ccall((:clang_getArrayElementType, libclang), CXType, (CXType,), T)
end

function clang_getArraySize(T)
    ccall((:clang_getArraySize, libclang), Clonglong, (CXType,), T)
end

function clang_Type_getNamedType(T)
    ccall((:clang_Type_getNamedType, libclang), CXType, (CXType,), T)
end

function clang_Type_isTransparentTagTypedef(T)
    ccall((:clang_Type_isTransparentTagTypedef, libclang), Cuint, (CXType,), T)
end

@cenum CXTypeNullabilityKind::UInt32 begin
    CXTypeNullability_NonNull = 0
    CXTypeNullability_Nullable = 1
    CXTypeNullability_Unspecified = 2
    CXTypeNullability_Invalid = 3
end

function clang_Type_getNullability(T)
    ccall((:clang_Type_getNullability, libclang), CXTypeNullabilityKind, (CXType,), T)
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
    ccall((:clang_Type_getAlignOf, libclang), Clonglong, (CXType,), T)
end

function clang_Type_getClassType(T)
    ccall((:clang_Type_getClassType, libclang), CXType, (CXType,), T)
end

function clang_Type_getSizeOf(T)
    ccall((:clang_Type_getSizeOf, libclang), Clonglong, (CXType,), T)
end

function clang_Type_getOffsetOf(T, S)
    ccall((:clang_Type_getOffsetOf, libclang), Clonglong, (CXType, Cstring), T, S)
end

function clang_Type_getModifiedType(T)
    ccall((:clang_Type_getModifiedType, libclang), CXType, (CXType,), T)
end

function clang_Type_getValueType(CT)
    ccall((:clang_Type_getValueType, libclang), CXType, (CXType,), CT)
end

function clang_Cursor_getOffsetOfField(C)
    ccall((:clang_Cursor_getOffsetOfField, libclang), Clonglong, (CXCursor,), C)
end

function clang_Cursor_isAnonymous(C)
    ccall((:clang_Cursor_isAnonymous, libclang), Cuint, (CXCursor,), C)
end

function clang_Cursor_isAnonymousRecordDecl(C)
    ccall((:clang_Cursor_isAnonymousRecordDecl, libclang), Cuint, (CXCursor,), C)
end

function clang_Cursor_isInlineNamespace(C)
    ccall((:clang_Cursor_isInlineNamespace, libclang), Cuint, (CXCursor,), C)
end

@cenum CXRefQualifierKind::UInt32 begin
    CXRefQualifier_None = 0
    CXRefQualifier_LValue = 1
    CXRefQualifier_RValue = 2
end

function clang_Type_getNumTemplateArguments(T)
    ccall((:clang_Type_getNumTemplateArguments, libclang), Cint, (CXType,), T)
end

function clang_Type_getTemplateArgumentAsType(T, i)
    ccall((:clang_Type_getTemplateArgumentAsType, libclang), CXType, (CXType, Cuint), T, i)
end

function clang_Type_getCXXRefQualifier(T)
    ccall((:clang_Type_getCXXRefQualifier, libclang), CXRefQualifierKind, (CXType,), T)
end

function clang_Cursor_isBitField(C)
    ccall((:clang_Cursor_isBitField, libclang), Cuint, (CXCursor,), C)
end

function clang_isVirtualBase(arg1)
    ccall((:clang_isVirtualBase, libclang), Cuint, (CXCursor,), arg1)
end

@cenum CX_CXXAccessSpecifier::UInt32 begin
    CX_CXXInvalidAccessSpecifier = 0
    CX_CXXPublic = 1
    CX_CXXProtected = 2
    CX_CXXPrivate = 3
end

function clang_getCXXAccessSpecifier(arg1)
    ccall((:clang_getCXXAccessSpecifier, libclang), CX_CXXAccessSpecifier, (CXCursor,), arg1)
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
    ccall((:clang_Cursor_getStorageClass, libclang), CX_StorageClass, (CXCursor,), arg1)
end

function clang_getNumOverloadedDecls(cursor)
    ccall((:clang_getNumOverloadedDecls, libclang), Cuint, (CXCursor,), cursor)
end

function clang_getOverloadedDecl(cursor, index)
    ccall((:clang_getOverloadedDecl, libclang), CXCursor, (CXCursor, Cuint), cursor, index)
end

function clang_getIBOutletCollectionType(arg1)
    ccall((:clang_getIBOutletCollectionType, libclang), CXType, (CXCursor,), arg1)
end

@cenum CXChildVisitResult::UInt32 begin
    CXChildVisit_Break = 0
    CXChildVisit_Continue = 1
    CXChildVisit_Recurse = 2
end

# typedef enum CXChildVisitResult ( * CXCursorVisitor ) ( CXCursor cursor , CXCursor parent , CXClientData client_data )
const CXCursorVisitor = Ptr{Cvoid}

function clang_visitChildren(parent, visitor, client_data)
    ccall((:clang_visitChildren, libclang), Cuint, (CXCursor, CXCursorVisitor, CXClientData), parent, visitor, client_data)
end

function clang_getCursorUSR(arg1)
    ccall((:clang_getCursorUSR, libclang), CXString, (CXCursor,), arg1)
end

function clang_constructUSR_ObjCClass(class_name)
    ccall((:clang_constructUSR_ObjCClass, libclang), CXString, (Cstring,), class_name)
end

function clang_constructUSR_ObjCCategory(class_name, category_name)
    ccall((:clang_constructUSR_ObjCCategory, libclang), CXString, (Cstring, Cstring), class_name, category_name)
end

function clang_constructUSR_ObjCProtocol(protocol_name)
    ccall((:clang_constructUSR_ObjCProtocol, libclang), CXString, (Cstring,), protocol_name)
end

function clang_constructUSR_ObjCIvar(name, classUSR)
    ccall((:clang_constructUSR_ObjCIvar, libclang), CXString, (Cstring, CXString), name, classUSR)
end

function clang_constructUSR_ObjCMethod(name, isInstanceMethod, classUSR)
    ccall((:clang_constructUSR_ObjCMethod, libclang), CXString, (Cstring, Cuint, CXString), name, isInstanceMethod, classUSR)
end

function clang_constructUSR_ObjCProperty(property, classUSR)
    ccall((:clang_constructUSR_ObjCProperty, libclang), CXString, (Cstring, CXString), property, classUSR)
end

function clang_getCursorSpelling(arg1)
    ccall((:clang_getCursorSpelling, libclang), CXString, (CXCursor,), arg1)
end

function clang_Cursor_getSpellingNameRange(arg1, pieceIndex, options)
    ccall((:clang_Cursor_getSpellingNameRange, libclang), CXSourceRange, (CXCursor, Cuint, Cuint), arg1, pieceIndex, options)
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
    ccall((:clang_PrintingPolicy_getProperty, libclang), Cuint, (CXPrintingPolicy, CXPrintingPolicyProperty), Policy, Property)
end

function clang_PrintingPolicy_setProperty(Policy, Property, Value)
    ccall((:clang_PrintingPolicy_setProperty, libclang), Cvoid, (CXPrintingPolicy, CXPrintingPolicyProperty, Cuint), Policy, Property, Value)
end

function clang_getCursorPrintingPolicy(arg1)
    ccall((:clang_getCursorPrintingPolicy, libclang), CXPrintingPolicy, (CXCursor,), arg1)
end

function clang_PrintingPolicy_dispose(Policy)
    ccall((:clang_PrintingPolicy_dispose, libclang), Cvoid, (CXPrintingPolicy,), Policy)
end

function clang_getCursorPrettyPrinted(Cursor, Policy)
    ccall((:clang_getCursorPrettyPrinted, libclang), CXString, (CXCursor, CXPrintingPolicy), Cursor, Policy)
end

function clang_getCursorDisplayName(arg1)
    ccall((:clang_getCursorDisplayName, libclang), CXString, (CXCursor,), arg1)
end

function clang_getCursorReferenced(arg1)
    ccall((:clang_getCursorReferenced, libclang), CXCursor, (CXCursor,), arg1)
end

function clang_getCursorDefinition(arg1)
    ccall((:clang_getCursorDefinition, libclang), CXCursor, (CXCursor,), arg1)
end

function clang_isCursorDefinition(arg1)
    ccall((:clang_isCursorDefinition, libclang), Cuint, (CXCursor,), arg1)
end

function clang_getCanonicalCursor(arg1)
    ccall((:clang_getCanonicalCursor, libclang), CXCursor, (CXCursor,), arg1)
end

function clang_Cursor_getObjCSelectorIndex(arg1)
    ccall((:clang_Cursor_getObjCSelectorIndex, libclang), Cint, (CXCursor,), arg1)
end

function clang_Cursor_isDynamicCall(C)
    ccall((:clang_Cursor_isDynamicCall, libclang), Cint, (CXCursor,), C)
end

function clang_Cursor_getReceiverType(C)
    ccall((:clang_Cursor_getReceiverType, libclang), CXType, (CXCursor,), C)
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
    ccall((:clang_Cursor_getObjCPropertyAttributes, libclang), Cuint, (CXCursor, Cuint), C, reserved)
end

function clang_Cursor_getObjCPropertyGetterName(C)
    ccall((:clang_Cursor_getObjCPropertyGetterName, libclang), CXString, (CXCursor,), C)
end

function clang_Cursor_getObjCPropertySetterName(C)
    ccall((:clang_Cursor_getObjCPropertySetterName, libclang), CXString, (CXCursor,), C)
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
    ccall((:clang_Cursor_getObjCDeclQualifiers, libclang), Cuint, (CXCursor,), C)
end

function clang_Cursor_isObjCOptional(C)
    ccall((:clang_Cursor_isObjCOptional, libclang), Cuint, (CXCursor,), C)
end

function clang_Cursor_isVariadic(C)
    ccall((:clang_Cursor_isVariadic, libclang), Cuint, (CXCursor,), C)
end

function clang_Cursor_isExternalSymbol(C, language, definedIn, isGenerated)
    ccall((:clang_Cursor_isExternalSymbol, libclang), Cuint, (CXCursor, Ptr{CXString}, Ptr{CXString}, Ptr{Cuint}), C, language, definedIn, isGenerated)
end

function clang_Cursor_getCommentRange(C)
    ccall((:clang_Cursor_getCommentRange, libclang), CXSourceRange, (CXCursor,), C)
end

function clang_Cursor_getRawCommentText(C)
    ccall((:clang_Cursor_getRawCommentText, libclang), CXString, (CXCursor,), C)
end

function clang_Cursor_getBriefCommentText(C)
    ccall((:clang_Cursor_getBriefCommentText, libclang), CXString, (CXCursor,), C)
end

function clang_Cursor_getMangling(arg1)
    ccall((:clang_Cursor_getMangling, libclang), CXString, (CXCursor,), arg1)
end

function clang_Cursor_getCXXManglings(arg1)
    ccall((:clang_Cursor_getCXXManglings, libclang), Ptr{CXStringSet}, (CXCursor,), arg1)
end

function clang_Cursor_getObjCManglings(arg1)
    ccall((:clang_Cursor_getObjCManglings, libclang), Ptr{CXStringSet}, (CXCursor,), arg1)
end

const CXModule = Ptr{Cvoid}

function clang_Cursor_getModule(C)
    ccall((:clang_Cursor_getModule, libclang), CXModule, (CXCursor,), C)
end

function clang_getModuleForFile(arg1, arg2)
    ccall((:clang_getModuleForFile, libclang), CXModule, (CXTranslationUnit, CXFile), arg1, arg2)
end

function clang_Module_getASTFile(Module)
    ccall((:clang_Module_getASTFile, libclang), CXFile, (CXModule,), Module)
end

function clang_Module_getParent(Module)
    ccall((:clang_Module_getParent, libclang), CXModule, (CXModule,), Module)
end

function clang_Module_getName(Module)
    ccall((:clang_Module_getName, libclang), CXString, (CXModule,), Module)
end

function clang_Module_getFullName(Module)
    ccall((:clang_Module_getFullName, libclang), CXString, (CXModule,), Module)
end

function clang_Module_isSystem(Module)
    ccall((:clang_Module_isSystem, libclang), Cint, (CXModule,), Module)
end

function clang_Module_getNumTopLevelHeaders(arg1, Module)
    ccall((:clang_Module_getNumTopLevelHeaders, libclang), Cuint, (CXTranslationUnit, CXModule), arg1, Module)
end

function clang_Module_getTopLevelHeader(arg1, Module, Index)
    ccall((:clang_Module_getTopLevelHeader, libclang), CXFile, (CXTranslationUnit, CXModule, Cuint), arg1, Module, Index)
end

function clang_CXXConstructor_isConvertingConstructor(C)
    ccall((:clang_CXXConstructor_isConvertingConstructor, libclang), Cuint, (CXCursor,), C)
end

function clang_CXXConstructor_isCopyConstructor(C)
    ccall((:clang_CXXConstructor_isCopyConstructor, libclang), Cuint, (CXCursor,), C)
end

function clang_CXXConstructor_isDefaultConstructor(C)
    ccall((:clang_CXXConstructor_isDefaultConstructor, libclang), Cuint, (CXCursor,), C)
end

function clang_CXXConstructor_isMoveConstructor(C)
    ccall((:clang_CXXConstructor_isMoveConstructor, libclang), Cuint, (CXCursor,), C)
end

function clang_CXXField_isMutable(C)
    ccall((:clang_CXXField_isMutable, libclang), Cuint, (CXCursor,), C)
end

function clang_CXXMethod_isDefaulted(C)
    ccall((:clang_CXXMethod_isDefaulted, libclang), Cuint, (CXCursor,), C)
end

function clang_CXXMethod_isPureVirtual(C)
    ccall((:clang_CXXMethod_isPureVirtual, libclang), Cuint, (CXCursor,), C)
end

function clang_CXXMethod_isStatic(C)
    ccall((:clang_CXXMethod_isStatic, libclang), Cuint, (CXCursor,), C)
end

function clang_CXXMethod_isVirtual(C)
    ccall((:clang_CXXMethod_isVirtual, libclang), Cuint, (CXCursor,), C)
end

function clang_CXXRecord_isAbstract(C)
    ccall((:clang_CXXRecord_isAbstract, libclang), Cuint, (CXCursor,), C)
end

function clang_EnumDecl_isScoped(C)
    ccall((:clang_EnumDecl_isScoped, libclang), Cuint, (CXCursor,), C)
end

function clang_CXXMethod_isConst(C)
    ccall((:clang_CXXMethod_isConst, libclang), Cuint, (CXCursor,), C)
end

function clang_getTemplateCursorKind(C)
    ccall((:clang_getTemplateCursorKind, libclang), CXCursorKind, (CXCursor,), C)
end

function clang_getSpecializedCursorTemplate(C)
    ccall((:clang_getSpecializedCursorTemplate, libclang), CXCursor, (CXCursor,), C)
end

function clang_getCursorReferenceNameRange(C, NameFlags, PieceIndex)
    ccall((:clang_getCursorReferenceNameRange, libclang), CXSourceRange, (CXCursor, Cuint, Cuint), C, NameFlags, PieceIndex)
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

mutable struct CXToken
    int_data::NTuple{4, Cuint}
    ptr_data::Ptr{Cvoid}
end

function clang_getToken(TU, Location)
    ccall((:clang_getToken, libclang), Ptr{CXToken}, (CXTranslationUnit, CXSourceLocation), TU, Location)
end

function clang_getTokenKind(arg1)
    ccall((:clang_getTokenKind, libclang), CXTokenKind, (CXToken,), arg1)
end

function clang_getTokenSpelling(arg1, arg2)
    ccall((:clang_getTokenSpelling, libclang), CXString, (CXTranslationUnit, CXToken), arg1, arg2)
end

function clang_getTokenLocation(arg1, arg2)
    ccall((:clang_getTokenLocation, libclang), CXSourceLocation, (CXTranslationUnit, CXToken), arg1, arg2)
end

function clang_getTokenExtent(arg1, arg2)
    ccall((:clang_getTokenExtent, libclang), CXSourceRange, (CXTranslationUnit, CXToken), arg1, arg2)
end

function clang_tokenize(TU, Range, Tokens, NumTokens)
    ccall((:clang_tokenize, libclang), Cvoid, (CXTranslationUnit, CXSourceRange, Ptr{Ptr{CXToken}}, Ptr{Cuint}), TU, Range, Tokens, NumTokens)
end

function clang_annotateTokens(TU, Tokens, NumTokens, Cursors)
    ccall((:clang_annotateTokens, libclang), Cvoid, (CXTranslationUnit, Ptr{CXToken}, Cuint, Ptr{CXCursor}), TU, Tokens, NumTokens, Cursors)
end

function clang_disposeTokens(TU, Tokens, NumTokens)
    ccall((:clang_disposeTokens, libclang), Cvoid, (CXTranslationUnit, Ptr{CXToken}, Cuint), TU, Tokens, NumTokens)
end

function clang_getCursorKindSpelling(Kind)
    ccall((:clang_getCursorKindSpelling, libclang), CXString, (CXCursorKind,), Kind)
end

function clang_getDefinitionSpellingAndExtent(arg1, startBuf, endBuf, startLine, startColumn, endLine, endColumn)
    ccall((:clang_getDefinitionSpellingAndExtent, libclang), Cvoid, (CXCursor, Ptr{Cstring}, Ptr{Cstring}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), arg1, startBuf, endBuf, startLine, startColumn, endLine, endColumn)
end

function clang_enableStackTraces()
    ccall((:clang_enableStackTraces, libclang), Cvoid, ())
end

function clang_executeOnThread(fn, user_data, stack_size)
    ccall((:clang_executeOnThread, libclang), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}, Cuint), fn, user_data, stack_size)
end

const CXCompletionString = Ptr{Cvoid}

mutable struct CXCompletionResult
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
    ccall((:clang_getCompletionChunkKind, libclang), CXCompletionChunkKind, (CXCompletionString, Cuint), completion_string, chunk_number)
end

function clang_getCompletionChunkText(completion_string, chunk_number)
    ccall((:clang_getCompletionChunkText, libclang), CXString, (CXCompletionString, Cuint), completion_string, chunk_number)
end

function clang_getCompletionChunkCompletionString(completion_string, chunk_number)
    ccall((:clang_getCompletionChunkCompletionString, libclang), CXCompletionString, (CXCompletionString, Cuint), completion_string, chunk_number)
end

function clang_getNumCompletionChunks(completion_string)
    ccall((:clang_getNumCompletionChunks, libclang), Cuint, (CXCompletionString,), completion_string)
end

function clang_getCompletionPriority(completion_string)
    ccall((:clang_getCompletionPriority, libclang), Cuint, (CXCompletionString,), completion_string)
end

function clang_getCompletionAvailability(completion_string)
    ccall((:clang_getCompletionAvailability, libclang), CXAvailabilityKind, (CXCompletionString,), completion_string)
end

function clang_getCompletionNumAnnotations(completion_string)
    ccall((:clang_getCompletionNumAnnotations, libclang), Cuint, (CXCompletionString,), completion_string)
end

function clang_getCompletionAnnotation(completion_string, annotation_number)
    ccall((:clang_getCompletionAnnotation, libclang), CXString, (CXCompletionString, Cuint), completion_string, annotation_number)
end

function clang_getCompletionParent(completion_string, kind)
    ccall((:clang_getCompletionParent, libclang), CXString, (CXCompletionString, Ptr{CXCursorKind}), completion_string, kind)
end

function clang_getCompletionBriefComment(completion_string)
    ccall((:clang_getCompletionBriefComment, libclang), CXString, (CXCompletionString,), completion_string)
end

function clang_getCursorCompletionString(cursor)
    ccall((:clang_getCursorCompletionString, libclang), CXCompletionString, (CXCursor,), cursor)
end

mutable struct CXCodeCompleteResults
    Results::Ptr{CXCompletionResult}
    NumResults::Cuint
end

function clang_getCompletionNumFixIts(results, completion_index)
    ccall((:clang_getCompletionNumFixIts, libclang), Cuint, (Ptr{CXCodeCompleteResults}, Cuint), results, completion_index)
end

function clang_getCompletionFixIt(results, completion_index, fixit_index, replacement_range)
    ccall((:clang_getCompletionFixIt, libclang), CXString, (Ptr{CXCodeCompleteResults}, Cuint, Cuint, Ptr{CXSourceRange}), results, completion_index, fixit_index, replacement_range)
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
    ccall((:clang_defaultCodeCompleteOptions, libclang), Cuint, ())
end

function clang_codeCompleteAt(TU, complete_filename, complete_line, complete_column, unsaved_files, num_unsaved_files, options)
    ccall((:clang_codeCompleteAt, libclang), Ptr{CXCodeCompleteResults}, (CXTranslationUnit, Cstring, Cuint, Cuint, Ptr{CXUnsavedFile}, Cuint, Cuint), TU, complete_filename, complete_line, complete_column, unsaved_files, num_unsaved_files, options)
end

function clang_sortCodeCompletionResults(Results, NumResults)
    ccall((:clang_sortCodeCompletionResults, libclang), Cvoid, (Ptr{CXCompletionResult}, Cuint), Results, NumResults)
end

function clang_disposeCodeCompleteResults(Results)
    ccall((:clang_disposeCodeCompleteResults, libclang), Cvoid, (Ptr{CXCodeCompleteResults},), Results)
end

function clang_codeCompleteGetNumDiagnostics(Results)
    ccall((:clang_codeCompleteGetNumDiagnostics, libclang), Cuint, (Ptr{CXCodeCompleteResults},), Results)
end

function clang_codeCompleteGetDiagnostic(Results, Index)
    ccall((:clang_codeCompleteGetDiagnostic, libclang), CXDiagnostic, (Ptr{CXCodeCompleteResults}, Cuint), Results, Index)
end

function clang_codeCompleteGetContexts(Results)
    ccall((:clang_codeCompleteGetContexts, libclang), Culonglong, (Ptr{CXCodeCompleteResults},), Results)
end

function clang_codeCompleteGetContainerKind(Results, IsIncomplete)
    ccall((:clang_codeCompleteGetContainerKind, libclang), CXCursorKind, (Ptr{CXCodeCompleteResults}, Ptr{Cuint}), Results, IsIncomplete)
end

function clang_codeCompleteGetContainerUSR(Results)
    ccall((:clang_codeCompleteGetContainerUSR, libclang), CXString, (Ptr{CXCodeCompleteResults},), Results)
end

function clang_codeCompleteGetObjCSelector(Results)
    ccall((:clang_codeCompleteGetObjCSelector, libclang), CXString, (Ptr{CXCodeCompleteResults},), Results)
end

function clang_getClangVersion()
    ccall((:clang_getClangVersion, libclang), CXString, ())
end

function clang_toggleCrashRecovery(isEnabled)
    ccall((:clang_toggleCrashRecovery, libclang), Cvoid, (Cuint,), isEnabled)
end

# typedef void ( * CXInclusionVisitor ) ( CXFile included_file , CXSourceLocation * inclusion_stack , unsigned include_len , CXClientData client_data )
const CXInclusionVisitor = Ptr{Cvoid}

function clang_getInclusions(tu, visitor, client_data)
    ccall((:clang_getInclusions, libclang), Cvoid, (CXTranslationUnit, CXInclusionVisitor, CXClientData), tu, visitor, client_data)
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
    ccall((:clang_Cursor_Evaluate, libclang), CXEvalResult, (CXCursor,), C)
end

function clang_EvalResult_getKind(E)
    ccall((:clang_EvalResult_getKind, libclang), CXEvalResultKind, (CXEvalResult,), E)
end

function clang_EvalResult_getAsInt(E)
    ccall((:clang_EvalResult_getAsInt, libclang), Cint, (CXEvalResult,), E)
end

function clang_EvalResult_getAsLongLong(E)
    ccall((:clang_EvalResult_getAsLongLong, libclang), Clonglong, (CXEvalResult,), E)
end

function clang_EvalResult_isUnsignedInt(E)
    ccall((:clang_EvalResult_isUnsignedInt, libclang), Cuint, (CXEvalResult,), E)
end

function clang_EvalResult_getAsUnsigned(E)
    ccall((:clang_EvalResult_getAsUnsigned, libclang), Culonglong, (CXEvalResult,), E)
end

function clang_EvalResult_getAsDouble(E)
    ccall((:clang_EvalResult_getAsDouble, libclang), Cdouble, (CXEvalResult,), E)
end

function clang_EvalResult_getAsStr(E)
    ccall((:clang_EvalResult_getAsStr, libclang), Cstring, (CXEvalResult,), E)
end

function clang_EvalResult_dispose(E)
    ccall((:clang_EvalResult_dispose, libclang), Cvoid, (CXEvalResult,), E)
end

const CXRemapping = Ptr{Cvoid}

function clang_getRemappings(path)
    ccall((:clang_getRemappings, libclang), CXRemapping, (Cstring,), path)
end

function clang_getRemappingsFromFileList(filePaths, numFiles)
    ccall((:clang_getRemappingsFromFileList, libclang), CXRemapping, (Ptr{Cstring}, Cuint), filePaths, numFiles)
end

function clang_remap_getNumFiles(arg1)
    ccall((:clang_remap_getNumFiles, libclang), Cuint, (CXRemapping,), arg1)
end

function clang_remap_getFilenames(arg1, index, original, transformed)
    ccall((:clang_remap_getFilenames, libclang), Cvoid, (CXRemapping, Cuint, Ptr{CXString}, Ptr{CXString}), arg1, index, original, transformed)
end

function clang_remap_dispose(arg1)
    ccall((:clang_remap_dispose, libclang), Cvoid, (CXRemapping,), arg1)
end

@cenum CXVisitorResult::UInt32 begin
    CXVisit_Break = 0
    CXVisit_Continue = 1
end

mutable struct CXCursorAndRangeVisitor
    context::Ptr{Cvoid}
    visit::Ptr{Cvoid}
end

@cenum CXResult::UInt32 begin
    CXResult_Success = 0
    CXResult_Invalid = 1
    CXResult_VisitBreak = 2
end

function clang_findReferencesInFile(cursor, file, visitor)
    ccall((:clang_findReferencesInFile, libclang), CXResult, (CXCursor, CXFile, CXCursorAndRangeVisitor), cursor, file, visitor)
end

function clang_findIncludesInFile(TU, file, visitor)
    ccall((:clang_findIncludesInFile, libclang), CXResult, (CXTranslationUnit, CXFile, CXCursorAndRangeVisitor), TU, file, visitor)
end

const CXIdxClientFile = Ptr{Cvoid}

const CXIdxClientEntity = Ptr{Cvoid}

const CXIdxClientContainer = Ptr{Cvoid}

const CXIdxClientASTFile = Ptr{Cvoid}

mutable struct CXIdxLoc
    ptr_data::NTuple{2, Ptr{Cvoid}}
    int_data::Cuint
end

mutable struct CXIdxIncludedFileInfo
    hashLoc::CXIdxLoc
    filename::Cstring
    file::CXFile
    isImport::Cint
    isAngled::Cint
    isModuleImport::Cint
end

mutable struct CXIdxImportedASTFileInfo
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

mutable struct CXIdxAttrInfo
    kind::CXIdxAttrKind
    cursor::CXCursor
    loc::CXIdxLoc
end

mutable struct CXIdxEntityInfo
    kind::CXIdxEntityKind
    templateKind::CXIdxEntityCXXTemplateKind
    lang::CXIdxEntityLanguage
    name::Cstring
    USR::Cstring
    cursor::CXCursor
    attributes::Ptr{Ptr{CXIdxAttrInfo}}
    numAttributes::Cuint
end

mutable struct CXIdxContainerInfo
    cursor::CXCursor
end

mutable struct CXIdxIBOutletCollectionAttrInfo
    attrInfo::Ptr{CXIdxAttrInfo}
    objcClass::Ptr{CXIdxEntityInfo}
    classCursor::CXCursor
    classLoc::CXIdxLoc
end

@cenum CXIdxDeclInfoFlags::UInt32 begin
    CXIdxDeclFlag_Skipped = 1
end

mutable struct CXIdxDeclInfo
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

mutable struct CXIdxObjCContainerDeclInfo
    declInfo::Ptr{CXIdxDeclInfo}
    kind::CXIdxObjCContainerKind
end

mutable struct CXIdxBaseClassInfo
    base::Ptr{CXIdxEntityInfo}
    cursor::CXCursor
    loc::CXIdxLoc
end

mutable struct CXIdxObjCProtocolRefInfo
    protocol::Ptr{CXIdxEntityInfo}
    cursor::CXCursor
    loc::CXIdxLoc
end

mutable struct CXIdxObjCProtocolRefListInfo
    protocols::Ptr{Ptr{CXIdxObjCProtocolRefInfo}}
    numProtocols::Cuint
end

mutable struct CXIdxObjCInterfaceDeclInfo
    containerInfo::Ptr{CXIdxObjCContainerDeclInfo}
    superInfo::Ptr{CXIdxBaseClassInfo}
    protocols::Ptr{CXIdxObjCProtocolRefListInfo}
end

mutable struct CXIdxObjCCategoryDeclInfo
    containerInfo::Ptr{CXIdxObjCContainerDeclInfo}
    objcClass::Ptr{CXIdxEntityInfo}
    classCursor::CXCursor
    classLoc::CXIdxLoc
    protocols::Ptr{CXIdxObjCProtocolRefListInfo}
end

mutable struct CXIdxObjCPropertyDeclInfo
    declInfo::Ptr{CXIdxDeclInfo}
    getter::Ptr{CXIdxEntityInfo}
    setter::Ptr{CXIdxEntityInfo}
end

mutable struct CXIdxCXXClassDeclInfo
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

mutable struct CXIdxEntityRefInfo
    kind::CXIdxEntityRefKind
    cursor::CXCursor
    loc::CXIdxLoc
    referencedEntity::Ptr{CXIdxEntityInfo}
    parentEntity::Ptr{CXIdxEntityInfo}
    container::Ptr{CXIdxContainerInfo}
    role::CXSymbolRole
end

mutable struct IndexerCallbacks
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
    ccall((:clang_index_isEntityObjCContainerKind, libclang), Cint, (CXIdxEntityKind,), arg1)
end

function clang_index_getObjCContainerDeclInfo(arg1)
    ccall((:clang_index_getObjCContainerDeclInfo, libclang), Ptr{CXIdxObjCContainerDeclInfo}, (Ptr{CXIdxDeclInfo},), arg1)
end

function clang_index_getObjCInterfaceDeclInfo(arg1)
    ccall((:clang_index_getObjCInterfaceDeclInfo, libclang), Ptr{CXIdxObjCInterfaceDeclInfo}, (Ptr{CXIdxDeclInfo},), arg1)
end

function clang_index_getObjCCategoryDeclInfo(arg1)
    ccall((:clang_index_getObjCCategoryDeclInfo, libclang), Ptr{CXIdxObjCCategoryDeclInfo}, (Ptr{CXIdxDeclInfo},), arg1)
end

function clang_index_getObjCProtocolRefListInfo(arg1)
    ccall((:clang_index_getObjCProtocolRefListInfo, libclang), Ptr{CXIdxObjCProtocolRefListInfo}, (Ptr{CXIdxDeclInfo},), arg1)
end

function clang_index_getObjCPropertyDeclInfo(arg1)
    ccall((:clang_index_getObjCPropertyDeclInfo, libclang), Ptr{CXIdxObjCPropertyDeclInfo}, (Ptr{CXIdxDeclInfo},), arg1)
end

function clang_index_getIBOutletCollectionAttrInfo(arg1)
    ccall((:clang_index_getIBOutletCollectionAttrInfo, libclang), Ptr{CXIdxIBOutletCollectionAttrInfo}, (Ptr{CXIdxAttrInfo},), arg1)
end

function clang_index_getCXXClassDeclInfo(arg1)
    ccall((:clang_index_getCXXClassDeclInfo, libclang), Ptr{CXIdxCXXClassDeclInfo}, (Ptr{CXIdxDeclInfo},), arg1)
end

function clang_index_getClientContainer(arg1)
    ccall((:clang_index_getClientContainer, libclang), CXIdxClientContainer, (Ptr{CXIdxContainerInfo},), arg1)
end

function clang_index_setClientContainer(arg1, arg2)
    ccall((:clang_index_setClientContainer, libclang), Cvoid, (Ptr{CXIdxContainerInfo}, CXIdxClientContainer), arg1, arg2)
end

function clang_index_getClientEntity(arg1)
    ccall((:clang_index_getClientEntity, libclang), CXIdxClientEntity, (Ptr{CXIdxEntityInfo},), arg1)
end

function clang_index_setClientEntity(arg1, arg2)
    ccall((:clang_index_setClientEntity, libclang), Cvoid, (Ptr{CXIdxEntityInfo}, CXIdxClientEntity), arg1, arg2)
end

const CXIndexAction = Ptr{Cvoid}

function clang_IndexAction_create(CIdx)
    ccall((:clang_IndexAction_create, libclang), CXIndexAction, (CXIndex,), CIdx)
end

function clang_IndexAction_dispose(arg1)
    ccall((:clang_IndexAction_dispose, libclang), Cvoid, (CXIndexAction,), arg1)
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
    ccall((:clang_indexSourceFile, libclang), Cint, (CXIndexAction, CXClientData, Ptr{IndexerCallbacks}, Cuint, Cuint, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, Cuint, Ptr{CXTranslationUnit}, Cuint), arg1, client_data, index_callbacks, index_callbacks_size, index_options, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, out_TU, TU_options)
end

function clang_indexSourceFileFullArgv(arg1, client_data, index_callbacks, index_callbacks_size, index_options, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, out_TU, TU_options)
    ccall((:clang_indexSourceFileFullArgv, libclang), Cint, (CXIndexAction, CXClientData, Ptr{IndexerCallbacks}, Cuint, Cuint, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, Cuint, Ptr{CXTranslationUnit}, Cuint), arg1, client_data, index_callbacks, index_callbacks_size, index_options, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, out_TU, TU_options)
end

function clang_indexTranslationUnit(arg1, client_data, index_callbacks, index_callbacks_size, index_options, arg6)
    ccall((:clang_indexTranslationUnit, libclang), Cint, (CXIndexAction, CXClientData, Ptr{IndexerCallbacks}, Cuint, Cuint, CXTranslationUnit), arg1, client_data, index_callbacks, index_callbacks_size, index_options, arg6)
end

function clang_indexLoc_getFileLocation(loc, indexFile, file, line, column, offset)
    ccall((:clang_indexLoc_getFileLocation, libclang), Cvoid, (CXIdxLoc, Ptr{CXIdxClientFile}, Ptr{CXFile}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), loc, indexFile, file, line, column, offset)
end

function clang_indexLoc_getCXSourceLocation(loc)
    ccall((:clang_indexLoc_getCXSourceLocation, libclang), CXSourceLocation, (CXIdxLoc,), loc)
end

# typedef enum CXVisitorResult ( * CXFieldVisitor ) ( CXCursor C , CXClientData client_data )
const CXFieldVisitor = Ptr{Cvoid}

function clang_Type_visitFields(T, visitor, client_data)
    ccall((:clang_Type_visitFields, libclang), Cuint, (CXType, CXFieldVisitor, CXClientData), T, visitor, client_data)
end

mutable struct CXComment
    ASTNode::Ptr{Cvoid}
    TranslationUnit::CXTranslationUnit
end

function clang_Cursor_getParsedComment(C)
    ccall((:clang_Cursor_getParsedComment, libclang), CXComment, (CXCursor,), C)
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
    ccall((:clang_Comment_getKind, libclang), CXCommentKind, (CXComment,), Comment)
end

function clang_Comment_getNumChildren(Comment)
    ccall((:clang_Comment_getNumChildren, libclang), Cuint, (CXComment,), Comment)
end

function clang_Comment_getChild(Comment, ChildIdx)
    ccall((:clang_Comment_getChild, libclang), CXComment, (CXComment, Cuint), Comment, ChildIdx)
end

function clang_Comment_isWhitespace(Comment)
    ccall((:clang_Comment_isWhitespace, libclang), Cuint, (CXComment,), Comment)
end

function clang_InlineContentComment_hasTrailingNewline(Comment)
    ccall((:clang_InlineContentComment_hasTrailingNewline, libclang), Cuint, (CXComment,), Comment)
end

function clang_TextComment_getText(Comment)
    ccall((:clang_TextComment_getText, libclang), CXString, (CXComment,), Comment)
end

function clang_InlineCommandComment_getCommandName(Comment)
    ccall((:clang_InlineCommandComment_getCommandName, libclang), CXString, (CXComment,), Comment)
end

function clang_InlineCommandComment_getRenderKind(Comment)
    ccall((:clang_InlineCommandComment_getRenderKind, libclang), CXCommentInlineCommandRenderKind, (CXComment,), Comment)
end

function clang_InlineCommandComment_getNumArgs(Comment)
    ccall((:clang_InlineCommandComment_getNumArgs, libclang), Cuint, (CXComment,), Comment)
end

function clang_InlineCommandComment_getArgText(Comment, ArgIdx)
    ccall((:clang_InlineCommandComment_getArgText, libclang), CXString, (CXComment, Cuint), Comment, ArgIdx)
end

function clang_HTMLTagComment_getTagName(Comment)
    ccall((:clang_HTMLTagComment_getTagName, libclang), CXString, (CXComment,), Comment)
end

function clang_HTMLStartTagComment_isSelfClosing(Comment)
    ccall((:clang_HTMLStartTagComment_isSelfClosing, libclang), Cuint, (CXComment,), Comment)
end

function clang_HTMLStartTag_getNumAttrs(Comment)
    ccall((:clang_HTMLStartTag_getNumAttrs, libclang), Cuint, (CXComment,), Comment)
end

function clang_HTMLStartTag_getAttrName(Comment, AttrIdx)
    ccall((:clang_HTMLStartTag_getAttrName, libclang), CXString, (CXComment, Cuint), Comment, AttrIdx)
end

function clang_HTMLStartTag_getAttrValue(Comment, AttrIdx)
    ccall((:clang_HTMLStartTag_getAttrValue, libclang), CXString, (CXComment, Cuint), Comment, AttrIdx)
end

function clang_BlockCommandComment_getCommandName(Comment)
    ccall((:clang_BlockCommandComment_getCommandName, libclang), CXString, (CXComment,), Comment)
end

function clang_BlockCommandComment_getNumArgs(Comment)
    ccall((:clang_BlockCommandComment_getNumArgs, libclang), Cuint, (CXComment,), Comment)
end

function clang_BlockCommandComment_getArgText(Comment, ArgIdx)
    ccall((:clang_BlockCommandComment_getArgText, libclang), CXString, (CXComment, Cuint), Comment, ArgIdx)
end

function clang_BlockCommandComment_getParagraph(Comment)
    ccall((:clang_BlockCommandComment_getParagraph, libclang), CXComment, (CXComment,), Comment)
end

function clang_ParamCommandComment_getParamName(Comment)
    ccall((:clang_ParamCommandComment_getParamName, libclang), CXString, (CXComment,), Comment)
end

function clang_ParamCommandComment_isParamIndexValid(Comment)
    ccall((:clang_ParamCommandComment_isParamIndexValid, libclang), Cuint, (CXComment,), Comment)
end

function clang_ParamCommandComment_getParamIndex(Comment)
    ccall((:clang_ParamCommandComment_getParamIndex, libclang), Cuint, (CXComment,), Comment)
end

function clang_ParamCommandComment_isDirectionExplicit(Comment)
    ccall((:clang_ParamCommandComment_isDirectionExplicit, libclang), Cuint, (CXComment,), Comment)
end

function clang_ParamCommandComment_getDirection(Comment)
    ccall((:clang_ParamCommandComment_getDirection, libclang), CXCommentParamPassDirection, (CXComment,), Comment)
end

function clang_TParamCommandComment_getParamName(Comment)
    ccall((:clang_TParamCommandComment_getParamName, libclang), CXString, (CXComment,), Comment)
end

function clang_TParamCommandComment_isParamPositionValid(Comment)
    ccall((:clang_TParamCommandComment_isParamPositionValid, libclang), Cuint, (CXComment,), Comment)
end

function clang_TParamCommandComment_getDepth(Comment)
    ccall((:clang_TParamCommandComment_getDepth, libclang), Cuint, (CXComment,), Comment)
end

function clang_TParamCommandComment_getIndex(Comment, Depth)
    ccall((:clang_TParamCommandComment_getIndex, libclang), Cuint, (CXComment, Cuint), Comment, Depth)
end

function clang_VerbatimBlockLineComment_getText(Comment)
    ccall((:clang_VerbatimBlockLineComment_getText, libclang), CXString, (CXComment,), Comment)
end

function clang_VerbatimLineComment_getText(Comment)
    ccall((:clang_VerbatimLineComment_getText, libclang), CXString, (CXComment,), Comment)
end

function clang_HTMLTagComment_getAsString(Comment)
    ccall((:clang_HTMLTagComment_getAsString, libclang), CXString, (CXComment,), Comment)
end

function clang_FullComment_getAsHTML(Comment)
    ccall((:clang_FullComment_getAsHTML, libclang), CXString, (CXComment,), Comment)
end

function clang_FullComment_getAsXML(Comment)
    ccall((:clang_FullComment_getAsXML, libclang), CXString, (CXComment,), Comment)
end

const CXCompilationDatabase = Ptr{Cvoid}

const CXCompileCommands = Ptr{Cvoid}

const CXCompileCommand = Ptr{Cvoid}

@cenum CXCompilationDatabase_Error::UInt32 begin
    CXCompilationDatabase_NoError = 0
    CXCompilationDatabase_CanNotLoadDatabase = 1
end

function clang_CompilationDatabase_fromDirectory(BuildDir, ErrorCode)
    ccall((:clang_CompilationDatabase_fromDirectory, libclang), CXCompilationDatabase, (Cstring, Ptr{CXCompilationDatabase_Error}), BuildDir, ErrorCode)
end

function clang_CompilationDatabase_dispose(arg1)
    ccall((:clang_CompilationDatabase_dispose, libclang), Cvoid, (CXCompilationDatabase,), arg1)
end

function clang_CompilationDatabase_getCompileCommands(arg1, CompleteFileName)
    ccall((:clang_CompilationDatabase_getCompileCommands, libclang), CXCompileCommands, (CXCompilationDatabase, Cstring), arg1, CompleteFileName)
end

function clang_CompilationDatabase_getAllCompileCommands(arg1)
    ccall((:clang_CompilationDatabase_getAllCompileCommands, libclang), CXCompileCommands, (CXCompilationDatabase,), arg1)
end

function clang_CompileCommands_dispose(arg1)
    ccall((:clang_CompileCommands_dispose, libclang), Cvoid, (CXCompileCommands,), arg1)
end

function clang_CompileCommands_getSize(arg1)
    ccall((:clang_CompileCommands_getSize, libclang), Cuint, (CXCompileCommands,), arg1)
end

function clang_CompileCommands_getCommand(arg1, I)
    ccall((:clang_CompileCommands_getCommand, libclang), CXCompileCommand, (CXCompileCommands, Cuint), arg1, I)
end

function clang_CompileCommand_getDirectory(arg1)
    ccall((:clang_CompileCommand_getDirectory, libclang), CXString, (CXCompileCommand,), arg1)
end

function clang_CompileCommand_getFilename(arg1)
    ccall((:clang_CompileCommand_getFilename, libclang), CXString, (CXCompileCommand,), arg1)
end

function clang_CompileCommand_getNumArgs(arg1)
    ccall((:clang_CompileCommand_getNumArgs, libclang), Cuint, (CXCompileCommand,), arg1)
end

function clang_CompileCommand_getArg(arg1, I)
    ccall((:clang_CompileCommand_getArg, libclang), CXString, (CXCompileCommand, Cuint), arg1, I)
end

function clang_CompileCommand_getNumMappedSources(arg1)
    ccall((:clang_CompileCommand_getNumMappedSources, libclang), Cuint, (CXCompileCommand,), arg1)
end

function clang_CompileCommand_getMappedSourcePath(arg1, I)
    @warn "`clang_CompileCommand_getMappedSourcePath` Left here for backward compatibility.\nNo mapped sources exists in the C++ backend anymore.\nThis function just return Null `CXString`.\nSee:\n- [Remove unused CompilationDatabase::MappedSources](https://reviews.llvm.org/D32351)\n"
    ccall((:clang_CompileCommand_getMappedSourcePath, libclang), CXString, (CXCompileCommand, Cuint), arg1, I)
end

function clang_CompileCommand_getMappedSourceContent(arg1, I)
    @warn "`clang_CompileCommand_getMappedSourceContent` Left here for backward compatibility.\nNo mapped sources exists in the C++ backend anymore.\nThis function just return Null `CXString`.\nSee:\n- [Remove unused CompilationDatabase::MappedSources](https://reviews.llvm.org/D32351)\n"
    ccall((:clang_CompileCommand_getMappedSourceContent, libclang), CXString, (CXCompileCommand, Cuint), arg1, I)
end

function clang_install_aborting_llvm_fatal_error_handler()
    ccall((:clang_install_aborting_llvm_fatal_error_handler, libclang), Cvoid, ())
end

function clang_uninstall_llvm_fatal_error_handler()
    ccall((:clang_uninstall_llvm_fatal_error_handler, libclang), Cvoid, ())
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
