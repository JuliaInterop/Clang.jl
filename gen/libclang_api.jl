# Julia wrapper for header: BuildSystem.h
# Automatically generated using Clang.jl


function clang_getBuildSessionTimestamp()
    ccall((:clang_getBuildSessionTimestamp, libclang), Culonglong, ())
end

function clang_VirtualFileOverlay_create(options)
    ccall((:clang_VirtualFileOverlay_create, libclang), CXVirtualFileOverlay, (UInt32,), options)
end

function clang_VirtualFileOverlay_addFileMapping(arg1, virtualPath, realPath)
    ccall((:clang_VirtualFileOverlay_addFileMapping, libclang), CXErrorCode, (CXVirtualFileOverlay, Cstring, Cstring), arg1, virtualPath, realPath)
end

function clang_VirtualFileOverlay_setCaseSensitivity(arg1, caseSensitive)
    ccall((:clang_VirtualFileOverlay_setCaseSensitivity, libclang), CXErrorCode, (CXVirtualFileOverlay, Cint), arg1, caseSensitive)
end

function clang_VirtualFileOverlay_writeToBuffer(arg1, options, out_buffer_ptr, out_buffer_size)
    ccall((:clang_VirtualFileOverlay_writeToBuffer, libclang), CXErrorCode, (CXVirtualFileOverlay, UInt32, Ptr{Cstring}, Ptr{UInt32}), arg1, options, out_buffer_ptr, out_buffer_size)
end

function clang_free(buffer)
    ccall((:clang_free, libclang), Cvoid, (Ptr{Cvoid},), buffer)
end

function clang_VirtualFileOverlay_dispose(arg1)
    ccall((:clang_VirtualFileOverlay_dispose, libclang), Cvoid, (CXVirtualFileOverlay,), arg1)
end

function clang_ModuleMapDescriptor_create(options)
    ccall((:clang_ModuleMapDescriptor_create, libclang), CXModuleMapDescriptor, (UInt32,), options)
end

function clang_ModuleMapDescriptor_setFrameworkModuleName(arg1, name)
    ccall((:clang_ModuleMapDescriptor_setFrameworkModuleName, libclang), CXErrorCode, (CXModuleMapDescriptor, Cstring), arg1, name)
end

function clang_ModuleMapDescriptor_setUmbrellaHeader(arg1, name)
    ccall((:clang_ModuleMapDescriptor_setUmbrellaHeader, libclang), CXErrorCode, (CXModuleMapDescriptor, Cstring), arg1, name)
end

function clang_ModuleMapDescriptor_writeToBuffer(arg1, options, out_buffer_ptr, out_buffer_size)
    ccall((:clang_ModuleMapDescriptor_writeToBuffer, libclang), CXErrorCode, (CXModuleMapDescriptor, UInt32, Ptr{Cstring}, Ptr{UInt32}), arg1, options, out_buffer_ptr, out_buffer_size)
end

function clang_ModuleMapDescriptor_dispose(arg1)
    ccall((:clang_ModuleMapDescriptor_dispose, libclang), Cvoid, (CXModuleMapDescriptor,), arg1)
end
# Julia wrapper for header: CXCompilationDatabase.h
# Automatically generated using Clang.jl


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
    ccall((:clang_CompileCommands_getSize, libclang), UInt32, (CXCompileCommands,), arg1)
end

function clang_CompileCommands_getCommand(arg1, I)
    ccall((:clang_CompileCommands_getCommand, libclang), CXCompileCommand, (CXCompileCommands, UInt32), arg1, I)
end

function clang_CompileCommand_getDirectory(arg1)
    ccall((:clang_CompileCommand_getDirectory, libclang), CXString, (CXCompileCommand,), arg1)
end

function clang_CompileCommand_getFilename(arg1)
    ccall((:clang_CompileCommand_getFilename, libclang), CXString, (CXCompileCommand,), arg1)
end

function clang_CompileCommand_getNumArgs(arg1)
    ccall((:clang_CompileCommand_getNumArgs, libclang), UInt32, (CXCompileCommand,), arg1)
end

function clang_CompileCommand_getArg(arg1, I)
    ccall((:clang_CompileCommand_getArg, libclang), CXString, (CXCompileCommand, UInt32), arg1, I)
end

function clang_CompileCommand_getNumMappedSources(arg1)
    ccall((:clang_CompileCommand_getNumMappedSources, libclang), UInt32, (CXCompileCommand,), arg1)
end

function clang_CompileCommand_getMappedSourcePath(arg1, I)
    ccall((:clang_CompileCommand_getMappedSourcePath, libclang), CXString, (CXCompileCommand, UInt32), arg1, I)
end

function clang_CompileCommand_getMappedSourceContent(arg1, I)
    ccall((:clang_CompileCommand_getMappedSourceContent, libclang), CXString, (CXCompileCommand, UInt32), arg1, I)
end
# Julia wrapper for header: CXErrorCode.h
# Automatically generated using Clang.jl

# Julia wrapper for header: CXString.h
# Automatically generated using Clang.jl


function clang_getCString(string)
    ccall((:clang_getCString, libclang), Cstring, (CXString,), string)
end

function clang_disposeString(string)
    ccall((:clang_disposeString, libclang), Cvoid, (CXString,), string)
end

function clang_disposeStringSet(set)
    ccall((:clang_disposeStringSet, libclang), Cvoid, (Ptr{CXStringSet},), set)
end
# Julia wrapper for header: Documentation.h
# Automatically generated using Clang.jl


function clang_Cursor_getParsedComment(C)
    ccall((:clang_Cursor_getParsedComment, libclang), CXComment, (CXCursor,), C)
end

