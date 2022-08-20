module LibClang

using Clang_jll
export Clang_jll

using CEnum

const Ctime_t = Int


const CXCompilationDatabase = Ptr{Cint}

"""
Contains the results of a search in the compilation database

When searching for the compile command for a file, the compilation db can return several commands, as the file may have been compiled with different options in different places of the project. This choice of compile commands is wrapped in this opaque data structure. It must be freed by [`clang_CompileCommands_dispose`](@ref).
"""
const CXCompileCommands = Ptr{Cvoid}

"""
Represents the command line invocation to compile a specific file.
"""
const CXCompileCommand = Ptr{Cvoid}

"""
    CXCompilationDatabase_Error

Error codes for Compilation Database
"""
@cenum CXCompilationDatabase_Error::UInt32 begin
    CXCompilationDatabase_NoError = 0
    CXCompilationDatabase_CanNotLoadDatabase = 1
end

function clang_CompilationDatabase_dispose(arg1)
    @ccall libclang.clang_CompilationDatabase_dispose(arg1::CXCompilationDatabase)::Cint
end

function clang_CompileCommands_dispose(arg1)
    @ccall libclang.clang_CompileCommands_dispose(arg1::CXCompileCommands)::Cint
end

function clang_CompileCommands_getSize(arg1)
    @ccall libclang.clang_CompileCommands_getSize(arg1::CXCompileCommands)::Cint
end

function clang_CompileCommand_getNumArgs(arg1)
    @ccall libclang.clang_CompileCommand_getNumArgs(arg1::CXCompileCommand)::Cint
end

function clang_CompileCommand_getNumMappedSources(arg1)
    @ccall libclang.clang_CompileCommand_getNumMappedSources(arg1::CXCompileCommand)::Cint
end

function clang_install_aborting_llvm_fatal_error_handler()
    @ccall libclang.clang_install_aborting_llvm_fatal_error_handler()::Cint
end

"""
    clang_uninstall_llvm_fatal_error_handler()

Removes currently installed error handler (if any). If no error handler is intalled, the default strategy is to print error message to stderr and call exit(1).
"""
function clang_uninstall_llvm_fatal_error_handler()
    @ccall libclang.clang_uninstall_llvm_fatal_error_handler()::Cvoid
end

"""
    CXErrorCode

Error codes returned by libclang routines.

Zero (`CXError_Success`) is the only error code indicating success. Other error codes, including not yet assigned non-zero values, indicate errors.

| Enumerator                 | Note                                                                                                                                              |
| :------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------ |
| CXError\\_Success          | No error.                                                                                                                                         |
| CXError\\_Failure          | A generic error code, no further details are available.  Errors of this kind can get their own specific error codes in future libclang versions.  |
| CXError\\_Crashed          | libclang crashed while performing the requested operation.                                                                                        |
| CXError\\_InvalidArguments | The function detected that the arguments violate the function contract.                                                                           |
| CXError\\_ASTReadError     | An AST deserialization error has occurred.                                                                                                        |
"""
@cenum CXErrorCode::UInt32 begin
    CXError_Success = 0
    CXError_Failure = 1
    CXError_Crashed = 2
    CXError_InvalidArguments = 3
    CXError_ASTReadError = 4
end

const CXRewriter = Ptr{Cint}

function clang_CXRewriter_insertTextBefore(Rew, Loc, Insert)
    @ccall libclang.clang_CXRewriter_insertTextBefore(Rew::CXRewriter, Loc::Cint, Insert::Cstring)::Cint
end

function clang_CXRewriter_replaceText(Rew, ToBeReplaced, Replacement)
    @ccall libclang.clang_CXRewriter_replaceText(Rew::CXRewriter, ToBeReplaced::Cint, Replacement::Cstring)::Cint
end

function clang_CXRewriter_removeText(Rew, ToBeRemoved)
    @ccall libclang.clang_CXRewriter_removeText(Rew::CXRewriter, ToBeRemoved::Cint)::Cint
end

function clang_CXRewriter_overwriteChangedFiles(Rew)
    @ccall libclang.clang_CXRewriter_overwriteChangedFiles(Rew::CXRewriter)::Cint
end

function clang_CXRewriter_writeMainFileToStdOut(Rew)
    @ccall libclang.clang_CXRewriter_writeMainFileToStdOut(Rew::CXRewriter)::Cint
end

function clang_CXRewriter_dispose(Rew)
    @ccall libclang.clang_CXRewriter_dispose(Rew::CXRewriter)::Cint
end

"""
    CXCommentKind

Describes the type of the comment AST node (`CXComment`). A comment node can be considered block content (e. g., paragraph), inline content (plain text) or neither (the root AST node).

| Enumerator                       | Note                                                                                                                                                                                                                                                                                                                                                                                                          |
| :------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| CXComment\\_Null                 | Null comment. No AST node is constructed at the requested location because there is no text or a syntax error.                                                                                                                                                                                                                                                                                                |
| CXComment\\_Text                 | Plain text. Inline content.                                                                                                                                                                                                                                                                                                                                                                                   |
| CXComment\\_InlineCommand        | A command with word-like arguments that is considered inline content.  For example: \\c command.                                                                                                                                                                                                                                                                                                              |
| CXComment\\_HTMLStartTag         | HTML start tag with attributes (name-value pairs). Considered inline content.  For example:  ```c++  <br> <br /> <a href="http://example.org/"> ```                                                                                                                                                                                                                                                           |
| CXComment\\_HTMLEndTag           | HTML end tag. Considered inline content.  For example:  ```c++  </a> ```                                                                                                                                                                                                                                                                                                                                      |
| CXComment\\_Paragraph            | A paragraph, contains inline comment. The paragraph itself is block content.                                                                                                                                                                                                                                                                                                                                  |
| CXComment\\_BlockCommand         | A command that has zero or more word-like arguments (number of word-like arguments depends on command name) and a paragraph as an argument. Block command is block content.  Paragraph argument is also a child of the block command.  For example:  0 word-like arguments and a paragraph argument.  AST nodes of special kinds that parser knows about (e. g., \\param command) have their own node kinds.  |
| CXComment\\_ParamCommand         | A \\param or \\arg command that describes the function parameter (name, passing direction, description).  For example: \\param [in] ParamName description.                                                                                                                                                                                                                                                    |
| CXComment\\_TParamCommand        | A \\tparam command that describes a template parameter (name and description).  For example: \\tparam T description.                                                                                                                                                                                                                                                                                          |
| CXComment\\_VerbatimBlockCommand | A verbatim block command (e. g., preformatted code). Verbatim block has an opening and a closing command and contains multiple lines of text (`CXComment_VerbatimBlockLine` child nodes).  For example: \\verbatim aaa \\endverbatim                                                                                                                                                                          |
| CXComment\\_VerbatimBlockLine    | A line of text that is contained within a CXComment\\_VerbatimBlockCommand node.                                                                                                                                                                                                                                                                                                                              |
| CXComment\\_VerbatimLine         | A verbatim line command. Verbatim line has an opening command, a single line of text (up to the newline after the opening command) and has no closing command.                                                                                                                                                                                                                                                |
| CXComment\\_FullComment          | A full comment attached to a declaration, contains block content.                                                                                                                                                                                                                                                                                                                                             |
"""
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

"""
    CXCommentInlineCommandRenderKind

The most appropriate rendering mode for an inline command, chosen on command semantics in Doxygen.

| Enumerator                                    | Note                                                                        |
| :-------------------------------------------- | :-------------------------------------------------------------------------- |
| CXCommentInlineCommandRenderKind\\_Normal     | Command argument should be rendered in a normal font.                       |
| CXCommentInlineCommandRenderKind\\_Bold       | Command argument should be rendered in a bold font.                         |
| CXCommentInlineCommandRenderKind\\_Monospaced | Command argument should be rendered in a monospaced font.                   |
| CXCommentInlineCommandRenderKind\\_Emphasized | Command argument should be rendered emphasized (typically italic font).     |
| CXCommentInlineCommandRenderKind\\_Anchor     | Command argument should not be rendered (since it only defines an anchor).  |
"""
@cenum CXCommentInlineCommandRenderKind::UInt32 begin
    CXCommentInlineCommandRenderKind_Normal = 0
    CXCommentInlineCommandRenderKind_Bold = 1
    CXCommentInlineCommandRenderKind_Monospaced = 2
    CXCommentInlineCommandRenderKind_Emphasized = 3
    CXCommentInlineCommandRenderKind_Anchor = 4
end

"""
    CXCommentParamPassDirection

Describes parameter passing direction for \\param or \\arg command.

| Enumerator                          | Note                                             |
| :---------------------------------- | :----------------------------------------------- |
| CXCommentParamPassDirection\\_In    | The parameter is an input parameter.             |
| CXCommentParamPassDirection\\_Out   | The parameter is an output parameter.            |
| CXCommentParamPassDirection\\_InOut | The parameter is an input and output parameter.  |
"""
@cenum CXCommentParamPassDirection::UInt32 begin
    CXCommentParamPassDirection_In = 0
    CXCommentParamPassDirection_Out = 1
    CXCommentParamPassDirection_InOut = 2
end

function clang_Comment_getKind(Comment)
    @ccall libclang.clang_Comment_getKind(Comment::Cint)::Cint
end

function clang_Comment_getNumChildren(Comment)
    @ccall libclang.clang_Comment_getNumChildren(Comment::Cint)::Cint
end

function clang_Comment_isWhitespace(Comment)
    @ccall libclang.clang_Comment_isWhitespace(Comment::Cint)::Cint
end

function clang_InlineContentComment_hasTrailingNewline(Comment)
    @ccall libclang.clang_InlineContentComment_hasTrailingNewline(Comment::Cint)::Cint
end

function clang_InlineCommandComment_getRenderKind(Comment)
    @ccall libclang.clang_InlineCommandComment_getRenderKind(Comment::Cint)::Cint
end

function clang_InlineCommandComment_getNumArgs(Comment)
    @ccall libclang.clang_InlineCommandComment_getNumArgs(Comment::Cint)::Cint
end

function clang_HTMLStartTagComment_isSelfClosing(Comment)
    @ccall libclang.clang_HTMLStartTagComment_isSelfClosing(Comment::Cint)::Cint
end

function clang_HTMLStartTag_getNumAttrs(Comment)
    @ccall libclang.clang_HTMLStartTag_getNumAttrs(Comment::Cint)::Cint
end

function clang_BlockCommandComment_getNumArgs(Comment)
    @ccall libclang.clang_BlockCommandComment_getNumArgs(Comment::Cint)::Cint
end

function clang_ParamCommandComment_isParamIndexValid(Comment)
    @ccall libclang.clang_ParamCommandComment_isParamIndexValid(Comment::Cint)::Cint
end

function clang_ParamCommandComment_getParamIndex(Comment)
    @ccall libclang.clang_ParamCommandComment_getParamIndex(Comment::Cint)::Cint
end

function clang_ParamCommandComment_isDirectionExplicit(Comment)
    @ccall libclang.clang_ParamCommandComment_isDirectionExplicit(Comment::Cint)::Cint
end

function clang_ParamCommandComment_getDirection(Comment)
    @ccall libclang.clang_ParamCommandComment_getDirection(Comment::Cint)::Cint
end

function clang_TParamCommandComment_isParamPositionValid(Comment)
    @ccall libclang.clang_TParamCommandComment_isParamPositionValid(Comment::Cint)::Cint
end

function clang_TParamCommandComment_getDepth(Comment)
    @ccall libclang.clang_TParamCommandComment_getDepth(Comment::Cint)::Cint
end

function clang_TParamCommandComment_getIndex(Comment, Depth)
    @ccall libclang.clang_TParamCommandComment_getIndex(Comment::Cint, Depth::Cuint)::Cint
end

"""
    clang_getBuildSessionTimestamp()

Return the timestamp for use with Clang's `-fbuild-session-timestamp=` option.
"""
function clang_getBuildSessionTimestamp()
    @ccall libclang.clang_getBuildSessionTimestamp()::Culonglong
end

mutable struct CXVirtualFileOverlayImpl end

"""
Object encapsulating information about overlaying virtual file/directories over the real file system.
"""
const CXVirtualFileOverlay = Ptr{CXVirtualFileOverlayImpl}

function clang_VirtualFileOverlay_addFileMapping(arg1, virtualPath, realPath)
    @ccall libclang.clang_VirtualFileOverlay_addFileMapping(arg1::CXVirtualFileOverlay, virtualPath::Cstring, realPath::Cstring)::Cint
end

function clang_VirtualFileOverlay_setCaseSensitivity(arg1, caseSensitive)
    @ccall libclang.clang_VirtualFileOverlay_setCaseSensitivity(arg1::CXVirtualFileOverlay, caseSensitive::Cint)::Cint
end

function clang_VirtualFileOverlay_writeToBuffer(arg1, options, out_buffer_ptr, out_buffer_size)
    @ccall libclang.clang_VirtualFileOverlay_writeToBuffer(arg1::CXVirtualFileOverlay, options::Cuint, out_buffer_ptr::Ptr{Cstring}, out_buffer_size::Ptr{Cuint})::Cint
end

function clang_free(buffer)
    @ccall libclang.clang_free(buffer::Ptr{Cvoid})::Cint
end

function clang_VirtualFileOverlay_dispose(arg1)
    @ccall libclang.clang_VirtualFileOverlay_dispose(arg1::CXVirtualFileOverlay)::Cint
end

mutable struct CXModuleMapDescriptorImpl end

"""
Object encapsulating information about a module.map file.
"""
const CXModuleMapDescriptor = Ptr{CXModuleMapDescriptorImpl}

function clang_ModuleMapDescriptor_setFrameworkModuleName(arg1, name)
    @ccall libclang.clang_ModuleMapDescriptor_setFrameworkModuleName(arg1::CXModuleMapDescriptor, name::Cstring)::Cint
end

function clang_ModuleMapDescriptor_setUmbrellaHeader(arg1, name)
    @ccall libclang.clang_ModuleMapDescriptor_setUmbrellaHeader(arg1::CXModuleMapDescriptor, name::Cstring)::Cint
end

function clang_ModuleMapDescriptor_writeToBuffer(arg1, options, out_buffer_ptr, out_buffer_size)
    @ccall libclang.clang_ModuleMapDescriptor_writeToBuffer(arg1::CXModuleMapDescriptor, options::Cuint, out_buffer_ptr::Ptr{Cstring}, out_buffer_size::Ptr{Cuint})::Cint
end

function clang_ModuleMapDescriptor_dispose(arg1)
    @ccall libclang.clang_ModuleMapDescriptor_dispose(arg1::CXModuleMapDescriptor)::Cint
end

const CXIndex = Ptr{Cint}

mutable struct CXTargetInfoImpl end

"""
An opaque type representing target information for a given translation unit.
"""
const CXTargetInfo = Ptr{CXTargetInfoImpl}

mutable struct CXTranslationUnitImpl end

"""
A single translation unit, which resides in an index.
"""
const CXTranslationUnit = Ptr{CXTranslationUnitImpl}

"""
Opaque pointer representing client data that will be passed through to various callbacks and visitors.
"""
const CXClientData = Ptr{Cvoid}

"""
    CXUnsavedFile

Provides the contents of a file that has not yet been saved to disk.

Each [`CXUnsavedFile`](@ref) instance provides the name of a file on the system along with the current contents of that file that have not yet been saved to disk.

| Field    | Note                                                                                                |
| :------- | :-------------------------------------------------------------------------------------------------- |
| Filename | The file whose contents have not yet been saved.  This file must already exist in the file system.  |
| Contents | A buffer containing the unsaved contents of this file.                                              |
| Length   | The length of the unsaved contents of this buffer.                                                  |
"""
struct CXUnsavedFile
    Filename::Cstring
    Contents::Cstring
    Length::Culong
end