function clang_Comment_getKind(Comment)
    ccall((:clang_Comment_getKind, libclang), CXCommentKind, (CXComment,), Comment)
end

function clang_Comment_getNumChildren(Comment)
    ccall((:clang_Comment_getNumChildren, libclang), UInt32, (CXComment,), Comment)
end

function clang_Comment_getChild(Comment, ChildIdx)
    ccall((:clang_Comment_getChild, libclang), CXComment, (CXComment, UInt32), Comment, ChildIdx)
end

function clang_Comment_isWhitespace(Comment)
    ccall((:clang_Comment_isWhitespace, libclang), UInt32, (CXComment,), Comment)
end

function clang_InlineContentComment_hasTrailingNewline(Comment)
    ccall((:clang_InlineContentComment_hasTrailingNewline, libclang), UInt32, (CXComment,), Comment)
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
    ccall((:clang_InlineCommandComment_getNumArgs, libclang), UInt32, (CXComment,), Comment)
end

function clang_InlineCommandComment_getArgText(Comment, ArgIdx)
    ccall((:clang_InlineCommandComment_getArgText, libclang), CXString, (CXComment, UInt32), Comment, ArgIdx)
end

function clang_HTMLTagComment_getTagName(Comment)
    ccall((:clang_HTMLTagComment_getTagName, libclang), CXString, (CXComment,), Comment)
end

function clang_HTMLStartTagComment_isSelfClosing(Comment)
    ccall((:clang_HTMLStartTagComment_isSelfClosing, libclang), UInt32, (CXComment,), Comment)
end

function clang_HTMLStartTag_getNumAttrs(Comment)
    ccall((:clang_HTMLStartTag_getNumAttrs, libclang), UInt32, (CXComment,), Comment)
end

function clang_HTMLStartTag_getAttrName(Comment, AttrIdx)
    ccall((:clang_HTMLStartTag_getAttrName, libclang), CXString, (CXComment, UInt32), Comment, AttrIdx)
end

function clang_HTMLStartTag_getAttrValue(Comment, AttrIdx)
    ccall((:clang_HTMLStartTag_getAttrValue, libclang), CXString, (CXComment, UInt32), Comment, AttrIdx)
end

function clang_BlockCommandComment_getCommandName(Comment)
    ccall((:clang_BlockCommandComment_getCommandName, libclang), CXString, (CXComment,), Comment)
end

function clang_BlockCommandComment_getNumArgs(Comment)
    ccall((:clang_BlockCommandComment_getNumArgs, libclang), UInt32, (CXComment,), Comment)
end

function clang_BlockCommandComment_getArgText(Comment, ArgIdx)
    ccall((:clang_BlockCommandComment_getArgText, libclang), CXString, (CXComment, UInt32), Comment, ArgIdx)
end

function clang_BlockCommandComment_getParagraph(Comment)
    ccall((:clang_BlockCommandComment_getParagraph, libclang), CXComment, (CXComment,), Comment)
end

function clang_ParamCommandComment_getParamName(Comment)
    ccall((:clang_ParamCommandComment_getParamName, libclang), CXString, (CXComment,), Comment)
end

function clang_ParamCommandComment_isParamIndexValid(Comment)
    ccall((:clang_ParamCommandComment_isParamIndexValid, libclang), UInt32, (CXComment,), Comment)
end

function clang_ParamCommandComment_getParamIndex(Comment)
    ccall((:clang_ParamCommandComment_getParamIndex, libclang), UInt32, (CXComment,), Comment)
end

function clang_ParamCommandComment_isDirectionExplicit(Comment)
    ccall((:clang_ParamCommandComment_isDirectionExplicit, libclang), UInt32, (CXComment,), Comment)
end

function clang_ParamCommandComment_getDirection(Comment)
    ccall((:clang_ParamCommandComment_getDirection, libclang), CXCommentParamPassDirection, (CXComment,), Comment)
end

function clang_TParamCommandComment_getParamName(Comment)
    ccall((:clang_TParamCommandComment_getParamName, libclang), CXString, (CXComment,), Comment)
end

function clang_TParamCommandComment_isParamPositionValid(Comment)
    ccall((:clang_TParamCommandComment_isParamPositionValid, libclang), UInt32, (CXComment,), Comment)
end

function clang_TParamCommandComment_getDepth(Comment)
    ccall((:clang_TParamCommandComment_getDepth, libclang), UInt32, (CXComment,), Comment)
end

function clang_TParamCommandComment_getIndex(Comment, Depth)
    ccall((:clang_TParamCommandComment_getIndex, libclang), UInt32, (CXComment, UInt32), Comment, Depth)
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
# Julia wrapper for header: Index.h
# Automatically generated using Clang.jl


function clang_createIndex(excludeDeclarationsFromPCH, displayDiagnostics)
    ccall((:clang_createIndex, libclang), CXIndex, (Cint, Cint), excludeDeclarationsFromPCH, displayDiagnostics)
end

function clang_disposeIndex(index)
    ccall((:clang_disposeIndex, libclang), Cvoid, (CXIndex,), index)
end

function clang_CXIndex_setGlobalOptions(arg1, options)
    ccall((:clang_CXIndex_setGlobalOptions, libclang), Cvoid, (CXIndex, UInt32), arg1, options)
end

function clang_CXIndex_getGlobalOptions(arg1)
    ccall((:clang_CXIndex_getGlobalOptions, libclang), UInt32, (CXIndex,), arg1)
end

function clang_CXIndex_setInvocationEmissionPathOption(arg1, Path)
    ccall((:clang_CXIndex_setInvocationEmissionPathOption, libclang), Cvoid, (CXIndex, Cstring), arg1, Path)
end