"""
    CXAvailabilityKind

Describes the availability of a particular entity, which indicates whether the use of this entity will result in a warning or error due to it being deprecated or unavailable.

| Enumerator                     | Note                                                                                |
| :----------------------------- | :---------------------------------------------------------------------------------- |
| CXAvailability\\_Available     | The entity is available.                                                            |
| CXAvailability\\_Deprecated    | The entity is available, but has been deprecated (and its use is not recommended).  |
| CXAvailability\\_NotAvailable  | The entity is not available; any use of it will be an error.                        |
| CXAvailability\\_NotAccessible | The entity is available, but not accessible; any use of it will be an error.        |
"""
@cenum CXAvailabilityKind::UInt32 begin
    CXAvailability_Available = 0
    CXAvailability_Deprecated = 1
    CXAvailability_NotAvailable = 2
    CXAvailability_NotAccessible = 3
end

"""
    CXVersion

Describes a version number of the form major.minor.subminor.

| Field    | Note                                                                                                                                                                       |
| :------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Major    | The major version number, e.g., the '10' in '10.7.3'. A negative value indicates that there is no version number at all.                                                   |
| Minor    | The minor version number, e.g., the '7' in '10.7.3'. This value will be negative if no minor version number was provided, e.g., for version '10'.                          |
| Subminor | The subminor version number, e.g., the '3' in '10.7.3'. This value will be negative if no minor or subminor version number was provided, e.g., in version '10' or '10.7'.  |
"""
struct CXVersion
    Major::Cint
    Minor::Cint
    Subminor::Cint
end

"""
    CXCursor_ExceptionSpecificationKind

Describes the exception specification of a cursor.

A negative value indicates that the cursor is not a function declaration.

| Enumerator                                               | Note                                                               |
| :------------------------------------------------------- | :----------------------------------------------------------------- |
| CXCursor\\_ExceptionSpecificationKind\\_None             | The cursor has no exception specification.                         |
| CXCursor\\_ExceptionSpecificationKind\\_DynamicNone      | The cursor has exception specification throw()                     |
| CXCursor\\_ExceptionSpecificationKind\\_Dynamic          | The cursor has exception specification throw(T1, T2)               |
| CXCursor\\_ExceptionSpecificationKind\\_MSAny            | The cursor has exception specification throw(...).                 |
| CXCursor\\_ExceptionSpecificationKind\\_BasicNoexcept    | The cursor has exception specification basic noexcept.             |
| CXCursor\\_ExceptionSpecificationKind\\_ComputedNoexcept | The cursor has exception specification computed noexcept.          |
| CXCursor\\_ExceptionSpecificationKind\\_Unevaluated      | The exception specification has not yet been evaluated.            |
| CXCursor\\_ExceptionSpecificationKind\\_Uninstantiated   | The exception specification has not yet been instantiated.         |
| CXCursor\\_ExceptionSpecificationKind\\_Unparsed         | The exception specification has not been parsed yet.               |
| CXCursor\\_ExceptionSpecificationKind\\_NoThrow          | The cursor has a \\_\\_declspec(nothrow) exception specification.  |
"""
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

function clang_disposeIndex(index)
    @ccall libclang.clang_disposeIndex(index::CXIndex)::Cint
end

"""
    CXGlobalOptFlags

| Enumerator                                        | Note                                                                                                                                                                                                                                                              |
| :------------------------------------------------ | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CXGlobalOpt\\_None                                | Used to indicate that no special [`CXIndex`](@ref) options are needed.                                                                                                                                                                                            |
| CXGlobalOpt\\_ThreadBackgroundPriorityForIndexing | Used to indicate that threads that libclang creates for indexing purposes should use background priority.  Affects #[`clang_indexSourceFile`](@ref), #[`clang_indexTranslationUnit`](@ref), #clang\\_parseTranslationUnit, #[`clang_saveTranslationUnit`](@ref).  |
| CXGlobalOpt\\_ThreadBackgroundPriorityForEditing  | Used to indicate that threads that libclang creates for editing purposes should use background priority.  Affects #[`clang_reparseTranslationUnit`](@ref), #clang\\_codeCompleteAt, #[`clang_annotateTokens`](@ref)                                               |
| CXGlobalOpt\\_ThreadBackgroundPriorityForAll      | Used to indicate that all threads that libclang creates should use background priority.                                                                                                                                                                           |
"""
@cenum CXGlobalOptFlags::UInt32 begin
    CXGlobalOpt_None = 0
    CXGlobalOpt_ThreadBackgroundPriorityForIndexing = 1
    CXGlobalOpt_ThreadBackgroundPriorityForEditing = 2
    CXGlobalOpt_ThreadBackgroundPriorityForAll = 3
end

function clang_CXIndex_setGlobalOptions(arg1, options)
    @ccall libclang.clang_CXIndex_setGlobalOptions(arg1::CXIndex, options::Cuint)::Cint
end

function clang_CXIndex_getGlobalOptions(arg1)
    @ccall libclang.clang_CXIndex_getGlobalOptions(arg1::CXIndex)::Cint
end

function clang_CXIndex_setInvocationEmissionPathOption(arg1, Path)
    @ccall libclang.clang_CXIndex_setInvocationEmissionPathOption(arg1::CXIndex, Path::Cstring)::Cint
end

"""
A particular source file that is part of a translation unit.
"""
const CXFile = Ptr{Cvoid}

"""
    CXFileUniqueID

Uniquely identifies a [`CXFile`](@ref), that refers to the same underlying file, across an indexing session.
"""
struct CXFileUniqueID
    data::NTuple{3, Culonglong}
end

function clang_getFileUniqueID(file, outID)
    @ccall libclang.clang_getFileUniqueID(file::CXFile, outID::Ptr{CXFileUniqueID})::Cint
end

function clang_isFileMultipleIncludeGuarded(tu, file)
    @ccall libclang.clang_isFileMultipleIncludeGuarded(tu::CXTranslationUnit, file::CXFile)::Cint
end

function clang_getFileContents(tu, file, size)
    @ccall libclang.clang_getFileContents(tu::CXTranslationUnit, file::CXFile, size::Ptr{Csize_t})::Ptr{Cint}
end

function clang_File_isEqual(file1, file2)
    @ccall libclang.clang_File_isEqual(file1::CXFile, file2::CXFile)::Cint
end

"""
    CXSourceLocation

Identifies a specific source location within a translation unit.

Use [`clang_getExpansionLocation`](@ref)() or [`clang_getSpellingLocation`](@ref)() to map a source location to a particular file, line, and column.
"""
struct CXSourceLocation
    ptr_data::NTuple{2, Ptr{Cvoid}}
    int_data::Cuint
end

"""
    CXSourceRange

Identifies a half-open character range in the source code.

Use clang\\_getRangeStart() and clang\\_getRangeEnd() to retrieve the starting and end locations from a source range, respectively.
"""
struct CXSourceRange
    ptr_data::NTuple{2, Ptr{Cvoid}}
    begin_int_data::Cuint
    end_int_data::Cuint
end

function clang_equalLocations(loc1, loc2)
    @ccall libclang.clang_equalLocations(loc1::CXSourceLocation, loc2::CXSourceLocation)::Cint
end

function clang_Location_isInSystemHeader(location)
    @ccall libclang.clang_Location_isInSystemHeader(location::CXSourceLocation)::Cint
end

function clang_Location_isFromMainFile(location)
    @ccall libclang.clang_Location_isFromMainFile(location::CXSourceLocation)::Cint
end

function clang_equalRanges(range1, range2)
    @ccall libclang.clang_equalRanges(range1::CXSourceRange, range2::CXSourceRange)::Cint
end

function clang_Range_isNull(range)
    @ccall libclang.clang_Range_isNull(range::CXSourceRange)::Cint
end

function clang_getExpansionLocation(location, file, line, column, offset)
    @ccall libclang.clang_getExpansionLocation(location::CXSourceLocation, file::Ptr{CXFile}, line::Ptr{Cuint}, column::Ptr{Cuint}, offset::Ptr{Cuint})::Cint
end

function clang_getPresumedLocation(location, filename, line, column)
    @ccall libclang.clang_getPresumedLocation(location::CXSourceLocation, filename::Ptr{Cint}, line::Ptr{Cuint}, column::Ptr{Cuint})::Cint
end

function clang_getInstantiationLocation(location, file, line, column, offset)
    @ccall libclang.clang_getInstantiationLocation(location::CXSourceLocation, file::Ptr{CXFile}, line::Ptr{Cuint}, column::Ptr{Cuint}, offset::Ptr{Cuint})::Cint
end

function clang_getSpellingLocation(location, file, line, column, offset)
    @ccall libclang.clang_getSpellingLocation(location::CXSourceLocation, file::Ptr{CXFile}, line::Ptr{Cuint}, column::Ptr{Cuint}, offset::Ptr{Cuint})::Cint
end

function clang_getFileLocation(location, file, line, column, offset)
    @ccall libclang.clang_getFileLocation(location::CXSourceLocation, file::Ptr{CXFile}, line::Ptr{Cuint}, column::Ptr{Cuint}, offset::Ptr{Cuint})::Cint
end

"""
    CXSourceRangeList

Identifies an array of ranges.

| Field  | Note                                         |
| :----- | :------------------------------------------- |
| count  | The number of ranges in the `ranges` array.  |
| ranges | An array of `CXSourceRanges`.                |
"""
struct CXSourceRangeList
    count::Cuint
    ranges::Ptr{CXSourceRange}
end

function clang_disposeSourceRangeList(ranges)
    @ccall libclang.clang_disposeSourceRangeList(ranges::Ptr{CXSourceRangeList})::Cint
end

"""
    CXDiagnosticSeverity

Describes the severity of a particular diagnostic.

| Enumerator             | Note                                                                                                                           |
| :--------------------- | :----------------------------------------------------------------------------------------------------------------------------- |
| CXDiagnostic\\_Ignored | A diagnostic that has been suppressed, e.g., by a command-line option.                                                         |
| CXDiagnostic\\_Note    | This diagnostic is a note that should be attached to the previous (non-note) diagnostic.                                       |
| CXDiagnostic\\_Warning | This diagnostic indicates suspicious code that may not be wrong.                                                               |
| CXDiagnostic\\_Error   | This diagnostic indicates that the code is ill-formed.                                                                         |
| CXDiagnostic\\_Fatal   | This diagnostic indicates that the code is ill-formed such that future parser recovery is unlikely to produce useful results.  |
"""
@cenum CXDiagnosticSeverity::UInt32 begin
    CXDiagnostic_Ignored = 0
    CXDiagnostic_Note = 1
    CXDiagnostic_Warning = 2
    CXDiagnostic_Error = 3
    CXDiagnostic_Fatal = 4
end

"""
A single diagnostic, containing the diagnostic's severity, location, text, source ranges, and fix-it hints.
"""
const CXDiagnostic = Ptr{Cvoid}

"""
A group of CXDiagnostics.
"""
const CXDiagnosticSet = Ptr{Cvoid}

function clang_getNumDiagnosticsInSet(Diags)
    @ccall libclang.clang_getNumDiagnosticsInSet(Diags::CXDiagnosticSet)::Cint
end

"""
    CXLoadDiag_Error

Describes the kind of error that occurred (if any) in a call to `clang_loadDiagnostics`.

| Enumerator               | Note                                                                                   |
| :----------------------- | :------------------------------------------------------------------------------------- |
| CXLoadDiag\\_None        | Indicates that no error occurred.                                                      |
| CXLoadDiag\\_Unknown     | Indicates that an unknown error occurred while attempting to deserialize diagnostics.  |
| CXLoadDiag\\_CannotLoad  | Indicates that the file containing the serialized diagnostics could not be opened.     |
| CXLoadDiag\\_InvalidFile | Indicates that the serialized diagnostics file is invalid or corrupt.                  |
"""
@cenum CXLoadDiag_Error::UInt32 begin
    CXLoadDiag_None = 0
    CXLoadDiag_Unknown = 1
    CXLoadDiag_CannotLoad = 2
    CXLoadDiag_InvalidFile = 3
end

function clang_disposeDiagnosticSet(Diags)
    @ccall libclang.clang_disposeDiagnosticSet(Diags::CXDiagnosticSet)::Cint
end

function clang_getNumDiagnostics(Unit)
    @ccall libclang.clang_getNumDiagnostics(Unit::CXTranslationUnit)::Cint
end

function clang_disposeDiagnostic(Diagnostic)
    @ccall libclang.clang_disposeDiagnostic(Diagnostic::CXDiagnostic)::Cint
end

"""
    CXDiagnosticDisplayOptions

Options to control the display of diagnostics.

The values in this enum are meant to be combined to customize the behavior of `clang_formatDiagnostic`().

| Enumerator                           | Note                                                                                                                                                                                                                                                                                                                                                     |
| :----------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CXDiagnostic\\_DisplaySourceLocation | Display the source-location information where the diagnostic was located.  When set, diagnostics will be prefixed by the file, line, and (optionally) column to which the diagnostic refers. For example,  ```c++  test.c:28: warning: extra tokens at end of #endif directive ```  This option corresponds to the clang flag `-fshow-source-location.`  |
| CXDiagnostic\\_DisplayColumn         | If displaying the source-location information of the diagnostic, also include the column number.  This option corresponds to the clang flag `-fshow-column.`                                                                                                                                                                                             |
| CXDiagnostic\\_DisplaySourceRanges   | If displaying the source-location information of the diagnostic, also include information about source ranges in a machine-parsable format.  This option corresponds to the clang flag `-fdiagnostics-print-source-range-info.`                                                                                                                          |
| CXDiagnostic\\_DisplayOption         | Display the option name associated with this diagnostic, if any.  The option name displayed (e.g., -Wconversion) will be placed in brackets after the diagnostic text. This option corresponds to the clang flag `-fdiagnostics-show-option.`                                                                                                            |
| CXDiagnostic\\_DisplayCategoryId     | Display the category number associated with this diagnostic, if any.  The category number is displayed within brackets after the diagnostic text. This option corresponds to the clang flag `-fdiagnostics-show-category=id.`                                                                                                                            |
| CXDiagnostic\\_DisplayCategoryName   | Display the category name associated with this diagnostic, if any.  The category name is displayed within brackets after the diagnostic text. This option corresponds to the clang flag `-fdiagnostics-show-category=name.`                                                                                                                              |
"""
@cenum CXDiagnosticDisplayOptions::UInt32 begin
    CXDiagnostic_DisplaySourceLocation = 1
    CXDiagnostic_DisplayColumn = 2
    CXDiagnostic_DisplaySourceRanges = 4
    CXDiagnostic_DisplayOption = 8
    CXDiagnostic_DisplayCategoryId = 16
    CXDiagnostic_DisplayCategoryName = 32
end

function clang_defaultDiagnosticDisplayOptions()
    @ccall libclang.clang_defaultDiagnosticDisplayOptions()::Cint
end

function clang_getDiagnosticSeverity(arg1)
    @ccall libclang.clang_getDiagnosticSeverity(arg1::CXDiagnostic)::Cint
end

function clang_getDiagnosticCategory(arg1)
    @ccall libclang.clang_getDiagnosticCategory(arg1::CXDiagnostic)::Cint
end

function clang_getDiagnosticNumRanges(arg1)
    @ccall libclang.clang_getDiagnosticNumRanges(arg1::CXDiagnostic)::Cint
end

function clang_getDiagnosticNumFixIts(Diagnostic)
    @ccall libclang.clang_getDiagnosticNumFixIts(Diagnostic::CXDiagnostic)::Cint
end

function clang_createTranslationUnit2(CIdx, ast_filename, out_TU)
    @ccall libclang.clang_createTranslationUnit2(CIdx::CXIndex, ast_filename::Cstring, out_TU::Ptr{CXTranslationUnit})::Cint
end

"""
    CXTranslationUnit_Flags

Flags that control the creation of translation units.

The enumerators in this enumeration type are meant to be bitwise ORed together to specify which options should be used when constructing the translation unit.

| Enumerator                                               | Note                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| :------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CXTranslationUnit\\_None                                 | Used to indicate that no special translation-unit options are needed.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CXTranslationUnit\\_DetailedPreprocessingRecord          | Used to indicate that the parser should construct a "detailed" preprocessing record, including all macro definitions and instantiations.  Constructing a detailed preprocessing record requires more memory and time to parse, since the information contained in the record is usually not retained. However, it can be useful for applications that require more detailed information about the behavior of the preprocessor.                                                                                                                                                                                                                                                  |
| CXTranslationUnit\\_Incomplete                           | Used to indicate that the translation unit is incomplete.  When a translation unit is considered "incomplete", semantic analysis that is typically performed at the end of the translation unit will be suppressed. For example, this suppresses the completion of tentative declarations in C and of instantiation of implicitly-instantiation function templates in C++. This option is typically used when parsing a header with the intent of producing a precompiled header.                                                                                                                                                                                                |
| CXTranslationUnit\\_PrecompiledPreamble                  | Used to indicate that the translation unit should be built with an implicit precompiled header for the preamble.  An implicit precompiled header is used as an optimization when a particular translation unit is likely to be reparsed many times when the sources aren't changing that often. In this case, an implicit precompiled header will be built containing all of the initial includes at the top of the main file (what we refer to as the "preamble" of the file). In subsequent parses, if the preamble or the files in it have not changed, [`clang_reparseTranslationUnit`](@ref)() will re-use the implicit precompiled header to improve parsing performance.  |
| CXTranslationUnit\\_CacheCompletionResults               | Used to indicate that the translation unit should cache some code-completion results with each reparse of the source file.  Caching of code-completion results is a performance optimization that introduces some overhead to reparsing but improves the performance of code-completion operations.                                                                                                                                                                                                                                                                                                                                                                              |
| CXTranslationUnit\\_ForSerialization                     | Used to indicate that the translation unit will be serialized with [`clang_saveTranslationUnit`](@ref).  This option is typically used when parsing a header with the intent of producing a precompiled header.                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXTranslationUnit\\_CXXChainedPCH                        | DEPRECATED: Enabled chained precompiled preambles in C++.  Note: this is a *temporary* option that is available only while we are testing C++ precompiled preamble support. It is deprecated.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXTranslationUnit\\_SkipFunctionBodies                   | Used to indicate that function/method bodies should be skipped while parsing.  This option can be used to search for declarations/definitions while ignoring the usages.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXTranslationUnit\\_IncludeBriefCommentsInCodeCompletion | Used to indicate that brief documentation comments should be included into the set of code completions returned from this translation unit.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| CXTranslationUnit\\_CreatePreambleOnFirstParse           | Used to indicate that the precompiled preamble should be created on the first parse. Otherwise it will be created on the first reparse. This trades runtime on the first parse (serializing the preamble takes time) for reduced runtime on the second parse (can now reuse the preamble).                                                                                                                                                                                                                                                                                                                                                                                       |
| CXTranslationUnit\\_KeepGoing                            | Do not stop processing when fatal errors are encountered.  When fatal errors are encountered while parsing a translation unit, semantic analysis is typically stopped early when compiling code. A common source for fatal errors are unresolvable include files. For the purposes of an IDE, this is undesirable behavior and as much information as possible should be reported. Use this flag to enable this behavior.                                                                                                                                                                                                                                                        |
| CXTranslationUnit\\_SingleFileParse                      | Sets the preprocessor in a mode for parsing a single file only.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXTranslationUnit\\_LimitSkipFunctionBodiesToPreamble    | Used in combination with CXTranslationUnit\\_SkipFunctionBodies to constrain the skipping of function bodies to the preamble.  The function bodies of the main file are not skipped.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXTranslationUnit\\_IncludeAttributedTypes               | Used to indicate that attributed types should be included in [`CXType`](@ref).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CXTranslationUnit\\_VisitImplicitAttributes              | Used to indicate that implicit attributes should be visited.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CXTranslationUnit\\_IgnoreNonErrorsFromIncludedFiles     | Used to indicate that non-errors from included files should be ignored.  If set, clang\\_getDiagnosticSetFromTU() will not report e.g. warnings from included files anymore. This speeds up clang\\_getDiagnosticSetFromTU() for the case where these warnings are not of interest, as for an IDE for example, which typically shows only the diagnostics in the main file.                                                                                                                                                                                                                                                                                                      |
| CXTranslationUnit\\_RetainExcludedConditionalBlocks      | Tells the preprocessor not to skip excluded conditional blocks.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
"""
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
    @ccall libclang.clang_defaultEditingTranslationUnitOptions()::Cint
end