function clang_getFileName(SFile)
    ccall((:clang_getFileName, libclang), CXString, (CXFile,), SFile)
end

function clang_getFileTime(SFile)
    ccall((:clang_getFileTime, libclang), Ctime_t, (CXFile,), SFile)
end

function clang_getFileUniqueID(file, outID)
    ccall((:clang_getFileUniqueID, libclang), Cint, (CXFile, Ptr{CXFileUniqueID}), file, outID)
end

function clang_isFileMultipleIncludeGuarded(tu, file)
    ccall((:clang_isFileMultipleIncludeGuarded, libclang), UInt32, (CXTranslationUnit, CXFile), tu, file)
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

function clang_getNullLocation()
    ccall((:clang_getNullLocation, libclang), CXSourceLocation, ())
end

function clang_equalLocations(loc1, loc2)
    ccall((:clang_equalLocations, libclang), UInt32, (CXSourceLocation, CXSourceLocation), loc1, loc2)
end

function clang_getLocation(tu, file, line, column)
    ccall((:clang_getLocation, libclang), CXSourceLocation, (CXTranslationUnit, CXFile, UInt32, UInt32), tu, file, line, column)
end

function clang_getLocationForOffset(tu, file, offset)
    ccall((:clang_getLocationForOffset, libclang), CXSourceLocation, (CXTranslationUnit, CXFile, UInt32), tu, file, offset)
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
    ccall((:clang_equalRanges, libclang), UInt32, (CXSourceRange, CXSourceRange), range1, range2)
end

function clang_Range_isNull(range)
    ccall((:clang_Range_isNull, libclang), Cint, (CXSourceRange,), range)
end

function clang_getExpansionLocation(location, file, line, column, offset)
    ccall((:clang_getExpansionLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXFile}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}), location, file, line, column, offset)
end

function clang_getPresumedLocation(location, filename, line, column)
    ccall((:clang_getPresumedLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXString}, Ptr{UInt32}, Ptr{UInt32}), location, filename, line, column)
end

function clang_getInstantiationLocation(location, file, line, column, offset)
    ccall((:clang_getInstantiationLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXFile}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}), location, file, line, column, offset)
end

function clang_getSpellingLocation(location, file, line, column, offset)
    ccall((:clang_getSpellingLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXFile}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}), location, file, line, column, offset)
end

function clang_getFileLocation(location, file, line, column, offset)
    ccall((:clang_getFileLocation, libclang), Cvoid, (CXSourceLocation, Ptr{CXFile}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}), location, file, line, column, offset)
end

function clang_getRangeStart(range)
    ccall((:clang_getRangeStart, libclang), CXSourceLocation, (CXSourceRange,), range)
end

function clang_getRangeEnd(range)
    ccall((:clang_getRangeEnd, libclang), CXSourceLocation, (CXSourceRange,), range)
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

function clang_getNumDiagnosticsInSet(Diags)
    ccall((:clang_getNumDiagnosticsInSet, libclang), UInt32, (CXDiagnosticSet,), Diags)
end

function clang_getDiagnosticInSet(Diags, Index)
    ccall((:clang_getDiagnosticInSet, libclang), CXDiagnostic, (CXDiagnosticSet, UInt32), Diags, Index)
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
    ccall((:clang_getNumDiagnostics, libclang), UInt32, (CXTranslationUnit,), Unit)
end

function clang_getDiagnostic(Unit, Index)
    ccall((:clang_getDiagnostic, libclang), CXDiagnostic, (CXTranslationUnit, UInt32), Unit, Index)
end

function clang_getDiagnosticSetFromTU(Unit)
    ccall((:clang_getDiagnosticSetFromTU, libclang), CXDiagnosticSet, (CXTranslationUnit,), Unit)
end

function clang_disposeDiagnostic(Diagnostic)
    ccall((:clang_disposeDiagnostic, libclang), Cvoid, (CXDiagnostic,), Diagnostic)
end

function clang_formatDiagnostic(Diagnostic, Options)
    ccall((:clang_formatDiagnostic, libclang), CXString, (CXDiagnostic, UInt32), Diagnostic, Options)
end

function clang_defaultDiagnosticDisplayOptions()
    ccall((:clang_defaultDiagnosticDisplayOptions, libclang), UInt32, ())
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
    ccall((:clang_getDiagnosticCategory, libclang), UInt32, (CXDiagnostic,), arg1)
end

function clang_getDiagnosticCategoryName(Category)
    ccall((:clang_getDiagnosticCategoryName, libclang), CXString, (UInt32,), Category)
end

function clang_getDiagnosticCategoryText(arg1)
    ccall((:clang_getDiagnosticCategoryText, libclang), CXString, (CXDiagnostic,), arg1)
end

function clang_getDiagnosticNumRanges(arg1)
    ccall((:clang_getDiagnosticNumRanges, libclang), UInt32, (CXDiagnostic,), arg1)
end

function clang_getDiagnosticRange(Diagnostic, Range)
    ccall((:clang_getDiagnosticRange, libclang), CXSourceRange, (CXDiagnostic, UInt32), Diagnostic, Range)
end

function clang_getDiagnosticNumFixIts(Diagnostic)
    ccall((:clang_getDiagnosticNumFixIts, libclang), UInt32, (CXDiagnostic,), Diagnostic)
end

function clang_getDiagnosticFixIt(Diagnostic, FixIt, ReplacementRange)
    ccall((:clang_getDiagnosticFixIt, libclang), CXString, (CXDiagnostic, UInt32, Ptr{CXSourceRange}), Diagnostic, FixIt, ReplacementRange)
end

function clang_getTranslationUnitSpelling(CTUnit)
    ccall((:clang_getTranslationUnitSpelling, libclang), CXString, (CXTranslationUnit,), CTUnit)