function clang_parseTranslationUnit2(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
    @ccall libclang.clang_parseTranslationUnit2(CIdx::CXIndex, source_filename::Cstring, command_line_args::Ptr{Cstring}, num_command_line_args::Cint, unsaved_files::Ptr{CXUnsavedFile}, num_unsaved_files::Cuint, options::Cuint, out_TU::Ptr{CXTranslationUnit})::Cint
end

function clang_parseTranslationUnit2FullArgv(CIdx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options, out_TU)
    @ccall libclang.clang_parseTranslationUnit2FullArgv(CIdx::CXIndex, source_filename::Cstring, command_line_args::Ptr{Cstring}, num_command_line_args::Cint, unsaved_files::Ptr{CXUnsavedFile}, num_unsaved_files::Cuint, options::Cuint, out_TU::Ptr{CXTranslationUnit})::Cint
end

"""
    CXSaveTranslationUnit_Flags

Flags that control how translation units are saved.

The enumerators in this enumeration type are meant to be bitwise ORed together to specify which options should be used when saving the translation unit.

| Enumerator                   | Note                                                         |
| :--------------------------- | :----------------------------------------------------------- |
| CXSaveTranslationUnit\\_None | Used to indicate that no special saving options are needed.  |
"""
@cenum CXSaveTranslationUnit_Flags::UInt32 begin
    CXSaveTranslationUnit_None = 0
end

function clang_defaultSaveOptions(TU)
    @ccall libclang.clang_defaultSaveOptions(TU::CXTranslationUnit)::Cint
end

"""
    CXSaveError

Describes the kind of error that occurred (if any) in a call to [`clang_saveTranslationUnit`](@ref)().

| Enumerator                      | Note                                                                                                                                                                                                                                              |
| :------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| CXSaveError\\_None              | Indicates that no error occurred while saving a translation unit.                                                                                                                                                                                 |
| CXSaveError\\_Unknown           | Indicates that an unknown error occurred while attempting to save the file.  This error typically indicates that file I/O failed when attempting to write the file.                                                                               |
| CXSaveError\\_TranslationErrors | Indicates that errors during translation prevented this attempt to save the translation unit.  Errors that prevent the translation unit from being saved can be extracted using [`clang_getNumDiagnostics`](@ref)() and `clang_getDiagnostic`().  |
| CXSaveError\\_InvalidTU         | Indicates that the translation unit to be saved was somehow invalid (e.g., NULL).                                                                                                                                                                 |
"""
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
    @ccall libclang.clang_suspendTranslationUnit(arg1::CXTranslationUnit)::Cint
end

function clang_disposeTranslationUnit(arg1)
    @ccall libclang.clang_disposeTranslationUnit(arg1::CXTranslationUnit)::Cint
end

"""
    CXReparse_Flags

Flags that control the reparsing of translation units.

The enumerators in this enumeration type are meant to be bitwise ORed together to specify which options should be used when reparsing the translation unit.

| Enumerator       | Note                                                            |
| :--------------- | :-------------------------------------------------------------- |
| CXReparse\\_None | Used to indicate that no special reparsing options are needed.  |
"""
@cenum CXReparse_Flags::UInt32 begin
    CXReparse_None = 0
end

function clang_defaultReparseOptions(TU)
    @ccall libclang.clang_defaultReparseOptions(TU::CXTranslationUnit)::Cint
end

function clang_reparseTranslationUnit(TU, num_unsaved_files, unsaved_files, options)
    @ccall libclang.clang_reparseTranslationUnit(TU::CXTranslationUnit, num_unsaved_files::Cuint, unsaved_files::Ptr{CXUnsavedFile}, options::Cuint)::Cint
end

"""
    CXTUResourceUsageKind

Categorizes how memory is being used by a translation unit.
"""
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
    @ccall libclang.clang_getTUResourceUsageName(kind::CXTUResourceUsageKind)::Ptr{Cint}
end

struct CXTUResourceUsageEntry
    kind::CXTUResourceUsageKind
    amount::Culong
end

"""
    CXTUResourceUsage

The memory usage of a [`CXTranslationUnit`](@ref), broken into categories.
"""
struct CXTUResourceUsage
    data::Ptr{Cvoid}
    numEntries::Cuint
    entries::Ptr{CXTUResourceUsageEntry}
end

function clang_disposeCXTUResourceUsage(usage)
    @ccall libclang.clang_disposeCXTUResourceUsage(usage::CXTUResourceUsage)::Cint
end

function clang_TargetInfo_dispose(Info)
    @ccall libclang.clang_TargetInfo_dispose(Info::CXTargetInfo)::Cint
end

function clang_TargetInfo_getPointerWidth(Info)
    @ccall libclang.clang_TargetInfo_getPointerWidth(Info::CXTargetInfo)::Cint
end

"""
    CXCursorKind

Describes the kind of entity that a cursor refers to.

| Enumerator                                                  | Note                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| :---------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CXCursor\\_UnexposedDecl                                    | A declaration whose specific kind is not exposed via this interface.  Unexposed declarations have the same operations as any other kind of declaration; one can extract their location information, spelling, find their definitions, etc. However, the specific kind of the declaration is not reported.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_StructDecl                                       | A C or C++ struct.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_UnionDecl                                        | A C or C++ union.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_ClassDecl                                        | A C++ class.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CXCursor\\_EnumDecl                                         | An enumeration.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_FieldDecl                                        | A field (in C) or non-static data member (in C++) in a struct, union, or C++ class.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_EnumConstantDecl                                 | An enumerator constant.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CXCursor\\_FunctionDecl                                     | A function.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| CXCursor\\_VarDecl                                          | A variable.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| CXCursor\\_ParmDecl                                         | A function or method parameter.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCInterfaceDecl                                | An Objective-C @interface.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_ObjCCategoryDecl                                 | An Objective-C @interface for a category.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_ObjCProtocolDecl                                 | An Objective-C @protocol declaration.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CXCursor\\_ObjCPropertyDecl                                 | An Objective-C @property declaration.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CXCursor\\_ObjCIvarDecl                                     | An Objective-C instance variable.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_ObjCInstanceMethodDecl                           | An Objective-C instance method.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCClassMethodDecl                              | An Objective-C class method.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CXCursor\\_ObjCImplementationDecl                           | An Objective-C @implementation.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCCategoryImplDecl                             | An Objective-C @implementation for a category.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CXCursor\\_TypedefDecl                                      | A typedef.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_CXXMethod                                        | A C++ class method.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_Namespace                                        | A C++ namespace.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CXCursor\\_LinkageSpec                                      | A linkage specification, e.g. 'extern "C"'.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| CXCursor\\_Constructor                                      | A C++ constructor.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_Destructor                                       | A C++ destructor.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_ConversionFunction                               | A C++ conversion function.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_TemplateTypeParameter                            | A C++ template type parameter.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CXCursor\\_NonTypeTemplateParameter                         | A C++ non-type template parameter.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_TemplateTemplateParameter                        | A C++ template template parameter.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_FunctionTemplate                                 | A C++ function template.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_ClassTemplate                                    | A C++ class template.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CXCursor\\_ClassTemplatePartialSpecialization               | A C++ class template partial specialization.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CXCursor\\_NamespaceAlias                                   | A C++ namespace alias declaration.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_UsingDirective                                   | A C++ using directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_UsingDeclaration                                 | A C++ using declaration.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_TypeAliasDecl                                    | A C++ alias declaration                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CXCursor\\_ObjCSynthesizeDecl                               | An Objective-C @synthesize definition.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_ObjCDynamicDecl                                  | An Objective-C @dynamic definition.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_CXXAccessSpecifier                               | An access specifier.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CXCursor\\_FirstDecl                                        |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_LastDecl                                         |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_FirstRef                                         |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCSuperClassRef                                |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCProtocolRef                                  |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCClassRef                                     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_TypeRef                                          | A reference to a type declaration.  A type reference occurs anywhere where a type is named but not declared. For example, given:  ```c++  typedef unsigned size_type;  size_type size; ```  The typedef is a declaration of size\\_type (CXCursor\\_TypedefDecl), while the type of the variable "size" is referenced. The cursor referenced by the type of size is the typedef for size\\_type.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CXCursor\\_CXXBaseSpecifier                                 |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_TemplateRef                                      | A reference to a class template, function template, template template parameter, or class template partial specialization.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_NamespaceRef                                     | A reference to a namespace or namespace alias.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CXCursor\\_MemberRef                                        | A reference to a member of a struct, union, or class that occurs in some non-expression context, e.g., a designated initializer.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CXCursor\\_LabelRef                                         | A reference to a labeled statement.  This cursor kind is used to describe the jump to "start\\_over" in the goto statement in the following example:  ```c++    start_over:      ++counter;      goto start_over; ```  A label reference cursor refers to a label statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CXCursor\\_OverloadedDeclRef                                | A reference to a set of overloaded functions or function templates that has not yet been resolved to a specific function or function template.  An overloaded declaration reference cursor occurs in C++ templates where a dependent name refers to a function. For example:  ```c++  template<typename T> void swap(T&, T&);  struct X { ... };  void swap(X&, X&);  template<typename T>  void reverse(T* first, T* last) {    while (first < last - 1) {      swap(*first, *--last);      ++first;    }  }  struct Y { };  void swap(Y&, Y&); ```  Here, the identifier "swap" is associated with an overloaded declaration reference. In the template definition, "swap" refers to either of the two "swap" functions declared above, so both results will be available. At instantiation time, "swap" may also refer to other functions found via argument-dependent lookup (e.g., the "swap" function at the end of the example).  The functions [`clang_getNumOverloadedDecls`](@ref)() and `clang_getOverloadedDecl`() can be used to retrieve the definitions referenced by this cursor.  |
| CXCursor\\_VariableRef                                      | A reference to a variable that occurs in some non-expression context, e.g., a C++ lambda capture list.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_LastRef                                          |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_FirstInvalid                                     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_InvalidFile                                      |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_NoDeclFound                                      |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_NotImplemented                                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_InvalidCode                                      |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_LastInvalid                                      |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_FirstExpr                                        |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_UnexposedExpr                                    | An expression whose specific kind is not exposed via this interface.  Unexposed expressions have the same operations as any other kind of expression; one can extract their location information, spelling, children, etc. However, the specific kind of the expression is not reported.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_DeclRefExpr                                      | An expression that refers to some value declaration, such as a function, variable, or enumerator.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_MemberRefExpr                                    | An expression that refers to a member of a struct, union, class, Objective-C class, etc.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_CallExpr                                         | An expression that calls a function.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CXCursor\\_ObjCMessageExpr                                  | An expression that sends a message to an Objective-C object or class.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CXCursor\\_BlockExpr                                        | An expression that represents a block literal.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CXCursor\\_IntegerLiteral                                   | An integer literal.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_FloatingLiteral                                  | A floating point number literal.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CXCursor\\_ImaginaryLiteral                                 | An imaginary number literal.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CXCursor\\_StringLiteral                                    | A string literal.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_CharacterLiteral                                 | A character literal.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CXCursor\\_ParenExpr                                        | A parenthesized expression, e.g. "(1)".  This AST node is only formed if full location information is requested.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CXCursor\\_UnaryOperator                                    | This represents the unary-expression's (except sizeof and alignof).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_ArraySubscriptExpr                               | [C99 6.5.2.1] Array Subscripting.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_BinaryOperator                                   | A builtin binary operation expression such as "x + y" or "x <= y".                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_CompoundAssignOperator                           | Compound assignment such as "+=".                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_ConditionalOperator                              | The ?: ternary operator.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_CStyleCastExpr                                   | An explicit cast in C (C99 6.5.4) or a C-style cast in C++ (C++ [expr.cast]), which uses the syntax (Type)expr.  For example: (int)f.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CXCursor\\_CompoundLiteralExpr                              | [C99 6.5.2.5]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| CXCursor\\_InitListExpr                                     | Describes an C or C++ initializer list.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CXCursor\\_AddrLabelExpr                                    | The GNU address of label extension, representing &&label.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_StmtExpr                                         | This is the GNU Statement Expression extension: ({int X=4; X;})                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_GenericSelectionExpr                             | Represents a C11 generic selection.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_GNUNullExpr                                      | Implements the GNU \\_\\_null extension, which is a name for a null pointer constant that has integral type (e.g., int or long) and is the same size and alignment as a pointer.  The \\_\\_null extension is typically only used by system headers, which define NULL as \\_\\_null in C++ rather than using 0 (which is an integer that may not match the size of a pointer).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_CXXStaticCastExpr                                | C++'s static\\_cast<> expression.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_CXXDynamicCastExpr                               | C++'s dynamic\\_cast<> expression.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_CXXReinterpretCastExpr                           | C++'s reinterpret\\_cast<> expression.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_CXXConstCastExpr                                 | C++'s const\\_cast<> expression.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CXCursor\\_CXXFunctionalCastExpr                            | Represents an explicit C++ type conversion that uses "functional" notion (C++ [expr.type.conv]).  Example:  ```c++    x = int(0.5); ```                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CXCursor\\_CXXTypeidExpr                                    | A C++ typeid expression (C++ [expr.typeid]).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CXCursor\\_CXXBoolLiteralExpr                               | [C++ 2.13.5] C++ Boolean Literal.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_CXXNullPtrLiteralExpr                            | [C++0x 2.14.7] C++ Pointer Literal.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_CXXThisExpr                                      | Represents the "this" expression in C++                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CXCursor\\_CXXThrowExpr                                     | [C++ 15] C++ Throw Expression.  This handles 'throw' and 'throw' assignment-expression. When assignment-expression isn't present, Op will be null.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_CXXNewExpr                                       | A new expression for memory allocation and constructor calls, e.g: "new CXXNewExpr(foo)".                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_CXXDeleteExpr                                    | A delete expression for memory deallocation and destructor calls, e.g. "delete[] pArray".                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_UnaryExpr                                        | A unary expression. (noexcept, sizeof, or other traits)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CXCursor\\_ObjCStringLiteral                                | An Objective-C string literal i.e. "foo".                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_ObjCEncodeExpr                                   | An Objective-C @encode expression.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_ObjCSelectorExpr                                 | An Objective-C @selector expression.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CXCursor\\_ObjCProtocolExpr                                 | An Objective-C @protocol expression.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CXCursor\\_ObjCBridgedCastExpr                              | An Objective-C "bridged" cast expression, which casts between Objective-C pointers and C pointers, transferring ownership in the process.  ```c++    NSString *str = (__bridge_transfer NSString *)CFCreateString(); ```                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_PackExpansionExpr                                | Represents a C++0x pack expansion that produces a sequence of expressions.  A pack expansion expression contains a pattern (which itself is an expression) followed by an ellipsis. For example:  ```c++  template<typename F, typename ...Types>  void forward(F f, Types &&...args) {   f(static_cast<Types&&>(args)...);  } ```                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_SizeOfPackExpr                                   | Represents an expression that computes the length of a parameter pack.  ```c++  template<typename ...Types>  struct count {    static const unsigned value = sizeof...(Types);  }; ```                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_ObjCBoolLiteralExpr                              | Objective-c Boolean Literal.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CXCursor\\_ObjCSelfExpr                                     | Represents the "self" expression in an Objective-C method.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_OMPArraySectionExpr                              | OpenMP 5.0 [2.1.5, Array Section].                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_ObjCAvailabilityCheckExpr                        | Represents an (...) check.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_FixedPointLiteral                                | Fixed point literal                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_OMPArrayShapingExpr                              | OpenMP 5.0 [2.1.4, Array Shaping].                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_OMPIteratorExpr                                  | OpenMP 5.0 [2.1.6 Iterators]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CXCursor\\_CXXAddrspaceCastExpr                             | OpenCL's addrspace\\_cast<> expression.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CXCursor\\_LastExpr                                         |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_FirstStmt                                        |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_UnexposedStmt                                    | A statement whose specific kind is not exposed via this interface.  Unexposed statements have the same operations as any other kind of statement; one can extract their location information, spelling, children, etc. However, the specific kind of the statement is not reported.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_LabelStmt                                        | A labelled statement in a function.  This cursor kind is used to describe the "start\\_over:" label statement in the following example:  ```c++    start_over:      ++counter; ```                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_CompoundStmt                                     | A group of statements like { stmt stmt }.  This cursor kind is used to describe compound statements, e.g. function bodies.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_CaseStmt                                         | A case statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_DefaultStmt                                      | A default statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CXCursor\\_IfStmt                                           | An if statement                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_SwitchStmt                                       | A switch statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_WhileStmt                                        | A while statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_DoStmt                                           | A do statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ForStmt                                          | A for statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CXCursor\\_GotoStmt                                         | A goto statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_IndirectGotoStmt                                 | An indirect goto statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| CXCursor\\_ContinueStmt                                     | A continue statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CXCursor\\_BreakStmt                                        | A break statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_ReturnStmt                                       | A return statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_GCCAsmStmt                                       | A GCC inline assembly statement extension.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_AsmStmt                                          |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCAtTryStmt                                    | Objective-C's overall @try-@catch-@finally statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CXCursor\\_ObjCAtCatchStmt                                  | Objective-C's @catch statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCAtFinallyStmt                                | Objective-C's @finally statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_ObjCAtThrowStmt                                  | Objective-C's @throw statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCAtSynchronizedStmt                           | Objective-C's @synchronized statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_ObjCAutoreleasePoolStmt                          | Objective-C's autorelease pool statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_ObjCForCollectionStmt                            | Objective-C's collection statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_CXXCatchStmt                                     | C++'s catch statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_CXXTryStmt                                       | C++'s try statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CXCursor\\_CXXForRangeStmt                                  | C++'s for (* : *) statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CXCursor\\_SEHTryStmt                                       | Windows Structured Exception Handling's try statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_SEHExceptStmt                                    | Windows Structured Exception Handling's except statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_SEHFinallyStmt                                   | Windows Structured Exception Handling's finally statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_MSAsmStmt                                        | A MS inline assembly statement extension.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_NullStmt                                         | The null statement ";": C99 6.8.3p3.  This cursor kind is used to describe the null statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CXCursor\\_DeclStmt                                         | Adaptor class for mixing declarations with statements and expressions.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_OMPParallelDirective                             | OpenMP parallel directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_OMPSimdDirective                                 | OpenMP SIMD directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_OMPForDirective                                  | OpenMP for directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CXCursor\\_OMPSectionsDirective                             | OpenMP sections directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_OMPSectionDirective                              | OpenMP section directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_OMPSingleDirective                               | OpenMP single directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_OMPParallelForDirective                          | OpenMP parallel for directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CXCursor\\_OMPParallelSectionsDirective                     | OpenMP parallel sections directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_OMPTaskDirective                                 | OpenMP task directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_OMPMasterDirective                               | OpenMP master directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_OMPCriticalDirective                             | OpenMP critical directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_OMPTaskyieldDirective                            | OpenMP taskyield directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| CXCursor\\_OMPBarrierDirective                              | OpenMP barrier directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_OMPTaskwaitDirective                             | OpenMP taskwait directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_OMPFlushDirective                                | OpenMP flush directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CXCursor\\_SEHLeaveStmt                                     | Windows Structured Exception Handling's leave statement.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_OMPOrderedDirective                              | OpenMP ordered directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_OMPAtomicDirective                               | OpenMP atomic directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_OMPForSimdDirective                              | OpenMP for SIMD directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_OMPParallelForSimdDirective                      | OpenMP parallel for SIMD directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_OMPTargetDirective                               | OpenMP target directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_OMPTeamsDirective                                | OpenMP teams directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CXCursor\\_OMPTaskgroupDirective                            | OpenMP taskgroup directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| CXCursor\\_OMPCancellationPointDirective                    | OpenMP cancellation point directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CXCursor\\_OMPCancelDirective                               | OpenMP cancel directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_OMPTargetDataDirective                           | OpenMP target data directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| CXCursor\\_OMPTaskLoopDirective                             | OpenMP taskloop directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_OMPTaskLoopSimdDirective                         | OpenMP taskloop simd directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_OMPDistributeDirective                           | OpenMP distribute directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CXCursor\\_OMPTargetEnterDataDirective                      | OpenMP target enter data directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_OMPTargetExitDataDirective                       | OpenMP target exit data directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_OMPTargetParallelDirective                       | OpenMP target parallel directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_OMPTargetParallelForDirective                    | OpenMP target parallel for directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CXCursor\\_OMPTargetUpdateDirective                         | OpenMP target update directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_OMPDistributeParallelForDirective                | OpenMP distribute parallel for directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_OMPDistributeParallelForSimdDirective            | OpenMP distribute parallel for simd directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CXCursor\\_OMPDistributeSimdDirective                       | OpenMP distribute simd directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_OMPTargetParallelForSimdDirective                | OpenMP target parallel for simd directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_OMPTargetSimdDirective                           | OpenMP target simd directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| CXCursor\\_OMPTeamsDistributeDirective                      | OpenMP teams distribute directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCursor\\_OMPTeamsDistributeSimdDirective                  | OpenMP teams distribute simd directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CXCursor\\_OMPTeamsDistributeParallelForSimdDirective       | OpenMP teams distribute parallel for simd directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CXCursor\\_OMPTeamsDistributeParallelForDirective           | OpenMP teams distribute parallel for directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_OMPTargetTeamsDirective                          | OpenMP target teams directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CXCursor\\_OMPTargetTeamsDistributeDirective                | OpenMP target teams distribute directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_OMPTargetTeamsDistributeParallelForDirective     | OpenMP target teams distribute parallel for directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_OMPTargetTeamsDistributeParallelForSimdDirective | OpenMP target teams distribute parallel for simd directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| CXCursor\\_OMPTargetTeamsDistributeSimdDirective            | OpenMP target teams distribute simd directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CXCursor\\_BuiltinBitCastExpr                               | C++2a std::bit\\_cast expression.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_OMPMasterTaskLoopDirective                       | OpenMP master taskloop directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_OMPParallelMasterTaskLoopDirective               | OpenMP parallel master taskloop directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_OMPMasterTaskLoopSimdDirective                   | OpenMP master taskloop simd directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_OMPParallelMasterTaskLoopSimdDirective           | OpenMP parallel master taskloop simd directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_OMPParallelMasterDirective                       | OpenMP parallel master directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCursor\\_OMPDepobjDirective                               | OpenMP depobj directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_OMPScanDirective                                 | OpenMP scan directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_OMPTileDirective                                 | OpenMP tile directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_OMPCanonicalLoop                                 | OpenMP canonical loop.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCursor\\_OMPInteropDirective                              | OpenMP interop directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCursor\\_OMPDispatchDirective                             | OpenMP dispatch directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCursor\\_OMPMaskedDirective                               | OpenMP masked directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_OMPUnrollDirective                               | OpenMP unroll directive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CXCursor\\_LastStmt                                         |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_TranslationUnit                                  | Cursor that represents the translation unit itself.  The translation unit cursor exists primarily to act as the root cursor for traversing the contents of a translation unit.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CXCursor\\_FirstAttr                                        |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_UnexposedAttr                                    | An attribute whose specific kind is not exposed via this interface.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCursor\\_IBActionAttr                                     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_IBOutletAttr                                     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_IBOutletCollectionAttr                           |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_CXXFinalAttr                                     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_CXXOverrideAttr                                  |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_AnnotateAttr                                     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_AsmLabelAttr                                     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_PackedAttr                                       |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_PureAttr                                         |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ConstAttr                                        |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_NoDuplicateAttr                                  |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_CUDAConstantAttr                                 |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_CUDADeviceAttr                                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_CUDAGlobalAttr                                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_CUDAHostAttr                                     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_CUDASharedAttr                                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_VisibilityAttr                                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_DLLExport                                        |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_DLLImport                                        |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_NSReturnsRetained                                |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_NSReturnsNotRetained                             |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_NSReturnsAutoreleased                            |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_NSConsumesSelf                                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_NSConsumed                                       |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCException                                    |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCNSObject                                     |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCIndependentClass                             |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCPreciseLifetime                              |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCReturnsInnerPointer                          |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCRequiresSuper                                |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCRootClass                                    |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCSubclassingRestricted                        |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCExplicitProtocolImpl                         |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCDesignatedInitializer                        |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCRuntimeVisible                               |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ObjCBoxable                                      |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_FlagEnum                                         |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ConvergentAttr                                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_WarnUnusedAttr                                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_WarnUnusedResultAttr                             |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_AlignedAttr                                      |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_LastAttr                                         |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_PreprocessingDirective                           |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_MacroDefinition                                  |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_MacroExpansion                                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_MacroInstantiation                               |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_InclusionDirective                               |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_FirstPreprocessing                               |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_LastPreprocessing                                |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_ModuleImportDecl                                 | A module import declaration.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CXCursor\\_TypeAliasTemplateDecl                            |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_StaticAssert                                     | A static\\_assert or \\_Static\\_assert node                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CXCursor\\_FriendDecl                                       | a friend declaration.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CXCursor\\_FirstExtraDecl                                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_LastExtraDecl                                    |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCursor\\_OverloadCandidate                                | A code completion overload candidate.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
"""
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
    CXCursor_OMPArrayShapingExpr = 150
    CXCursor_OMPIteratorExpr = 151
    CXCursor_CXXAddrspaceCastExpr = 152
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
    CXCursor_OMPTileDirective = 288
    CXCursor_OMPCanonicalLoop = 289
    CXCursor_OMPInteropDirective = 290
    CXCursor_OMPDispatchDirective = 291
    CXCursor_OMPMaskedDirective = 292
    CXCursor_OMPUnrollDirective = 293
    CXCursor_LastStmt = 293
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

"""
    CXCursor

A cursor representing some element in the abstract syntax tree for a translation unit.

The cursor abstraction unifies the different kinds of entities in a program--declaration, statements, expressions, references to declarations, etc.--under a single "cursor" abstraction with a common set of operations. Common operation for a cursor include: getting the physical location in a source file where the cursor points, getting the name associated with a cursor, and retrieving cursors for any child nodes of a particular cursor.

Cursors can be produced in two specific ways. clang\\_getTranslationUnitCursor() produces a cursor for a translation unit, from which one can use [`clang_visitChildren`](@ref)() to explore the rest of the translation unit. clang\\_getCursor() maps from a physical source location to the entity that resides at that location, allowing one to map from the source code into the AST.
"""
struct CXCursor
    kind::CXCursorKind
    xdata::Cint
    data::NTuple{3, Ptr{Cvoid}}
end

function clang_equalCursors(arg1, arg2)
    @ccall libclang.clang_equalCursors(arg1::CXCursor, arg2::CXCursor)::Cint
end

function clang_Cursor_isNull(cursor)
    @ccall libclang.clang_Cursor_isNull(cursor::CXCursor)::Cint
end

function clang_hashCursor(arg1)
    @ccall libclang.clang_hashCursor(arg1::CXCursor)::Cint
end

function clang_getCursorKind(arg1)
    @ccall libclang.clang_getCursorKind(arg1::CXCursor)::Cint
end

function clang_isDeclaration(arg1)
    @ccall libclang.clang_isDeclaration(arg1::CXCursorKind)::Cint
end

function clang_isInvalidDeclaration(arg1)
    @ccall libclang.clang_isInvalidDeclaration(arg1::CXCursor)::Cint
end

function clang_isReference(arg1)
    @ccall libclang.clang_isReference(arg1::CXCursorKind)::Cint
end

function clang_isExpression(arg1)
    @ccall libclang.clang_isExpression(arg1::CXCursorKind)::Cint
end

function clang_isStatement(arg1)
    @ccall libclang.clang_isStatement(arg1::CXCursorKind)::Cint
end

function clang_isAttribute(arg1)
    @ccall libclang.clang_isAttribute(arg1::CXCursorKind)::Cint
end

function clang_Cursor_hasAttrs(C)
    @ccall libclang.clang_Cursor_hasAttrs(C::CXCursor)::Cint
end

function clang_isInvalid(arg1)
    @ccall libclang.clang_isInvalid(arg1::CXCursorKind)::Cint
end

function clang_isTranslationUnit(arg1)
    @ccall libclang.clang_isTranslationUnit(arg1::CXCursorKind)::Cint
end

function clang_isPreprocessing(arg1)
    @ccall libclang.clang_isPreprocessing(arg1::CXCursorKind)::Cint
end

function clang_isUnexposed(arg1)
    @ccall libclang.clang_isUnexposed(arg1::CXCursorKind)::Cint
end

"""
    CXLinkageKind

Describe the linkage of the entity referred to by a cursor.

| Enumerator                 | Note                                                                                                                                    |
| :------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------- |
| CXLinkage\\_Invalid        | This value indicates that no linkage information is available for a provided [`CXCursor`](@ref).                                        |
| CXLinkage\\_NoLinkage      | This is the linkage for variables, parameters, and so on that have automatic storage. This covers normal (non-extern) local variables.  |
| CXLinkage\\_Internal       | This is the linkage for static variables and static functions.                                                                          |
| CXLinkage\\_UniqueExternal | This is the linkage for entities with external linkage that live in C++ anonymous namespaces.                                           |
| CXLinkage\\_External       | This is the linkage for entities with true, external linkage.                                                                           |
"""
@cenum CXLinkageKind::UInt32 begin
    CXLinkage_Invalid = 0
    CXLinkage_NoLinkage = 1
    CXLinkage_Internal = 2
    CXLinkage_UniqueExternal = 3
    CXLinkage_External = 4
end

function clang_getCursorLinkage(cursor)
    @ccall libclang.clang_getCursorLinkage(cursor::CXCursor)::Cint
end

"""
    CXVisibilityKind

| Enumerator               | Note                                                                                                 |
| :----------------------- | :--------------------------------------------------------------------------------------------------- |
| CXVisibility\\_Invalid   | This value indicates that no visibility information is available for a provided [`CXCursor`](@ref).  |
| CXVisibility\\_Hidden    | Symbol not seen by the linker.                                                                       |
| CXVisibility\\_Protected | Symbol seen by the linker but resolves to a symbol inside this object.                               |
| CXVisibility\\_Default   | Symbol seen by the linker and acts like a normal symbol.                                             |
"""
@cenum CXVisibilityKind::UInt32 begin
    CXVisibility_Invalid = 0
    CXVisibility_Hidden = 1
    CXVisibility_Protected = 2
    CXVisibility_Default = 3
end

function clang_getCursorVisibility(cursor)
    @ccall libclang.clang_getCursorVisibility(cursor::CXCursor)::Cint
end

function clang_getCursorAvailability(cursor)
    @ccall libclang.clang_getCursorAvailability(cursor::CXCursor)::Cint
end

"""
    CXPlatformAvailability

| Field       | Note                                                                                          |
| :---------- | :-------------------------------------------------------------------------------------------- |
| Introduced  | The version number in which this entity was introduced.                                       |
| Deprecated  | The version number in which this entity was deprecated (but is still available).              |
| Obsoleted   | The version number in which this entity was obsoleted, and therefore is no longer available.  |
| Unavailable | Whether the entity is unconditionally unavailable on this platform.                           |
"""
struct CXPlatformAvailability
    Platform::Cint
    Introduced::CXVersion
    Deprecated::CXVersion
    Obsoleted::CXVersion
    Unavailable::Cint
    Message::Cint
end

function clang_getCursorPlatformAvailability(cursor, always_deprecated, deprecated_message, always_unavailable, unavailable_message, availability, availability_size)
    @ccall libclang.clang_getCursorPlatformAvailability(cursor::CXCursor, always_deprecated::Ptr{Cint}, deprecated_message::Ptr{Cint}, always_unavailable::Ptr{Cint}, unavailable_message::Ptr{Cint}, availability::Ptr{CXPlatformAvailability}, availability_size::Cint)::Cint
end

function clang_disposeCXPlatformAvailability(availability)
    @ccall libclang.clang_disposeCXPlatformAvailability(availability::Ptr{CXPlatformAvailability})::Cint
end

function clang_Cursor_hasVarDeclGlobalStorage(cursor)
    @ccall libclang.clang_Cursor_hasVarDeclGlobalStorage(cursor::CXCursor)::Cint
end

function clang_Cursor_hasVarDeclExternalStorage(cursor)
    @ccall libclang.clang_Cursor_hasVarDeclExternalStorage(cursor::CXCursor)::Cint
end

"""
    CXLanguageKind

Describe the "language" of the entity referred to by a cursor.
"""
@cenum CXLanguageKind::UInt32 begin
    CXLanguage_Invalid = 0
    CXLanguage_C = 1
    CXLanguage_ObjC = 2
    CXLanguage_CPlusPlus = 3
end

function clang_getCursorLanguage(cursor)
    @ccall libclang.clang_getCursorLanguage(cursor::CXCursor)::Cint
end

"""
    CXTLSKind

Describe the "thread-local storage (TLS) kind" of the declaration referred to by a cursor.
"""
@cenum CXTLSKind::UInt32 begin
    CXTLS_None = 0
    CXTLS_Dynamic = 1
    CXTLS_Static = 2
end

function clang_getCursorTLSKind(cursor)
    @ccall libclang.clang_getCursorTLSKind(cursor::CXCursor)::Cint
end

mutable struct CXCursorSetImpl end

"""
A fast container representing a set of CXCursors.
"""
const CXCursorSet = Ptr{CXCursorSetImpl}

function clang_disposeCXCursorSet(cset)
    @ccall libclang.clang_disposeCXCursorSet(cset::CXCursorSet)::Cint
end

function clang_CXCursorSet_contains(cset, cursor)
    @ccall libclang.clang_CXCursorSet_contains(cset::CXCursorSet, cursor::CXCursor)::Cint
end

function clang_CXCursorSet_insert(cset, cursor)
    @ccall libclang.clang_CXCursorSet_insert(cset::CXCursorSet, cursor::CXCursor)::Cint
end

function clang_getOverriddenCursors(cursor, overridden, num_overridden)
    @ccall libclang.clang_getOverriddenCursors(cursor::CXCursor, overridden::Ptr{Ptr{CXCursor}}, num_overridden::Ptr{Cuint})::Cint
end

function clang_disposeOverriddenCursors(overridden)
    @ccall libclang.clang_disposeOverriddenCursors(overridden::Ptr{CXCursor})::Cint
end

"""
    CXTypeKind

Describes the kind of type

| Enumerator                                              | Note                                                                                                                                           |
| :------------------------------------------------------ | :--------------------------------------------------------------------------------------------------------------------------------------------- |
| CXType\\_Invalid                                        | Represents an invalid type (e.g., where no type is available).                                                                                 |
| CXType\\_Unexposed                                      | A type whose specific kind is not exposed via this interface.                                                                                  |
| CXType\\_Void                                           |                                                                                                                                                |
| CXType\\_Bool                                           |                                                                                                                                                |
| CXType\\_Char\\_U                                       |                                                                                                                                                |
| CXType\\_UChar                                          |                                                                                                                                                |
| CXType\\_Char16                                         |                                                                                                                                                |
| CXType\\_Char32                                         |                                                                                                                                                |
| CXType\\_UShort                                         |                                                                                                                                                |
| CXType\\_UInt                                           |                                                                                                                                                |
| CXType\\_ULong                                          |                                                                                                                                                |
| CXType\\_ULongLong                                      |                                                                                                                                                |
| CXType\\_UInt128                                        |                                                                                                                                                |
| CXType\\_Char\\_S                                       |                                                                                                                                                |
| CXType\\_SChar                                          |                                                                                                                                                |
| CXType\\_WChar                                          |                                                                                                                                                |
| CXType\\_Short                                          |                                                                                                                                                |
| CXType\\_Int                                            |                                                                                                                                                |
| CXType\\_Long                                           |                                                                                                                                                |
| CXType\\_LongLong                                       |                                                                                                                                                |
| CXType\\_Int128                                         |                                                                                                                                                |
| CXType\\_Float                                          |                                                                                                                                                |
| CXType\\_Double                                         |                                                                                                                                                |
| CXType\\_LongDouble                                     |                                                                                                                                                |
| CXType\\_NullPtr                                        |                                                                                                                                                |
| CXType\\_Overload                                       |                                                                                                                                                |
| CXType\\_Dependent                                      |                                                                                                                                                |
| CXType\\_ObjCId                                         |                                                                                                                                                |
| CXType\\_ObjCClass                                      |                                                                                                                                                |
| CXType\\_ObjCSel                                        |                                                                                                                                                |
| CXType\\_Float128                                       |                                                                                                                                                |
| CXType\\_Half                                           |                                                                                                                                                |
| CXType\\_Float16                                        |                                                                                                                                                |
| CXType\\_ShortAccum                                     |                                                                                                                                                |
| CXType\\_Accum                                          |                                                                                                                                                |
| CXType\\_LongAccum                                      |                                                                                                                                                |
| CXType\\_UShortAccum                                    |                                                                                                                                                |
| CXType\\_UAccum                                         |                                                                                                                                                |
| CXType\\_ULongAccum                                     |                                                                                                                                                |
| CXType\\_BFloat16                                       |                                                                                                                                                |
| CXType\\_FirstBuiltin                                   |                                                                                                                                                |
| CXType\\_LastBuiltin                                    |                                                                                                                                                |
| CXType\\_Complex                                        |                                                                                                                                                |
| CXType\\_Pointer                                        |                                                                                                                                                |
| CXType\\_BlockPointer                                   |                                                                                                                                                |
| CXType\\_LValueReference                                |                                                                                                                                                |
| CXType\\_RValueReference                                |                                                                                                                                                |
| CXType\\_Record                                         |                                                                                                                                                |
| CXType\\_Enum                                           |                                                                                                                                                |
| CXType\\_Typedef                                        |                                                                                                                                                |
| CXType\\_ObjCInterface                                  |                                                                                                                                                |
| CXType\\_ObjCObjectPointer                              |                                                                                                                                                |
| CXType\\_FunctionNoProto                                |                                                                                                                                                |
| CXType\\_FunctionProto                                  |                                                                                                                                                |
| CXType\\_ConstantArray                                  |                                                                                                                                                |
| CXType\\_Vector                                         |                                                                                                                                                |
| CXType\\_IncompleteArray                                |                                                                                                                                                |
| CXType\\_VariableArray                                  |                                                                                                                                                |
| CXType\\_DependentSizedArray                            |                                                                                                                                                |
| CXType\\_MemberPointer                                  |                                                                                                                                                |
| CXType\\_Auto                                           |                                                                                                                                                |
| CXType\\_Elaborated                                     | Represents a type that was referred to using an elaborated type keyword.  E.g., struct S, or via a qualified name, e.g., N::M::type, or both.  |
| CXType\\_Pipe                                           |                                                                                                                                                |
| CXType\\_OCLImage1dRO                                   |                                                                                                                                                |
| CXType\\_OCLImage1dArrayRO                              |                                                                                                                                                |
| CXType\\_OCLImage1dBufferRO                             |                                                                                                                                                |
| CXType\\_OCLImage2dRO                                   |                                                                                                                                                |
| CXType\\_OCLImage2dArrayRO                              |                                                                                                                                                |
| CXType\\_OCLImage2dDepthRO                              |                                                                                                                                                |
| CXType\\_OCLImage2dArrayDepthRO                         |                                                                                                                                                |
| CXType\\_OCLImage2dMSAARO                               |                                                                                                                                                |
| CXType\\_OCLImage2dArrayMSAARO                          |                                                                                                                                                |
| CXType\\_OCLImage2dMSAADepthRO                          |                                                                                                                                                |
| CXType\\_OCLImage2dArrayMSAADepthRO                     |                                                                                                                                                |
| CXType\\_OCLImage3dRO                                   |                                                                                                                                                |
| CXType\\_OCLImage1dWO                                   |                                                                                                                                                |
| CXType\\_OCLImage1dArrayWO                              |                                                                                                                                                |
| CXType\\_OCLImage1dBufferWO                             |                                                                                                                                                |
| CXType\\_OCLImage2dWO                                   |                                                                                                                                                |
| CXType\\_OCLImage2dArrayWO                              |                                                                                                                                                |
| CXType\\_OCLImage2dDepthWO                              |                                                                                                                                                |
| CXType\\_OCLImage2dArrayDepthWO                         |                                                                                                                                                |
| CXType\\_OCLImage2dMSAAWO                               |                                                                                                                                                |
| CXType\\_OCLImage2dArrayMSAAWO                          |                                                                                                                                                |
| CXType\\_OCLImage2dMSAADepthWO                          |                                                                                                                                                |
| CXType\\_OCLImage2dArrayMSAADepthWO                     |                                                                                                                                                |
| CXType\\_OCLImage3dWO                                   |                                                                                                                                                |
| CXType\\_OCLImage1dRW                                   |                                                                                                                                                |
| CXType\\_OCLImage1dArrayRW                              |                                                                                                                                                |
| CXType\\_OCLImage1dBufferRW                             |                                                                                                                                                |
| CXType\\_OCLImage2dRW                                   |                                                                                                                                                |
| CXType\\_OCLImage2dArrayRW                              |                                                                                                                                                |
| CXType\\_OCLImage2dDepthRW                              |                                                                                                                                                |
| CXType\\_OCLImage2dArrayDepthRW                         |                                                                                                                                                |
| CXType\\_OCLImage2dMSAARW                               |                                                                                                                                                |
| CXType\\_OCLImage2dArrayMSAARW                          |                                                                                                                                                |
| CXType\\_OCLImage2dMSAADepthRW                          |                                                                                                                                                |
| CXType\\_OCLImage2dArrayMSAADepthRW                     |                                                                                                                                                |
| CXType\\_OCLImage3dRW                                   |                                                                                                                                                |
| CXType\\_OCLSampler                                     |                                                                                                                                                |
| CXType\\_OCLEvent                                       |                                                                                                                                                |
| CXType\\_OCLQueue                                       |                                                                                                                                                |
| CXType\\_OCLReserveID                                   |                                                                                                                                                |
| CXType\\_ObjCObject                                     |                                                                                                                                                |
| CXType\\_ObjCTypeParam                                  |                                                                                                                                                |
| CXType\\_Attributed                                     |                                                                                                                                                |
| CXType\\_OCLIntelSubgroupAVCMcePayload                  |                                                                                                                                                |
| CXType\\_OCLIntelSubgroupAVCImePayload                  |                                                                                                                                                |
| CXType\\_OCLIntelSubgroupAVCRefPayload                  |                                                                                                                                                |
| CXType\\_OCLIntelSubgroupAVCSicPayload                  |                                                                                                                                                |
| CXType\\_OCLIntelSubgroupAVCMceResult                   |                                                                                                                                                |
| CXType\\_OCLIntelSubgroupAVCImeResult                   |                                                                                                                                                |
| CXType\\_OCLIntelSubgroupAVCRefResult                   |                                                                                                                                                |
| CXType\\_OCLIntelSubgroupAVCSicResult                   |                                                                                                                                                |
| CXType\\_OCLIntelSubgroupAVCImeResultSingleRefStreamout |                                                                                                                                                |
| CXType\\_OCLIntelSubgroupAVCImeResultDualRefStreamout   |                                                                                                                                                |
| CXType\\_OCLIntelSubgroupAVCImeSingleRefStreamin        |                                                                                                                                                |
| CXType\\_OCLIntelSubgroupAVCImeDualRefStreamin          |                                                                                                                                                |
| CXType\\_ExtVector                                      |                                                                                                                                                |
| CXType\\_Atomic                                         |                                                                                                                                                |
"""
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

"""
    CXCallingConv

Describes the calling convention of a function type
"""
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
    CXCallingConv_SwiftAsync = 17
    CXCallingConv_Invalid = 100
    CXCallingConv_Unexposed = 200
end

"""
    CXType

The type of an element in the abstract syntax tree.
"""
struct CXType
    kind::CXTypeKind
    data::NTuple{2, Ptr{Cvoid}}
end

function clang_getEnumConstantDeclValue(C)
    @ccall libclang.clang_getEnumConstantDeclValue(C::CXCursor)::Cint
end

function clang_getEnumConstantDeclUnsignedValue(C)
    @ccall libclang.clang_getEnumConstantDeclUnsignedValue(C::CXCursor)::Cint
end

function clang_getFieldDeclBitWidth(C)
    @ccall libclang.clang_getFieldDeclBitWidth(C::CXCursor)::Cint
end

function clang_Cursor_getNumArguments(C)
    @ccall libclang.clang_Cursor_getNumArguments(C::CXCursor)::Cint
end

"""
    CXTemplateArgumentKind

Describes the kind of a template argument.

See the definition of llvm::clang::TemplateArgument::ArgKind for full element descriptions.
"""
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
    @ccall libclang.clang_Cursor_getTemplateArgumentKind(C::CXCursor, I::Cuint)::Cint
end

function clang_Cursor_getTemplateArgumentValue(C, I)
    @ccall libclang.clang_Cursor_getTemplateArgumentValue(C::CXCursor, I::Cuint)::Cint
end

function clang_Cursor_getTemplateArgumentUnsignedValue(C, I)
    @ccall libclang.clang_Cursor_getTemplateArgumentUnsignedValue(C::CXCursor, I::Cuint)::Cint
end

function clang_equalTypes(A, B)
    @ccall libclang.clang_equalTypes(A::CXType, B::CXType)::Cint
end

function clang_isConstQualifiedType(T)
    @ccall libclang.clang_isConstQualifiedType(T::CXType)::Cint
end

function clang_Cursor_isMacroFunctionLike(C)
    @ccall libclang.clang_Cursor_isMacroFunctionLike(C::CXCursor)::Cint
end

function clang_Cursor_isMacroBuiltin(C)
    @ccall libclang.clang_Cursor_isMacroBuiltin(C::CXCursor)::Cint
end

function clang_Cursor_isFunctionInlined(C)
    @ccall libclang.clang_Cursor_isFunctionInlined(C::CXCursor)::Cint
end

function clang_isVolatileQualifiedType(T)
    @ccall libclang.clang_isVolatileQualifiedType(T::CXType)::Cint
end

function clang_isRestrictQualifiedType(T)
    @ccall libclang.clang_isRestrictQualifiedType(T::CXType)::Cint
end

function clang_getAddressSpace(T)
    @ccall libclang.clang_getAddressSpace(T::CXType)::Cint
end

function clang_getFunctionTypeCallingConv(T)
    @ccall libclang.clang_getFunctionTypeCallingConv(T::CXType)::Cint
end

function clang_getExceptionSpecificationType(T)
    @ccall libclang.clang_getExceptionSpecificationType(T::CXType)::Cint
end

function clang_getNumArgTypes(T)
    @ccall libclang.clang_getNumArgTypes(T::CXType)::Cint
end

function clang_Type_getNumObjCProtocolRefs(T)
    @ccall libclang.clang_Type_getNumObjCProtocolRefs(T::CXType)::Cint
end

function clang_Type_getNumObjCTypeArgs(T)
    @ccall libclang.clang_Type_getNumObjCTypeArgs(T::CXType)::Cint
end

function clang_isFunctionTypeVariadic(T)
    @ccall libclang.clang_isFunctionTypeVariadic(T::CXType)::Cint
end

function clang_getCursorExceptionSpecificationType(C)
    @ccall libclang.clang_getCursorExceptionSpecificationType(C::CXCursor)::Cint
end

function clang_isPODType(T)
    @ccall libclang.clang_isPODType(T::CXType)::Cint
end

function clang_getNumElements(T)
    @ccall libclang.clang_getNumElements(T::CXType)::Cint
end

function clang_getArraySize(T)
    @ccall libclang.clang_getArraySize(T::CXType)::Cint
end

function clang_Type_isTransparentTagTypedef(T)
    @ccall libclang.clang_Type_isTransparentTagTypedef(T::CXType)::Cint
end

"""
    CXTypeNullabilityKind

| Enumerator                         | Note                                                                                                                                                                                                                                                                  |
| :--------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CXTypeNullability\\_NonNull        | Values of this type can never be null.                                                                                                                                                                                                                                |
| CXTypeNullability\\_Nullable       | Values of this type can be null.                                                                                                                                                                                                                                      |
| CXTypeNullability\\_Unspecified    | Whether values of this type can be null is (explicitly) unspecified. This captures a (fairly rare) case where we can't conclude anything about the nullability of the type even though it has been considered.                                                        |
| CXTypeNullability\\_Invalid        | Nullability is not applicable to this type.                                                                                                                                                                                                                           |
| CXTypeNullability\\_NullableResult | Generally behaves like Nullable, except when used in a block parameter that was imported into a swift async method. There, swift will assume that the parameter can get null even if no error occured. \\_Nullable parameters are assumed to only get null on error.  |
"""
@cenum CXTypeNullabilityKind::UInt32 begin
    CXTypeNullability_NonNull = 0
    CXTypeNullability_Nullable = 1
    CXTypeNullability_Unspecified = 2
    CXTypeNullability_Invalid = 3
    CXTypeNullability_NullableResult = 4
end

function clang_Type_getNullability(T)
    @ccall libclang.clang_Type_getNullability(T::CXType)::Cint
end

"""
    CXTypeLayoutError

List the possible error codes for [`clang_Type_getSizeOf`](@ref), [`clang_Type_getAlignOf`](@ref), [`clang_Type_getOffsetOf`](@ref) and `clang_Cursor_getOffsetOf`.

A value of this enumeration type can be returned if the target type is not a valid argument to sizeof, alignof or offsetof.

| Enumerator                           | Note                                          |
| :----------------------------------- | :-------------------------------------------- |
| CXTypeLayoutError\\_Invalid          | Type is of kind CXType\\_Invalid.             |
| CXTypeLayoutError\\_Incomplete       | The type is an incomplete Type.               |
| CXTypeLayoutError\\_Dependent        | The type is a dependent Type.                 |
| CXTypeLayoutError\\_NotConstantSize  | The type is not a constant size type.         |
| CXTypeLayoutError\\_InvalidFieldName | The Field name is not valid for this record.  |
| CXTypeLayoutError\\_Undeduced        | The type is undeduced.                        |
"""
@cenum CXTypeLayoutError::Int32 begin
    CXTypeLayoutError_Invalid = -1
    CXTypeLayoutError_Incomplete = -2
    CXTypeLayoutError_Dependent = -3
    CXTypeLayoutError_NotConstantSize = -4
    CXTypeLayoutError_InvalidFieldName = -5
    CXTypeLayoutError_Undeduced = -6
end

function clang_Type_getAlignOf(T)
    @ccall libclang.clang_Type_getAlignOf(T::CXType)::Cint
end

function clang_Type_getSizeOf(T)
    @ccall libclang.clang_Type_getSizeOf(T::CXType)::Cint
end

function clang_Type_getOffsetOf(T, S)
    @ccall libclang.clang_Type_getOffsetOf(T::CXType, S::Cstring)::Cint
end

function clang_Cursor_getOffsetOfField(C)
    @ccall libclang.clang_Cursor_getOffsetOfField(C::CXCursor)::Cint
end

function clang_Cursor_isAnonymous(C)
    @ccall libclang.clang_Cursor_isAnonymous(C::CXCursor)::Cint
end

function clang_Cursor_isAnonymousRecordDecl(C)
    @ccall libclang.clang_Cursor_isAnonymousRecordDecl(C::CXCursor)::Cint
end

function clang_Cursor_isInlineNamespace(C)
    @ccall libclang.clang_Cursor_isInlineNamespace(C::CXCursor)::Cint
end

"""
    CXRefQualifierKind

| Enumerator              | Note                                          |
| :---------------------- | :-------------------------------------------- |
| CXRefQualifier\\_None   | No ref-qualifier was provided.                |
| CXRefQualifier\\_LValue | An lvalue ref-qualifier was provided (`&).`   |
| CXRefQualifier\\_RValue | An rvalue ref-qualifier was provided (`&&).`  |
"""
@cenum CXRefQualifierKind::UInt32 begin
    CXRefQualifier_None = 0
    CXRefQualifier_LValue = 1
    CXRefQualifier_RValue = 2
end

function clang_Type_getNumTemplateArguments(T)
    @ccall libclang.clang_Type_getNumTemplateArguments(T::CXType)::Cint
end

function clang_Type_getCXXRefQualifier(T)
    @ccall libclang.clang_Type_getCXXRefQualifier(T::CXType)::Cint
end

function clang_Cursor_isBitField(C)
    @ccall libclang.clang_Cursor_isBitField(C::CXCursor)::Cint
end

function clang_isVirtualBase(arg1)
    @ccall libclang.clang_isVirtualBase(arg1::CXCursor)::Cint
end

"""
    CX_CXXAccessSpecifier

Represents the C++ access control level to a base class for a cursor with kind CX\\_CXXBaseSpecifier.
"""
@cenum CX_CXXAccessSpecifier::UInt32 begin
    CX_CXXInvalidAccessSpecifier = 0
    CX_CXXPublic = 1
    CX_CXXProtected = 2
    CX_CXXPrivate = 3
end

function clang_getCXXAccessSpecifier(arg1)
    @ccall libclang.clang_getCXXAccessSpecifier(arg1::CXCursor)::Cint
end

"""
    CX_StorageClass

Represents the storage classes as declared in the source. CX\\_SC\\_Invalid was added for the case that the passed cursor in not a declaration.
"""
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
    @ccall libclang.clang_Cursor_getStorageClass(arg1::CXCursor)::Cint
end

function clang_getNumOverloadedDecls(cursor)
    @ccall libclang.clang_getNumOverloadedDecls(cursor::CXCursor)::Cint
end

"""
    CXChildVisitResult

Describes how the traversal of the children of a particular cursor should proceed after visiting a particular child cursor.

A value of this enumeration type should be returned by each [`CXCursorVisitor`](@ref) to indicate how [`clang_visitChildren`](@ref)() proceed.

| Enumerator              | Note                                                                                                             |
| :---------------------- | :--------------------------------------------------------------------------------------------------------------- |
| CXChildVisit\\_Break    | Terminates the cursor traversal.                                                                                 |
| CXChildVisit\\_Continue | Continues the cursor traversal with the next sibling of the cursor just visited, without visiting its children.  |
| CXChildVisit\\_Recurse  | Recursively traverse the children of this cursor, using the same visitor and client data.                        |
"""
@cenum CXChildVisitResult::UInt32 begin
    CXChildVisit_Break = 0
    CXChildVisit_Continue = 1
    CXChildVisit_Recurse = 2
end

# typedef enum CXChildVisitResult ( * CXCursorVisitor ) ( CXCursor cursor , CXCursor parent , CXClientData client_data )
"""
Visitor invoked for each cursor found by a traversal.

This visitor function will be invoked for each cursor found by clang\\_visitCursorChildren(). Its first argument is the cursor being visited, its second argument is the parent visitor for that cursor, and its third argument is the client data provided to clang\\_visitCursorChildren().

The visitor should return one of the [`CXChildVisitResult`](@ref) values to direct clang\\_visitCursorChildren().
"""
const CXCursorVisitor = Ptr{Cvoid}

function clang_visitChildren(parent, visitor, client_data)
    @ccall libclang.clang_visitChildren(parent::CXCursor, visitor::CXCursorVisitor, client_data::CXClientData)::Cint
end

"""
Opaque pointer representing a policy that controls pretty printing for `clang_getCursorPrettyPrinted`.
"""
const CXPrintingPolicy = Ptr{Cvoid}

"""
    CXPrintingPolicyProperty

Properties for the printing policy.

See `clang`::PrintingPolicy for more information.
"""
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
    @ccall libclang.clang_PrintingPolicy_getProperty(Policy::CXPrintingPolicy, Property::CXPrintingPolicyProperty)::Cint
end

function clang_PrintingPolicy_setProperty(Policy, Property, Value)
    @ccall libclang.clang_PrintingPolicy_setProperty(Policy::CXPrintingPolicy, Property::CXPrintingPolicyProperty, Value::Cuint)::Cint
end

function clang_PrintingPolicy_dispose(Policy)
    @ccall libclang.clang_PrintingPolicy_dispose(Policy::CXPrintingPolicy)::Cint
end

function clang_isCursorDefinition(arg1)
    @ccall libclang.clang_isCursorDefinition(arg1::CXCursor)::Cint
end

function clang_Cursor_getObjCSelectorIndex(arg1)
    @ccall libclang.clang_Cursor_getObjCSelectorIndex(arg1::CXCursor)::Cint
end

function clang_Cursor_isDynamicCall(C)
    @ccall libclang.clang_Cursor_isDynamicCall(C::CXCursor)::Cint
end

"""
    CXObjCPropertyAttrKind

Property attributes for a `CXCursor_ObjCPropertyDecl`.
"""
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
    @ccall libclang.clang_Cursor_getObjCPropertyAttributes(C::CXCursor, reserved::Cuint)::Cint
end

"""
    CXObjCDeclQualifierKind

'Qualifiers' written next to the return and parameter types in Objective-C method declarations.
"""
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
    @ccall libclang.clang_Cursor_getObjCDeclQualifiers(C::CXCursor)::Cint
end

function clang_Cursor_isObjCOptional(C)
    @ccall libclang.clang_Cursor_isObjCOptional(C::CXCursor)::Cint
end

function clang_Cursor_isVariadic(C)
    @ccall libclang.clang_Cursor_isVariadic(C::CXCursor)::Cint
end

function clang_Cursor_isExternalSymbol(C, language, definedIn, isGenerated)
    @ccall libclang.clang_Cursor_isExternalSymbol(C::CXCursor, language::Ptr{Cint}, definedIn::Ptr{Cint}, isGenerated::Ptr{Cuint})::Cint
end

"""
` CINDEX_MODULE Module introspection`

The functions in this group provide access to information about modules.

@{
"""
const CXModule = Ptr{Cvoid}

function clang_Module_isSystem(Module)
    @ccall libclang.clang_Module_isSystem(Module::CXModule)::Cint
end

function clang_Module_getNumTopLevelHeaders(arg1, Module)
    @ccall libclang.clang_Module_getNumTopLevelHeaders(arg1::CXTranslationUnit, Module::CXModule)::Cint
end

function clang_CXXConstructor_isConvertingConstructor(C)
    @ccall libclang.clang_CXXConstructor_isConvertingConstructor(C::CXCursor)::Cint
end

function clang_CXXConstructor_isCopyConstructor(C)
    @ccall libclang.clang_CXXConstructor_isCopyConstructor(C::CXCursor)::Cint
end

function clang_CXXConstructor_isDefaultConstructor(C)
    @ccall libclang.clang_CXXConstructor_isDefaultConstructor(C::CXCursor)::Cint
end

function clang_CXXConstructor_isMoveConstructor(C)
    @ccall libclang.clang_CXXConstructor_isMoveConstructor(C::CXCursor)::Cint
end

function clang_CXXField_isMutable(C)
    @ccall libclang.clang_CXXField_isMutable(C::CXCursor)::Cint
end

function clang_CXXMethod_isDefaulted(C)
    @ccall libclang.clang_CXXMethod_isDefaulted(C::CXCursor)::Cint
end

function clang_CXXMethod_isPureVirtual(C)
    @ccall libclang.clang_CXXMethod_isPureVirtual(C::CXCursor)::Cint
end

function clang_CXXMethod_isStatic(C)
    @ccall libclang.clang_CXXMethod_isStatic(C::CXCursor)::Cint
end

function clang_CXXMethod_isVirtual(C)
    @ccall libclang.clang_CXXMethod_isVirtual(C::CXCursor)::Cint
end

function clang_CXXRecord_isAbstract(C)
    @ccall libclang.clang_CXXRecord_isAbstract(C::CXCursor)::Cint
end

function clang_EnumDecl_isScoped(C)
    @ccall libclang.clang_EnumDecl_isScoped(C::CXCursor)::Cint
end

function clang_CXXMethod_isConst(C)
    @ccall libclang.clang_CXXMethod_isConst(C::CXCursor)::Cint
end

function clang_getTemplateCursorKind(C)
    @ccall libclang.clang_getTemplateCursorKind(C::CXCursor)::Cint
end

"""
    CXNameRefFlags

| Enumerator                     | Note                                                                                                                                                                                                                                                                                                    |
| :----------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| CXNameRange\\_WantQualifier    | Include the nested-name-specifier, e.g. Foo:: in x.Foo::y, in the range.                                                                                                                                                                                                                                |
| CXNameRange\\_WantTemplateArgs | Include the explicit template arguments, e.g. <int> in x.f<int>, in the range.                                                                                                                                                                                                                          |
| CXNameRange\\_WantSinglePiece  | If the name is non-contiguous, return the full spanning range.  Non-contiguous names occur in Objective-C when a selector with two or more parameters is used, or in C++ when using an operator:  ```c++  [object doSomething:here withValue:there]; // Objective-C  return some_vector[1]; // C++ ```  |
"""
@cenum CXNameRefFlags::UInt32 begin
    CXNameRange_WantQualifier = 1
    CXNameRange_WantTemplateArgs = 2
    CXNameRange_WantSinglePiece = 4
end

"""
    CXTokenKind

Describes a kind of token.

| Enumerator            | Note                                             |
| :-------------------- | :----------------------------------------------- |
| CXToken\\_Punctuation | A token that contains some kind of punctuation.  |
| CXToken\\_Keyword     | A language keyword.                              |
| CXToken\\_Identifier  | An identifier (that is not a keyword).           |
| CXToken\\_Literal     | A numeric, string, or character literal.         |
| CXToken\\_Comment     | A comment.                                       |
"""
@cenum CXTokenKind::UInt32 begin
    CXToken_Punctuation = 0
    CXToken_Keyword = 1
    CXToken_Identifier = 2
    CXToken_Literal = 3
    CXToken_Comment = 4
end

"""
    CXToken

Describes a single preprocessing token.
"""
struct CXToken
    int_data::NTuple{4, Cuint}
    ptr_data::Ptr{Cvoid}
end

function clang_tokenize(TU, Range, Tokens, NumTokens)
    @ccall libclang.clang_tokenize(TU::CXTranslationUnit, Range::CXSourceRange, Tokens::Ptr{Ptr{CXToken}}, NumTokens::Ptr{Cuint})::Cint
end

function clang_annotateTokens(TU, Tokens, NumTokens, Cursors)
    @ccall libclang.clang_annotateTokens(TU::CXTranslationUnit, Tokens::Ptr{CXToken}, NumTokens::Cuint, Cursors::Ptr{CXCursor})::Cint
end

function clang_disposeTokens(TU, Tokens, NumTokens)
    @ccall libclang.clang_disposeTokens(TU::CXTranslationUnit, Tokens::Ptr{CXToken}, NumTokens::Cuint)::Cint
end

function clang_getDefinitionSpellingAndExtent(arg1, startBuf, endBuf, startLine, startColumn, endLine, endColumn)
    @ccall libclang.clang_getDefinitionSpellingAndExtent(arg1::CXCursor, startBuf::Ptr{Cstring}, endBuf::Ptr{Cstring}, startLine::Ptr{Cuint}, startColumn::Ptr{Cuint}, endLine::Ptr{Cuint}, endColumn::Ptr{Cuint})::Cint
end

function clang_enableStackTraces()
    @ccall libclang.clang_enableStackTraces()::Cint
end

function clang_executeOnThread(fn, user_data, stack_size)
    @ccall libclang.clang_executeOnThread(fn::Ptr{Cvoid}, user_data::Ptr{Cvoid}, stack_size::Cuint)::Cint
end

"""
A semantic string that describes a code-completion result.

A semantic string that describes the formatting of a code-completion result as a single "template" of text that should be inserted into the source buffer when a particular code-completion result is selected. Each semantic string is made up of some number of "chunks", each of which contains some text along with a description of what that text means, e.g., the name of the entity being referenced, whether the text chunk is part of the template, or whether it is a "placeholder" that the user should replace with actual code,of a specific kind. See [`CXCompletionChunkKind`](@ref) for a description of the different kinds of chunks.
"""
const CXCompletionString = Ptr{Cvoid}

"""
    CXCompletionResult

A single result of code completion.

| Field            | Note                                                                                                                                                                                                                                                                                                                                               |
| :--------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CursorKind       | The kind of entity that this completion refers to.  The cursor kind will be a macro, keyword, or a declaration (one of the *Decl cursor kinds), describing the entity that the completion is referring to.  \\todo In the future, we would like to provide a full cursor, to allow the client to extract additional information from declaration.  |
| CompletionString | The code-completion string that describes how to insert this code-completion result into the editing buffer.                                                                                                                                                                                                                                       |
"""
struct CXCompletionResult
    CursorKind::CXCursorKind
    CompletionString::CXCompletionString
end

"""
    CXCompletionChunkKind

Describes a single piece of text within a code-completion string.

Each "chunk" within a code-completion string ([`CXCompletionString`](@ref)) is either a piece of text with a specific "kind" that describes how that text should be interpreted by the client or is another completion string.

| Enumerator                           | Note                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| :----------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CXCompletionChunk\\_Optional         | A code-completion string that describes "optional" text that could be a part of the template (but is not required).  The Optional chunk is the only kind of chunk that has a code-completion string for its representation, which is accessible via `clang_getCompletionChunkCompletionString`(). The code-completion string describes an additional part of the template that is completely optional. For example, optional chunks can be used to describe the placeholders for arguments that match up with defaulted function parameters, e.g. given:  ```c++  void f(int x, float y = 3.14, double z = 2.71828); ```  The code-completion string for this function would contain: - a TypedText chunk for "f". - a LeftParen chunk for "(". - a Placeholder chunk for "int x" - an Optional chunk containing the remaining defaulted arguments, e.g., - a Comma chunk for "," - a Placeholder chunk for "float y" - an Optional chunk containing the last defaulted argument: - a Comma chunk for "," - a Placeholder chunk for "double z" - a RightParen chunk for ")"  There are many ways to handle Optional chunks. Two simple approaches are: - Completely ignore optional chunks, in which case the template for the function "f" would only include the first parameter ("int x"). - Fully expand all optional chunks, in which case the template for the function "f" would have all of the parameters.  |
| CXCompletionChunk\\_TypedText        | Text that a user would be expected to type to get this code-completion result.  There will be exactly one "typed text" chunk in a semantic string, which will typically provide the spelling of a keyword or the name of a declaration that could be used at the current code point. Clients are expected to filter the code-completion results based on the text in this chunk.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CXCompletionChunk\\_Text             | Text that should be inserted as part of a code-completion result.  A "text" chunk represents text that is part of the template to be inserted into user code should this particular code-completion result be selected.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CXCompletionChunk\\_Placeholder      | Placeholder text that should be replaced by the user.  A "placeholder" chunk marks a place where the user should insert text into the code-completion template. For example, placeholders might mark the function parameters for a function declaration, to indicate that the user should provide arguments for each of those parameters. The actual text in a placeholder is a suggestion for the text to display before the user replaces the placeholder with real code.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCompletionChunk\\_Informative      | Informative text that should be displayed but never inserted as part of the template.  An "informative" chunk contains annotations that can be displayed to help the user decide whether a particular code-completion result is the right option, but which is not part of the actual template to be inserted by code completion.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CXCompletionChunk\\_CurrentParameter | Text that describes the current parameter when code-completion is referring to function call, message send, or template specialization.  A "current parameter" chunk occurs when code-completion is providing information about a parameter corresponding to the argument at the code-completion point. For example, given a function  ```c++  int add(int x, int y); ```  and the source code `add`(, where the code-completion point is after the "(", the code-completion string will contain a "current parameter" chunk for "int x", indicating that the current argument will initialize that parameter. After typing further, to `add`(17, (where the code-completion point is after the ","), the code-completion string will contain a "current parameter" chunk to "int y".                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCompletionChunk\\_LeftParen        | A left parenthesis ('('), used to initiate a function call or signal the beginning of a function parameter list.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CXCompletionChunk\\_RightParen       | A right parenthesis (')'), used to finish a function call or signal the end of a function parameter list.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CXCompletionChunk\\_LeftBracket      | A left bracket ('[').                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CXCompletionChunk\\_RightBracket     | A right bracket (']').                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CXCompletionChunk\\_LeftBrace        | A left brace ('{').                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CXCompletionChunk\\_RightBrace       | A right brace ('}').                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CXCompletionChunk\\_LeftAngle        | A left angle bracket ('<').                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CXCompletionChunk\\_RightAngle       | A right angle bracket ('>').                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCompletionChunk\\_Comma            | A comma separator (',').                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CXCompletionChunk\\_ResultType       | Text that specifies the result type of a given result.  This special kind of informative chunk is not meant to be inserted into the text buffer. Rather, it is meant to illustrate the type that an expression using the given completion string would have.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCompletionChunk\\_Colon            | A colon (':').                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CXCompletionChunk\\_SemiColon        | A semicolon (';').                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CXCompletionChunk\\_Equal            | An '=' sign.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CXCompletionChunk\\_HorizontalSpace  | Horizontal space (' ').                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CXCompletionChunk\\_VerticalSpace    | Vertical space ('\\n'), after which it is generally a good idea to perform indentation.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
"""
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
    @ccall libclang.clang_getCompletionChunkKind(completion_string::CXCompletionString, chunk_number::Cuint)::Cint
end

function clang_getNumCompletionChunks(completion_string)
    @ccall libclang.clang_getNumCompletionChunks(completion_string::CXCompletionString)::Cint
end

function clang_getCompletionPriority(completion_string)
    @ccall libclang.clang_getCompletionPriority(completion_string::CXCompletionString)::Cint
end

function clang_getCompletionAvailability(completion_string)
    @ccall libclang.clang_getCompletionAvailability(completion_string::CXCompletionString)::Cint
end

function clang_getCompletionNumAnnotations(completion_string)
    @ccall libclang.clang_getCompletionNumAnnotations(completion_string::CXCompletionString)::Cint
end

"""
    CXCodeCompleteResults

Contains the results of code-completion.

This data structure contains the results of code completion, as produced by `clang_codeCompleteAt`(). Its contents must be freed by [`clang_disposeCodeCompleteResults`](@ref).

| Field      | Note                                                                  |
| :--------- | :-------------------------------------------------------------------- |
| Results    | The code-completion results.                                          |
| NumResults | The number of code-completion results stored in the `Results` array.  |
"""
struct CXCodeCompleteResults
    Results::Ptr{CXCompletionResult}
    NumResults::Cuint
end

function clang_getCompletionNumFixIts(results, completion_index)
    @ccall libclang.clang_getCompletionNumFixIts(results::Ptr{CXCodeCompleteResults}, completion_index::Cuint)::Cint
end

"""
    CXCodeComplete_Flags

Flags that can be passed to `clang_codeCompleteAt`() to modify its behavior.

The enumerators in this enumeration can be bitwise-OR'd together to provide multiple options to `clang_codeCompleteAt`().

| Enumerator                                    | Note                                                                                                                                                                                                                   |
| :-------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CXCodeComplete\\_IncludeMacros                | Whether to include macros within the set of code completions returned.                                                                                                                                                 |
| CXCodeComplete\\_IncludeCodePatterns          | Whether to include code patterns for language constructs within the set of code completions, e.g., for loops.                                                                                                          |
| CXCodeComplete\\_IncludeBriefComments         | Whether to include brief documentation within the set of code completions returned.                                                                                                                                    |
| CXCodeComplete\\_SkipPreamble                 | Whether to speed up completion by omitting top- or namespace-level entities defined in the preamble. There's no guarantee any particular entity is omitted. This may be useful if the headers are indexed externally.  |
| CXCodeComplete\\_IncludeCompletionsWithFixIts | Whether to include completions with small fix-its, e.g. change '.' to '->' on member access, etc.                                                                                                                      |
"""
@cenum CXCodeComplete_Flags::UInt32 begin
    CXCodeComplete_IncludeMacros = 1
    CXCodeComplete_IncludeCodePatterns = 2
    CXCodeComplete_IncludeBriefComments = 4
    CXCodeComplete_SkipPreamble = 8
    CXCodeComplete_IncludeCompletionsWithFixIts = 16
end

"""
    CXCompletionContext

Bits that represent the context under which completion is occurring.

The enumerators in this enumeration may be bitwise-OR'd together if multiple contexts are occurring simultaneously.

| Enumerator                                | Note                                                                                                                                     |
| :---------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------- |
| CXCompletionContext\\_Unexposed           | The context for completions is unexposed, as only Clang results should be included. (This is equivalent to having no context bits set.)  |
| CXCompletionContext\\_AnyType             | Completions for any possible type should be included in the results.                                                                     |
| CXCompletionContext\\_AnyValue            | Completions for any possible value (variables, function calls, etc.) should be included in the results.                                  |
| CXCompletionContext\\_ObjCObjectValue     | Completions for values that resolve to an Objective-C object should be included in the results.                                          |
| CXCompletionContext\\_ObjCSelectorValue   | Completions for values that resolve to an Objective-C selector should be included in the results.                                        |
| CXCompletionContext\\_CXXClassTypeValue   | Completions for values that resolve to a C++ class type should be included in the results.                                               |
| CXCompletionContext\\_DotMemberAccess     | Completions for fields of the member being accessed using the dot operator should be included in the results.                            |
| CXCompletionContext\\_ArrowMemberAccess   | Completions for fields of the member being accessed using the arrow operator should be included in the results.                          |
| CXCompletionContext\\_ObjCPropertyAccess  | Completions for properties of the Objective-C object being accessed using the dot operator should be included in the results.            |
| CXCompletionContext\\_EnumTag             | Completions for enum tags should be included in the results.                                                                             |
| CXCompletionContext\\_UnionTag            | Completions for union tags should be included in the results.                                                                            |
| CXCompletionContext\\_StructTag           | Completions for struct tags should be included in the results.                                                                           |
| CXCompletionContext\\_ClassTag            | Completions for C++ class names should be included in the results.                                                                       |
| CXCompletionContext\\_Namespace           | Completions for C++ namespaces and namespace aliases should be included in the results.                                                  |
| CXCompletionContext\\_NestedNameSpecifier | Completions for C++ nested name specifiers should be included in the results.                                                            |
| CXCompletionContext\\_ObjCInterface       | Completions for Objective-C interfaces (classes) should be included in the results.                                                      |
| CXCompletionContext\\_ObjCProtocol        | Completions for Objective-C protocols should be included in the results.                                                                 |
| CXCompletionContext\\_ObjCCategory        | Completions for Objective-C categories should be included in the results.                                                                |
| CXCompletionContext\\_ObjCInstanceMessage | Completions for Objective-C instance messages should be included in the results.                                                         |
| CXCompletionContext\\_ObjCClassMessage    | Completions for Objective-C class messages should be included in the results.                                                            |
| CXCompletionContext\\_ObjCSelectorName    | Completions for Objective-C selector names should be included in the results.                                                            |
| CXCompletionContext\\_MacroName           | Completions for preprocessor macro names should be included in the results.                                                              |
| CXCompletionContext\\_NaturalLanguage     | Natural language completions should be included in the results.                                                                          |
| CXCompletionContext\\_IncludedFile        | #include file completions should be included in the results.                                                                             |
| CXCompletionContext\\_Unknown             | The current context is unknown, so set all contexts.                                                                                     |
"""
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
    @ccall libclang.clang_defaultCodeCompleteOptions()::Cint
end

function clang_sortCodeCompletionResults(Results, NumResults)
    @ccall libclang.clang_sortCodeCompletionResults(Results::Ptr{CXCompletionResult}, NumResults::Cuint)::Cint
end

function clang_disposeCodeCompleteResults(Results)
    @ccall libclang.clang_disposeCodeCompleteResults(Results::Ptr{CXCodeCompleteResults})::Cint
end

function clang_codeCompleteGetNumDiagnostics(Results)
    @ccall libclang.clang_codeCompleteGetNumDiagnostics(Results::Ptr{CXCodeCompleteResults})::Cint
end

function clang_codeCompleteGetContexts(Results)
    @ccall libclang.clang_codeCompleteGetContexts(Results::Ptr{CXCodeCompleteResults})::Cint
end

function clang_codeCompleteGetContainerKind(Results, IsIncomplete)
    @ccall libclang.clang_codeCompleteGetContainerKind(Results::Ptr{CXCodeCompleteResults}, IsIncomplete::Ptr{Cuint})::Cint
end

function clang_toggleCrashRecovery(isEnabled)
    @ccall libclang.clang_toggleCrashRecovery(isEnabled::Cuint)::Cint
end

# typedef void ( * CXInclusionVisitor ) ( CXFile included_file , CXSourceLocation * inclusion_stack , unsigned include_len , CXClientData client_data )
"""
Visitor invoked for each file in a translation unit (used with [`clang_getInclusions`](@ref)()).

This visitor function will be invoked by [`clang_getInclusions`](@ref)() for each file included (either at the top-level or by #include directives) within a translation unit. The first argument is the file being included, and the second and third arguments provide the inclusion stack. The array is sorted in order of immediate inclusion. For example, the first element refers to the location that included 'included\\_file'.
"""
const CXInclusionVisitor = Ptr{Cvoid}

function clang_getInclusions(tu, visitor, client_data)
    @ccall libclang.clang_getInclusions(tu::CXTranslationUnit, visitor::CXInclusionVisitor, client_data::CXClientData)::Cint
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

"""
Evaluation result of a cursor
"""
const CXEvalResult = Ptr{Cvoid}

function clang_EvalResult_getAsInt(E)
    @ccall libclang.clang_EvalResult_getAsInt(E::CXEvalResult)::Cint
end

function clang_EvalResult_getAsLongLong(E)
    @ccall libclang.clang_EvalResult_getAsLongLong(E::CXEvalResult)::Cint
end

function clang_EvalResult_isUnsignedInt(E)
    @ccall libclang.clang_EvalResult_isUnsignedInt(E::CXEvalResult)::Cint
end

function clang_EvalResult_getAsUnsigned(E)
    @ccall libclang.clang_EvalResult_getAsUnsigned(E::CXEvalResult)::Cint
end

function clang_EvalResult_getAsDouble(E)
    @ccall libclang.clang_EvalResult_getAsDouble(E::CXEvalResult)::Cint
end

function clang_EvalResult_getAsStr(E)
    @ccall libclang.clang_EvalResult_getAsStr(E::CXEvalResult)::Ptr{Cint}
end

function clang_EvalResult_dispose(E)
    @ccall libclang.clang_EvalResult_dispose(E::CXEvalResult)::Cint
end

"""
A remapping of original source files and their translated files.
"""
const CXRemapping = Ptr{Cvoid}

function clang_remap_getNumFiles(arg1)
    @ccall libclang.clang_remap_getNumFiles(arg1::CXRemapping)::Cint
end

function clang_remap_getFilenames(arg1, index, original, transformed)
    @ccall libclang.clang_remap_getFilenames(arg1::CXRemapping, index::Cuint, original::Ptr{Cint}, transformed::Ptr{Cint})::Cint
end

function clang_remap_dispose(arg1)
    @ccall libclang.clang_remap_dispose(arg1::CXRemapping)::Cint
end

"""
    CXVisitorResult

` CINDEX_HIGH Higher level API functions`

@{
"""
@cenum CXVisitorResult::UInt32 begin
    CXVisit_Break = 0
    CXVisit_Continue = 1
end

struct CXCursorAndRangeVisitor
    context::Ptr{Cvoid}
    visit::Ptr{Cvoid}
end

"""
    CXResult

| Enumerator            | Note                                                                          |
| :-------------------- | :---------------------------------------------------------------------------- |
| CXResult\\_Success    | Function returned successfully.                                               |
| CXResult\\_Invalid    | One of the parameters was invalid for the function.                           |
| CXResult\\_VisitBreak | The function was terminated by a callback (e.g. it returned CXVisit\\_Break)  |
"""
@cenum CXResult::UInt32 begin
    CXResult_Success = 0
    CXResult_Invalid = 1
    CXResult_VisitBreak = 2
end

"""
The client's data object that is associated with a [`CXFile`](@ref).
"""
const CXIdxClientFile = Ptr{Cvoid}

"""
The client's data object that is associated with a semantic entity.
"""
const CXIdxClientEntity = Ptr{Cvoid}

"""
The client's data object that is associated with a semantic container of entities.
"""
const CXIdxClientContainer = Ptr{Cvoid}

"""
The client's data object that is associated with an AST file (PCH or module).
"""
const CXIdxClientASTFile = Ptr{Cvoid}

"""
    CXIdxLoc

Source location passed to index callbacks.
"""
struct CXIdxLoc
    ptr_data::NTuple{2, Ptr{Cvoid}}
    int_data::Cuint
end

"""
    CXIdxIncludedFileInfo

Data for ppIncludedFile callback.

| Field          | Note                                                                      |
| :------------- | :------------------------------------------------------------------------ |
| hashLoc        | Location of '#' in the #include/#import directive.                        |
| filename       | Filename as written in the #include/#import directive.                    |
| file           | The actual file that the #include/#import directive resolved to.          |
| isModuleImport | Non-zero if the directive was automatically turned into a module import.  |
"""
struct CXIdxIncludedFileInfo
    hashLoc::CXIdxLoc
    filename::Cstring
    file::CXFile
    isImport::Cint
    isAngled::Cint
    isModuleImport::Cint
end

"""
    CXIdxImportedASTFileInfo

Data for [`IndexerCallbacks`](@ref)#importedASTFile.

| Field      | Note                                                                                                            |
| :--------- | :-------------------------------------------------------------------------------------------------------------- |
| file       | Top level AST file containing the imported PCH, module or submodule.                                            |
| module     | The imported module or NULL if the AST file is a PCH.                                                           |
| loc        | Location where the file is imported. Applicable only for modules.                                               |
| isImplicit | Non-zero if an inclusion directive was automatically turned into a module import. Applicable only for modules.  |
"""
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

"""
    CXIdxEntityCXXTemplateKind

Extra C++ template information for an entity. This can apply to: CXIdxEntity\\_Function CXIdxEntity\\_CXXClass CXIdxEntity\\_CXXStaticMethod CXIdxEntity\\_CXXInstanceMethod CXIdxEntity\\_CXXConstructor CXIdxEntity\\_CXXConversionFunction CXIdxEntity\\_CXXTypeAlias
"""
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

"""
    CXIdxDeclInfo

| Field            | Note                                                                                                                                 |
| :--------------- | :----------------------------------------------------------------------------------------------------------------------------------- |
| lexicalContainer | Generally same as #semanticContainer but can be different in cases like out-of-line C++ member functions.                            |
| isImplicit       | Whether the declaration exists in code or was created implicitly by the compiler, e.g. implicit Objective-C methods for properties.  |
"""
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

"""
    CXIdxEntityRefKind

Data for [`IndexerCallbacks`](@ref)#indexEntityReference.

This may be deprecated in a future version as this duplicates the `CXSymbolRole_Implicit` bit in [`CXSymbolRole`](@ref).

| Enumerator                | Note                                                                                  |
| :------------------------ | :------------------------------------------------------------------------------------ |
| CXIdxEntityRef\\_Direct   | The entity is referenced directly in user's code.                                     |
| CXIdxEntityRef\\_Implicit | An implicit reference, e.g. a reference of an Objective-C method via the dot syntax.  |
"""
@cenum CXIdxEntityRefKind::UInt32 begin
    CXIdxEntityRef_Direct = 1
    CXIdxEntityRef_Implicit = 2
end

"""
    CXSymbolRole

Roles that are attributed to symbol occurrences.

Internal: this currently mirrors low 9 bits of clang::index::SymbolRole with higher bits zeroed. These high bits may be exposed in the future.
"""
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

"""
    CXIdxEntityRefInfo

Data for [`IndexerCallbacks`](@ref)#indexEntityReference.

| Field            | Note                                                                                                                                                                                                                                               |
| :--------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| cursor           | Reference cursor.                                                                                                                                                                                                                                  |
| referencedEntity | The entity that gets referenced.                                                                                                                                                                                                                   |
| parentEntity     | Immediate "parent" of the reference. For example:  ```c++  Foo *var; ```  The parent of reference of type 'Foo' is the variable 'var'. For references inside statement bodies of functions/methods, the parentEntity will be the function/method.  |
| container        | Lexical container context of the reference.                                                                                                                                                                                                        |
| role             | Sets of symbol roles of the reference.                                                                                                                                                                                                             |
"""
struct CXIdxEntityRefInfo
    kind::CXIdxEntityRefKind
    cursor::CXCursor
    loc::CXIdxLoc
    referencedEntity::Ptr{CXIdxEntityInfo}
    parentEntity::Ptr{CXIdxEntityInfo}
    container::Ptr{CXIdxContainerInfo}
    role::CXSymbolRole
end

"""
    IndexerCallbacks

A group of callbacks used by #[`clang_indexSourceFile`](@ref) and #[`clang_indexTranslationUnit`](@ref).

| Field                  | Note                                                                                                                                                                                                                                                                                            |
| :--------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| abortQuery             | Called periodically to check whether indexing should be aborted. Should return 0 to continue, and non-zero to abort.                                                                                                                                                                            |
| diagnostic             | Called at the end of indexing; passes the complete diagnostic set.                                                                                                                                                                                                                              |
| ppIncludedFile         | Called when a file gets #included/#imported.                                                                                                                                                                                                                                                    |
| importedASTFile        | Called when a AST file (PCH or module) gets imported.  AST files will not get indexed (there will not be callbacks to index all the entities in an AST file). The recommended action is that, if the AST file is not already indexed, to initiate a new indexing job specific to the AST file.  |
| startedTranslationUnit | Called at the beginning of indexing a translation unit.                                                                                                                                                                                                                                         |
| indexEntityReference   | Called to index a reference of an entity.                                                                                                                                                                                                                                                       |
"""
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

function clang_index_setClientContainer(arg1, arg2)
    @ccall libclang.clang_index_setClientContainer(arg1::Ptr{CXIdxContainerInfo}, arg2::CXIdxClientContainer)::Cint
end

function clang_index_setClientEntity(arg1, arg2)
    @ccall libclang.clang_index_setClientEntity(arg1::Ptr{CXIdxEntityInfo}, arg2::CXIdxClientEntity)::Cint
end

"""
An indexing action/session, to be applied to one or multiple translation units.
"""
const CXIndexAction = Ptr{Cvoid}

function clang_IndexAction_dispose(arg1)
    @ccall libclang.clang_IndexAction_dispose(arg1::CXIndexAction)::Cint
end

"""
    CXIndexOptFlags

| Enumerator                                       | Note                                                                                                                                                                                                            |
| :----------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CXIndexOpt\\_None                                | Used to indicate that no special indexing options are needed.                                                                                                                                                   |
| CXIndexOpt\\_SuppressRedundantRefs               | Used to indicate that [`IndexerCallbacks`](@ref)#indexEntityReference should be invoked for only one reference of an entity per source file that does not also include a declaration/definition of the entity.  |
| CXIndexOpt\\_IndexFunctionLocalSymbols           | Function-local symbols should be indexed. If this is not set function-local symbols will be ignored.                                                                                                            |
| CXIndexOpt\\_IndexImplicitTemplateInstantiations | Implicit function/class template instantiations should be indexed. If this is not set, implicit instantiations will be ignored.                                                                                 |
| CXIndexOpt\\_SuppressWarnings                    | Suppress all compiler warnings when parsing for indexing.                                                                                                                                                       |
| CXIndexOpt\\_SkipParsedBodiesInSession           | Skip a function/method body that was already parsed during an indexing session associated with a [`CXIndexAction`](@ref) object. Bodies in system headers are always skipped.                                   |
"""
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
    @ccall libclang.clang_indexLoc_getFileLocation(loc::CXIdxLoc, indexFile::Ptr{CXIdxClientFile}, file::Ptr{CXFile}, line::Ptr{Cuint}, column::Ptr{Cuint}, offset::Ptr{Cuint})::Cint
end

# typedef enum CXVisitorResult ( * CXFieldVisitor ) ( CXCursor C , CXClientData client_data )
"""
Visitor invoked for each field found by a traversal.

This visitor function will be invoked for each field found by [`clang_Type_visitFields`](@ref). Its first argument is the cursor being visited, its second argument is the client data provided to [`clang_Type_visitFields`](@ref).

The visitor should return one of the [`CXVisitorResult`](@ref) values to direct [`clang_Type_visitFields`](@ref).
"""
const CXFieldVisitor = Ptr{Cvoid}

function clang_Type_visitFields(T, visitor, client_data)
    @ccall libclang.clang_Type_visitFields(T::CXType, visitor::CXFieldVisitor, client_data::CXClientData)::Cint
end

struct CXStringSet
    Strings::Ptr{Cint}
    Count::Cuint
end

function clang_getCString(string)
    @ccall libclang.clang_getCString(string::Cint)::Ptr{Cint}
end

function clang_disposeString(string)
    @ccall libclang.clang_disposeString(string::Cint)::Cint
end

function clang_disposeStringSet(set)
    @ccall libclang.clang_disposeStringSet(set::Ptr{CXStringSet})::Cint
end

const CINDEX_VERSION_MAJOR = 0

const CINDEX_VERSION_MINOR = 62

CINDEX_VERSION_ENCODE(major, minor) = major * 10000 + minor * 1

# exports
const PREFIXES = ["CX", "clang_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

end # module