end

function clang_createTranslationUnitFromSourceFile(CIdx, source_filename, num_clang_command_line_args, clang_command_line_args, num_unsaved_files, unsaved_files)
    ccall((:clang_createTranslationUnitFromSourceFile, libclang), CXTranslationUnit, (CXIndex, Cstring, Cint, Ptr{Cstring}, UInt32, Ptr{CXUnsavedFile}), CIdx, source_filename, num_clang_command_line_args, clang_command_line_args, num_unsaved_files, unsaved_files)
end

function clang_createTranslationUnit(CIdx, ast_filename)
    ccall((:clang_createTranslationUnit, libclang), CXTranslationUnit, (CXIndex, Cstring), CIdx, ast_filename)
end

function clang_createTranslationUnit2(CIdx, ast_filename, out_TU)
    ccall((:clang_createTranslationUnit2, libclang), CXErrorCode, (CXIndex, Cstring, Ptr{CXTranslationUnit}), CIdx, ast_filename, out_TU)
end

function clang_defaultEditingTranslationUnitOptions()
    ccall((:clang_defaultEditingTranslationUnitOptions, libclang), UInt32, ())
end

function clang_parseTranslationUnit(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options)
    ccall((:clang_parseTranslationUnit, libclang), CXTranslationUnit, (CXIndex, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, UInt32, UInt32), CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options)
end

function clang_parseTranslationUnit2(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
    ccall((:clang_parseTranslationUnit2, libclang), CXErrorCode, (CXIndex, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, UInt32, UInt32, Ptr{CXTranslationUnit}), CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
end

function clang_parseTranslationUnit2FullArgv(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
    ccall((:clang_parseTranslationUnit2FullArgv, libclang), CXErrorCode, (CXIndex, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, UInt32, UInt32, Ptr{CXTranslationUnit}), CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
end

function clang_defaultSaveOptions(TU)
    ccall((:clang_defaultSaveOptions, libclang), UInt32, (CXTranslationUnit,), TU)
end

function clang_saveTranslationUnit(TU, FileName, options)
    ccall((:clang_saveTranslationUnit, libclang), Cint, (CXTranslationUnit, Cstring, UInt32), TU, FileName, options)
end

function clang_suspendTranslationUnit(arg1)
    ccall((:clang_suspendTranslationUnit, libclang), UInt32, (CXTranslationUnit,), arg1)
end

function clang_disposeTranslationUnit(arg1)
    ccall((:clang_disposeTranslationUnit, libclang), Cvoid, (CXTranslationUnit,), arg1)
end

function clang_defaultReparseOptions(TU)
    ccall((:clang_defaultReparseOptions, libclang), UInt32, (CXTranslationUnit,), TU)
end

function clang_reparseTranslationUnit(TU, num_unsaved_files, unsaved_files, options)
    ccall((:clang_reparseTranslationUnit, libclang), Cint, (CXTranslationUnit, UInt32, Ptr{CXUnsavedFile}, UInt32), TU, num_unsaved_files, unsaved_files, options)
end

function clang_getTUResourceUsageName(kind)
    ccall((:clang_getTUResourceUsageName, libclang), Cstring, (CXTUResourceUsageKind,), kind)
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

function clang_getNullCursor()
    ccall((:clang_getNullCursor, libclang), CXCursor, ())
end

function clang_getTranslationUnitCursor(arg1)
    ccall((:clang_getTranslationUnitCursor, libclang), CXCursor, (CXTranslationUnit,), arg1)
end

function clang_equalCursors(arg1, arg2)
    ccall((:clang_equalCursors, libclang), UInt32, (CXCursor, CXCursor), arg1, arg2)
end

function clang_Cursor_isNull(cursor)
    ccall((:clang_Cursor_isNull, libclang), Cint, (CXCursor,), cursor)
end

function clang_hashCursor(arg1)
    ccall((:clang_hashCursor, libclang), UInt32, (CXCursor,), arg1)
end

function clang_getCursorKind(arg1)
    ccall((:clang_getCursorKind, libclang), CXCursorKind, (CXCursor,), arg1)
end

function clang_isDeclaration(arg1)
    ccall((:clang_isDeclaration, libclang), UInt32, (CXCursorKind,), arg1)
end

function clang_isReference(arg1)
    ccall((:clang_isReference, libclang), UInt32, (CXCursorKind,), arg1)
end

function clang_isExpression(arg1)
    ccall((:clang_isExpression, libclang), UInt32, (CXCursorKind,), arg1)
end

function clang_isStatement(arg1)
    ccall((:clang_isStatement, libclang), UInt32, (CXCursorKind,), arg1)
end

function clang_isAttribute(arg1)
    ccall((:clang_isAttribute, libclang), UInt32, (CXCursorKind,), arg1)
end

function clang_Cursor_hasAttrs(C)
    ccall((:clang_Cursor_hasAttrs, libclang), UInt32, (CXCursor,), C)
end

function clang_isInvalid(arg1)
    ccall((:clang_isInvalid, libclang), UInt32, (CXCursorKind,), arg1)
end

function clang_isTranslationUnit(arg1)
    ccall((:clang_isTranslationUnit, libclang), UInt32, (CXCursorKind,), arg1)
end

function clang_isPreprocessing(arg1)
    ccall((:clang_isPreprocessing, libclang), UInt32, (CXCursorKind,), arg1)
end

function clang_isUnexposed(arg1)
    ccall((:clang_isUnexposed, libclang), UInt32, (CXCursorKind,), arg1)
end

function clang_getCursorLinkage(cursor)
    ccall((:clang_getCursorLinkage, libclang), CXLinkageKind, (CXCursor,), cursor)
end

function clang_getCursorVisibility(cursor)
    ccall((:clang_getCursorVisibility, libclang), CXVisibilityKind, (CXCursor,), cursor)
end

function clang_getCursorAvailability(cursor)
    ccall((:clang_getCursorAvailability, libclang), CXAvailabilityKind, (CXCursor,), cursor)
end

function clang_getCursorPlatformAvailability(cursor, always_deprecated, deprecated_message, always_unavailable, unavailable_message, availability, availability_size)
    ccall((:clang_getCursorPlatformAvailability, libclang), Cint, (CXCursor, Ptr{Cint}, Ptr{CXString}, Ptr{Cint}, Ptr{CXString}, Ptr{CXPlatformAvailability}, Cint), cursor, always_deprecated, deprecated_message, always_unavailable, unavailable_message, availability, availability_size)
end

function clang_disposeCXPlatformAvailability(availability)
    ccall((:clang_disposeCXPlatformAvailability, libclang), Cvoid, (Ptr{CXPlatformAvailability},), availability)
end

function clang_getCursorLanguage(cursor)
    ccall((:clang_getCursorLanguage, libclang), CXLanguageKind, (CXCursor,), cursor)
end

function clang_getCursorTLSKind(cursor)
    ccall((:clang_getCursorTLSKind, libclang), CXTLSKind, (CXCursor,), cursor)
end

function clang_Cursor_getTranslationUnit(arg1)
    ccall((:clang_Cursor_getTranslationUnit, libclang), CXTranslationUnit, (CXCursor,), arg1)
end

function clang_createCXCursorSet()
    ccall((:clang_createCXCursorSet, libclang), CXCursorSet, ())
end

function clang_disposeCXCursorSet(cset)
    ccall((:clang_disposeCXCursorSet, libclang), Cvoid, (CXCursorSet,), cset)
end

function clang_CXCursorSet_contains(cset, cursor)
    ccall((:clang_CXCursorSet_contains, libclang), UInt32, (CXCursorSet, CXCursor), cset, cursor)
end

function clang_CXCursorSet_insert(cset, cursor)
    ccall((:clang_CXCursorSet_insert, libclang), UInt32, (CXCursorSet, CXCursor), cset, cursor)
end

function clang_getCursorSemanticParent(cursor)
    ccall((:clang_getCursorSemanticParent, libclang), CXCursor, (CXCursor,), cursor)
end

function clang_getCursorLexicalParent(cursor)
    ccall((:clang_getCursorLexicalParent, libclang), CXCursor, (CXCursor,), cursor)
end

function clang_getOverriddenCursors(cursor, overridden, num_overridden)
    ccall((:clang_getOverriddenCursors, libclang), Cvoid, (CXCursor, Ptr{Ptr{CXCursor}}, Ptr{UInt32}), cursor, overridden, num_overridden)
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
    ccall((:clang_Cursor_getArgument, libclang), CXCursor, (CXCursor, UInt32), C, i)
end

function clang_Cursor_getNumTemplateArguments(C)
    ccall((:clang_Cursor_getNumTemplateArguments, libclang), Cint, (CXCursor,), C)
end

function clang_Cursor_getTemplateArgumentKind(C, I)
    ccall((:clang_Cursor_getTemplateArgumentKind, libclang), CXTemplateArgumentKind, (CXCursor, UInt32), C, I)
end

function clang_Cursor_getTemplateArgumentType(C, I)
    ccall((:clang_Cursor_getTemplateArgumentType, libclang), CXType, (CXCursor, UInt32), C, I)
end

function clang_Cursor_getTemplateArgumentValue(C, I)
    ccall((:clang_Cursor_getTemplateArgumentValue, libclang), Clonglong, (CXCursor, UInt32), C, I)
end

function clang_Cursor_getTemplateArgumentUnsignedValue(C, I)
    ccall((:clang_Cursor_getTemplateArgumentUnsignedValue, libclang), Culonglong, (CXCursor, UInt32), C, I)
end

function clang_equalTypes(A, B)
    ccall((:clang_equalTypes, libclang), UInt32, (CXType, CXType), A, B)
end

function clang_getCanonicalType(T)
    ccall((:clang_getCanonicalType, libclang), CXType, (CXType,), T)
end

function clang_isConstQualifiedType(T)
    ccall((:clang_isConstQualifiedType, libclang), UInt32, (CXType,), T)
end

function clang_Cursor_isMacroFunctionLike(C)
    ccall((:clang_Cursor_isMacroFunctionLike, libclang), UInt32, (CXCursor,), C)
end

function clang_Cursor_isMacroBuiltin(C)
    ccall((:clang_Cursor_isMacroBuiltin, libclang), UInt32, (CXCursor,), C)
end

function clang_Cursor_isFunctionInlined(C)
    ccall((:clang_Cursor_isFunctionInlined, libclang), UInt32, (CXCursor,), C)
end

function clang_isVolatileQualifiedType(T)
    ccall((:clang_isVolatileQualifiedType, libclang), UInt32, (CXType,), T)
end

function clang_isRestrictQualifiedType(T)
    ccall((:clang_isRestrictQualifiedType, libclang), UInt32, (CXType,), T)
end

function clang_getAddressSpace(T)
    ccall((:clang_getAddressSpace, libclang), UInt32, (CXType,), T)
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
    ccall((:clang_getArgType, libclang), CXType, (CXType, UInt32), T, i)
end

function clang_isFunctionTypeVariadic(T)
    ccall((:clang_isFunctionTypeVariadic, libclang), UInt32, (CXType,), T)
end

function clang_getCursorResultType(C)
    ccall((:clang_getCursorResultType, libclang), CXType, (CXCursor,), C)
end

function clang_getCursorExceptionSpecificationType(C)
    ccall((:clang_getCursorExceptionSpecificationType, libclang), Cint, (CXCursor,), C)
end

function clang_isPODType(T)
    ccall((:clang_isPODType, libclang), UInt32, (CXType,), T)
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
    ccall((:clang_Type_isTransparentTagTypedef, libclang), UInt32, (CXType,), T)
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

function clang_Cursor_getOffsetOfField(C)
    ccall((:clang_Cursor_getOffsetOfField, libclang), Clonglong, (CXCursor,), C)
end

function clang_Cursor_isAnonymous(C)
    ccall((:clang_Cursor_isAnonymous, libclang), UInt32, (CXCursor,), C)
end

function clang_Type_getNumTemplateArguments(T)
    ccall((:clang_Type_getNumTemplateArguments, libclang), Cint, (CXType,), T)
end

function clang_Type_getTemplateArgumentAsType(T, i)
    ccall((:clang_Type_getTemplateArgumentAsType, libclang), CXType, (CXType, UInt32), T, i)
end

function clang_Type_getCXXRefQualifier(T)
    ccall((:clang_Type_getCXXRefQualifier, libclang), CXRefQualifierKind, (CXType,), T)
end

function clang_Cursor_isBitField(C)
    ccall((:clang_Cursor_isBitField, libclang), UInt32, (CXCursor,), C)
end

function clang_isVirtualBase(arg1)
    ccall((:clang_isVirtualBase, libclang), UInt32, (CXCursor,), arg1)
end

function clang_getCXXAccessSpecifier(arg1)
    ccall((:clang_getCXXAccessSpecifier, libclang), CX_CXXAccessSpecifier, (CXCursor,), arg1)
end

function clang_Cursor_getStorageClass(arg1)
    ccall((:clang_Cursor_getStorageClass, libclang), CX_StorageClass, (CXCursor,), arg1)
end

function clang_getNumOverloadedDecls(cursor)
    ccall((:clang_getNumOverloadedDecls, libclang), UInt32, (CXCursor,), cursor)
end

function clang_getOverloadedDecl(cursor, index)
    ccall((:clang_getOverloadedDecl, libclang), CXCursor, (CXCursor, UInt32), cursor, index)
end

function clang_getIBOutletCollectionType(arg1)
    ccall((:clang_getIBOutletCollectionType, libclang), CXType, (CXCursor,), arg1)
end

function clang_visitChildren(parent, visitor, client_data)
    ccall((:clang_visitChildren, libclang), UInt32, (CXCursor, CXCursorVisitor, CXClientData), parent, visitor, client_data)
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
    ccall((:clang_constructUSR_ObjCMethod, libclang), CXString, (Cstring, UInt32, CXString), name, isInstanceMethod, classUSR)
end

function clang_constructUSR_ObjCProperty(property, classUSR)
    ccall((:clang_constructUSR_ObjCProperty, libclang), CXString, (Cstring, CXString), property, classUSR)
end

function clang_getCursorSpelling(arg1)
    ccall((:clang_getCursorSpelling, libclang), CXString, (CXCursor,), arg1)
end

function clang_Cursor_getSpellingNameRange(arg1, pieceIndex, options)
    ccall((:clang_Cursor_getSpellingNameRange, libclang), CXSourceRange, (CXCursor, UInt32, UInt32), arg1, pieceIndex, options)
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
    ccall((:clang_isCursorDefinition, libclang), UInt32, (CXCursor,), arg1)
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

function clang_Cursor_getObjCPropertyAttributes(C, reserved)
    ccall((:clang_Cursor_getObjCPropertyAttributes, libclang), UInt32, (CXCursor, UInt32), C, reserved)
end

function clang_Cursor_getObjCDeclQualifiers(C)
    ccall((:clang_Cursor_getObjCDeclQualifiers, libclang), UInt32, (CXCursor,), C)
end

function clang_Cursor_isObjCOptional(C)
    ccall((:clang_Cursor_isObjCOptional, libclang), UInt32, (CXCursor,), C)
end

function clang_Cursor_isVariadic(C)
    ccall((:clang_Cursor_isVariadic, libclang), UInt32, (CXCursor,), C)
end

function clang_Cursor_isExternalSymbol(C, language, definedIn, isGenerated)
    ccall((:clang_Cursor_isExternalSymbol, libclang), UInt32, (CXCursor, Ptr{CXString}, Ptr{CXString}, Ptr{UInt32}), C, language, definedIn, isGenerated)
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
    ccall((:clang_Module_getNumTopLevelHeaders, libclang), UInt32, (CXTranslationUnit, CXModule), arg1, Module)
end

function clang_Module_getTopLevelHeader(arg1, Module, Index)
    ccall((:clang_Module_getTopLevelHeader, libclang), CXFile, (CXTranslationUnit, CXModule, UInt32), arg1, Module, Index)
end

function clang_CXXConstructor_isConvertingConstructor(C)
    ccall((:clang_CXXConstructor_isConvertingConstructor, libclang), UInt32, (CXCursor,), C)
end

function clang_CXXConstructor_isCopyConstructor(C)
    ccall((:clang_CXXConstructor_isCopyConstructor, libclang), UInt32, (CXCursor,), C)
end

function clang_CXXConstructor_isDefaultConstructor(C)
    ccall((:clang_CXXConstructor_isDefaultConstructor, libclang), UInt32, (CXCursor,), C)
end

function clang_CXXConstructor_isMoveConstructor(C)
    ccall((:clang_CXXConstructor_isMoveConstructor, libclang), UInt32, (CXCursor,), C)
end

function clang_CXXField_isMutable(C)
    ccall((:clang_CXXField_isMutable, libclang), UInt32, (CXCursor,), C)
end

function clang_CXXMethod_isDefaulted(C)
    ccall((:clang_CXXMethod_isDefaulted, libclang), UInt32, (CXCursor,), C)
end

function clang_CXXMethod_isPureVirtual(C)
    ccall((:clang_CXXMethod_isPureVirtual, libclang), UInt32, (CXCursor,), C)
end

function clang_CXXMethod_isStatic(C)
    ccall((:clang_CXXMethod_isStatic, libclang), UInt32, (CXCursor,), C)
end

function clang_CXXMethod_isVirtual(C)
    ccall((:clang_CXXMethod_isVirtual, libclang), UInt32, (CXCursor,), C)
end

function clang_CXXRecord_isAbstract(C)
    ccall((:clang_CXXRecord_isAbstract, libclang), UInt32, (CXCursor,), C)
end

function clang_EnumDecl_isScoped(C)
    ccall((:clang_EnumDecl_isScoped, libclang), UInt32, (CXCursor,), C)
end

function clang_CXXMethod_isConst(C)
    ccall((:clang_CXXMethod_isConst, libclang), UInt32, (CXCursor,), C)
end

function clang_getTemplateCursorKind(C)
    ccall((:clang_getTemplateCursorKind, libclang), CXCursorKind, (CXCursor,), C)
end

function clang_getSpecializedCursorTemplate(C)
    ccall((:clang_getSpecializedCursorTemplate, libclang), CXCursor, (CXCursor,), C)
end

function clang_getCursorReferenceNameRange(C, NameFlags, PieceIndex)
    ccall((:clang_getCursorReferenceNameRange, libclang), CXSourceRange, (CXCursor, UInt32, UInt32), C, NameFlags, PieceIndex)
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
    ccall((:clang_tokenize, libclang), Cvoid, (CXTranslationUnit, CXSourceRange, Ptr{Ptr{CXToken}}, Ptr{UInt32}), TU, Range, Tokens, NumTokens)
end

function clang_annotateTokens(TU, Tokens, NumTokens, Cursors)
    ccall((:clang_annotateTokens, libclang), Cvoid, (CXTranslationUnit, Ptr{CXToken}, UInt32, Ptr{CXCursor}), TU, Tokens, NumTokens, Cursors)
end

function clang_disposeTokens(TU, Tokens, NumTokens)
    ccall((:clang_disposeTokens, libclang), Cvoid, (CXTranslationUnit, Ptr{CXToken}, UInt32), TU, Tokens, NumTokens)
end

function clang_getCursorKindSpelling(Kind)
    ccall((:clang_getCursorKindSpelling, libclang), CXString, (CXCursorKind,), Kind)
end

function clang_getDefinitionSpellingAndExtent(arg1, startBuf, endBuf, startLine, startColumn, endLine, endColumn)
    ccall((:clang_getDefinitionSpellingAndExtent, libclang), Cvoid, (CXCursor, Ptr{Cstring}, Ptr{Cstring}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}), arg1, startBuf, endBuf, startLine, startColumn, endLine, endColumn)
end

function clang_enableStackTraces()
    ccall((:clang_enableStackTraces, libclang), Cvoid, ())
end

function clang_executeOnThread(fn, user_data, stack_size)
    ccall((:clang_executeOnThread, libclang), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}, UInt32), fn, user_data, stack_size)
end

function clang_getCompletionChunkKind(completion_string, chunk_number)
    ccall((:clang_getCompletionChunkKind, libclang), CXCompletionChunkKind, (CXCompletionString, UInt32), completion_string, chunk_number)
end

function clang_getCompletionChunkText(completion_string, chunk_number)
    ccall((:clang_getCompletionChunkText, libclang), CXString, (CXCompletionString, UInt32), completion_string, chunk_number)
end

function clang_getCompletionChunkCompletionString(completion_string, chunk_number)
    ccall((:clang_getCompletionChunkCompletionString, libclang), CXCompletionString, (CXCompletionString, UInt32), completion_string, chunk_number)
end

function clang_getNumCompletionChunks(completion_string)
    ccall((:clang_getNumCompletionChunks, libclang), UInt32, (CXCompletionString,), completion_string)
end

function clang_getCompletionPriority(completion_string)
    ccall((:clang_getCompletionPriority, libclang), UInt32, (CXCompletionString,), completion_string)
end

function clang_getCompletionAvailability(completion_string)
    ccall((:clang_getCompletionAvailability, libclang), CXAvailabilityKind, (CXCompletionString,), completion_string)
end

function clang_getCompletionNumAnnotations(completion_string)
    ccall((:clang_getCompletionNumAnnotations, libclang), UInt32, (CXCompletionString,), completion_string)
end

function clang_getCompletionAnnotation(completion_string, annotation_number)
    ccall((:clang_getCompletionAnnotation, libclang), CXString, (CXCompletionString, UInt32), completion_string, annotation_number)
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

function clang_defaultCodeCompleteOptions()
    ccall((:clang_defaultCodeCompleteOptions, libclang), UInt32, ())
end

function clang_codeCompleteAt(TU, complete_filename, complete_line, complete_column, unsaved_files, num_unsaved_files, options)
    ccall((:clang_codeCompleteAt, libclang), Ptr{CXCodeCompleteResults}, (CXTranslationUnit, Cstring, UInt32, UInt32, Ptr{CXUnsavedFile}, UInt32, UInt32), TU, complete_filename, complete_line, complete_column, unsaved_files, num_unsaved_files, options)
end

function clang_sortCodeCompletionResults(Results, NumResults)
    ccall((:clang_sortCodeCompletionResults, libclang), Cvoid, (Ptr{CXCompletionResult}, UInt32), Results, NumResults)
end

function clang_disposeCodeCompleteResults(Results)
    ccall((:clang_disposeCodeCompleteResults, libclang), Cvoid, (Ptr{CXCodeCompleteResults},), Results)
end

function clang_codeCompleteGetNumDiagnostics(Results)
    ccall((:clang_codeCompleteGetNumDiagnostics, libclang), UInt32, (Ptr{CXCodeCompleteResults},), Results)
end

function clang_codeCompleteGetDiagnostic(Results, Index)
    ccall((:clang_codeCompleteGetDiagnostic, libclang), CXDiagnostic, (Ptr{CXCodeCompleteResults}, UInt32), Results, Index)
end

function clang_codeCompleteGetContexts(Results)
    ccall((:clang_codeCompleteGetContexts, libclang), Culonglong, (Ptr{CXCodeCompleteResults},), Results)
end

function clang_codeCompleteGetContainerKind(Results, IsIncomplete)
    ccall((:clang_codeCompleteGetContainerKind, libclang), CXCursorKind, (Ptr{CXCodeCompleteResults}, Ptr{UInt32}), Results, IsIncomplete)
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
    ccall((:clang_toggleCrashRecovery, libclang), Cvoid, (UInt32,), isEnabled)
end

function clang_getInclusions(tu, visitor, client_data)
    ccall((:clang_getInclusions, libclang), Cvoid, (CXTranslationUnit, CXInclusionVisitor, CXClientData), tu, visitor, client_data)
end

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
    ccall((:clang_EvalResult_isUnsignedInt, libclang), UInt32, (CXEvalResult,), E)
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

function clang_getRemappings(path)
    ccall((:clang_getRemappings, libclang), CXRemapping, (Cstring,), path)
end

function clang_getRemappingsFromFileList(filePaths, numFiles)
    ccall((:clang_getRemappingsFromFileList, libclang), CXRemapping, (Ptr{Cstring}, UInt32), filePaths, numFiles)
end

function clang_remap_getNumFiles(arg1)
    ccall((:clang_remap_getNumFiles, libclang), UInt32, (CXRemapping,), arg1)
end

function clang_remap_getFilenames(arg1, index, original, transformed)
    ccall((:clang_remap_getFilenames, libclang), Cvoid, (CXRemapping, UInt32, Ptr{CXString}, Ptr{CXString}), arg1, index, original, transformed)
end

function clang_remap_dispose(arg1)
    ccall((:clang_remap_dispose, libclang), Cvoid, (CXRemapping,), arg1)
end

function clang_findReferencesInFile(cursor, file, visitor)
    ccall((:clang_findReferencesInFile, libclang), CXResult, (CXCursor, CXFile, CXCursorAndRangeVisitor), cursor, file, visitor)
end

function clang_findIncludesInFile(TU, file, visitor)
    ccall((:clang_findIncludesInFile, libclang), CXResult, (CXTranslationUnit, CXFile, CXCursorAndRangeVisitor), TU, file, visitor)
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

function clang_IndexAction_create(CIdx)
    ccall((:clang_IndexAction_create, libclang), CXIndexAction, (CXIndex,), CIdx)
end

function clang_IndexAction_dispose(arg1)
    ccall((:clang_IndexAction_dispose, libclang), Cvoid, (CXIndexAction,), arg1)
end

function clang_indexSourceFile(arg1, client_data, index_callbacks, index_callbacks_size, index_options, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, out_TU, TU_options)
    ccall((:clang_indexSourceFile, libclang), Cint, (CXIndexAction, CXClientData, Ptr{IndexerCallbacks}, UInt32, UInt32, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, UInt32, Ptr{CXTranslationUnit}, UInt32), arg1, client_data, index_callbacks, index_callbacks_size, index_options, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, out_TU, TU_options)
end

function clang_indexSourceFileFullArgv(arg1, client_data, index_callbacks, index_callbacks_size, index_options, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, out_TU, TU_options)
    ccall((:clang_indexSourceFileFullArgv, libclang), Cint, (CXIndexAction, CXClientData, Ptr{IndexerCallbacks}, UInt32, UInt32, Cstring, Ptr{Cstring}, Cint, Ptr{CXUnsavedFile}, UInt32, Ptr{CXTranslationUnit}, UInt32), arg1, client_data, index_callbacks, index_callbacks_size, index_options, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, out_TU, TU_options)
end

function clang_indexTranslationUnit(arg1, client_data, index_callbacks, index_callbacks_size, index_options, arg2)
    ccall((:clang_indexTranslationUnit, libclang), Cint, (CXIndexAction, CXClientData, Ptr{IndexerCallbacks}, UInt32, UInt32, CXTranslationUnit), arg1, client_data, index_callbacks, index_callbacks_size, index_options, arg2)
end

function clang_indexLoc_getFileLocation(loc, indexFile, file, line, column, offset)
    ccall((:clang_indexLoc_getFileLocation, libclang), Cvoid, (CXIdxLoc, Ptr{CXIdxClientFile}, Ptr{CXFile}, Ptr{UInt32}, Ptr{UInt32}, Ptr{UInt32}), loc, indexFile, file, line, column, offset)
end

function clang_indexLoc_getCXSourceLocation(loc)
    ccall((:clang_indexLoc_getCXSourceLocation, libclang), CXSourceLocation, (CXIdxLoc,), loc)
end

function clang_Type_visitFields(T, visitor, client_data)
    ccall((:clang_Type_visitFields, libclang), UInt32, (CXType, CXFieldVisitor, CXClientData), T, visitor, client_data)
end
# Julia wrapper for header: Platform.h
# Automatically generated using Clang.jl

