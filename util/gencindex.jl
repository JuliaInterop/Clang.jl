jl_bfr = memio()
c_bfr = memio()

abstract StructArg
  abstract CXUnsavedFile <: StructArg
  abstract CXSourceLocation <: StructArg
  abstract CXSourceRange <: StructArg
  abstract CXCursor <: StructArg
  abstract CXType <: StructArg
  abstract CXToken <: StructArg
  abstract CXString <: StructArg

abstract EnumArg
  abstract CXTypeKind <: EnumArg
  abstract CXCursorKind <: EnumArg

abstract PointerArg
  abstract CXTranslationUnit <: PointerArg
  abstract CXFile <: PointerArg

c_types = {
  Int32 => "int",
  Uint32 => "unsigned int",
  Int64 => "long long",
  Uint64 => "unsigned long long",
  CXUnsavedFile => "char*",
  CXSourceLocation => "char*",
  CXSourceRange => "char*",
  CXCursor => "char*",
  CXType => "char*",
  CXToken => "char*",
  CXString => "char*",
  CXFile => "char*",
  Void => "void",
  CXTypeKind => "CXTypeKind",
  CXCursorKind => "CXCursorKind",
  CXTranslationUnit => "CXTranslationUnit"
  }

symbols = {}

is_struct(x) = (super(x) == StructArg ? true : false)
is_enum(x) = (super(x) == EnumArg ? true : false)

type Arg
  cname::String
  ctype::String
end

function flatten(f...)
  ret = {}
  upret(x) = push(ret, x)
  flt(k) = (typeof(k) == Array{Any,1}) ? (for x in k upret(x) end) : upret(k)
  map(flt, f)
  return ret
end

function to_c(io::IOStream, rtype, fname, args)
  c_ret = is_struct(rtype) ? "void " : c_types[rtype]
  c_args = map(x->ref(c_types,x), is_struct(rtype) ? flatten(args,{rtype}) : args )
  
  named_args = { Arg("a$i", a) for (i,a) in enumerate(c_args) }
  declargs = join( [x.ctype*" "*x.cname*"," for x in named_args])[1:end-1]
  
  println(io, "$c_ret wci_$fname($declargs) {")

  cl_args = {}
  for (i,a) in enumerate(args)
    if is_struct(a)
      println(io, "  $a l$i = wci_get_$a(a$i);")
      push(cl_args, "l$i")
    else
      push(cl_args, "a$i")
    end
  end
  cl_fargs = join( ["$a," for a in cl_args])[1:end-1]
  
  if is_struct(rtype)
    println(io, "  $rtype rx = clang_$fname($cl_fargs);")
    println(io, "  wci_save_$rtype(rx,a", string(length(args)+1), ");")
  else
    println(io, "  return clang_$fname($cl_fargs);")
  end
  println(io, "}")
end

function to_jl(io::IOStream, rtype, fname, args)
  push(symbols, "wci_$fname")
  arg_ids = ["a"*string(i) for i=1:length(args)]
  f_args = join([string(arg_ids[i])*"::"string(args[i])*"," for i in 1:length(args)])

  println(io, "function $fname($f_args)")
  f_rtype = rtype
  ret_data = ""
  ret_ptr = ""
  if( is_struct(rtype) )
    println(io, "  c = $rtype()")
    ret_data = "c.data,"
    ret_ptr = "Ptr{Void},"
    f_rtype = "Void"
  end
  cc_atype(x) = (
    if (is_struct(x)) return "Ptr{Void}"
    else return x end)
  cc_rtype(x,y) = (
    if (is_struct(x)) return "$y.data"
    else return y end)
  ccall_args1 = join([string(i)*"," for i in map(cc_atype, args)])
  ccall_args2 = join([i*"," for i in map(cc_rtype, args, arg_ids)])
  println(io, "  ccall( (:wci_$fname, libwci), $f_rtype, ($ccall_args1$ret_ptr), $ccall_args2 $ret_data)")
  if(rtype == CXString)
    println(io, "  return get_string(c)")
  elseif ( is_struct(rtype) )
    println(io, "  return c")
  end
  println(io, "end")
end
to_jl(rtype, fname, args) = to_jl(stdout_stream, rtype, fname, args)

function write_output()
  flush(jl_bfr)
  flush(c_bfr)
  seek(jl_bfr,0)
  seek(c_bfr,0)
  
  # Write Julia wrapper functions
  f_base = open("../src/cindex_base.jl", "w")
  
  println(f_base, "libwci = \"./libwrapcindex.so\"")
  for line in EachLine(jl_bfr)
    print(f_base, line)
  end

  # Write C wrapper functions
  f_hdr = open("../src/wrapcindex.h", "w")
  for line in EachLine(c_bfr)
    print(f_hdr, line)
  end

  close(f_hdr)
  close(f_base)
end

macro cx(rtype, fname, args)
  r,f,a = eval(rtype),string(fname),eval(args)
  to_c(c_bfr, r, f, a) 
  to_jl(jl_bfr, r,f,a)
end

# Four spaces: probably won't wrap.
# Two  spaces: might wrap
    #287 Pointer{"Char_S"} clang_getCString(CXString)
    #288 Void clang_disposeString(CXString)
    #289 Typedef{"Pointer CXIndex"} clang_createIndex(int, int)
    #290 Void clang_disposeIndex(CXIndex)
    #293 Void clang_CXIndex_setGlobalOptions(CXIndex, unsigned int)
    #294 UInt clang_CXIndex_getGlobalOptions(CXIndex)

#296 Typedef{"Record CXString"} clang_getFileName(CXFile)
@cx CXString getFileName {CXFile}

    #297 Typedef{"Typedef time_t"} clang_getFileTime(CXFile)

#TODO: enable
  #298 UInt clang_isFileMultipleIncludeGuarded(CXTranslationUnit, CXFile)
  #@cx Uint32 isFileMultipleIncludeGuarded {CXTranslationUnit, CXFile}
  
    #299 Typedef{"Pointer CXFile"} clang_getFile(CXTranslationUnit, const char *)

#304 Typedef{"Record CXSourceLocation"} clang_getNullLocation()
@cx CXSourceLocation getNullLocation {}
#305 UInt clang_equalLocations(CXSourceLocation, CXSourceLocation)
@cx Uint32 equalLocations {CXSourceLocation, CXSourceLocation}
  
    #306 Typedef{"Record CXSourceLocation"} clang_getLocation(CXTranslationUnit, CXFile, unsigned int, unsigned int)
    #307 Typedef{"Record CXSourceLocation"} clang_getLocationForOffset(CXTranslationUnit, CXFile, unsigned int)

#308 Typedef{"Record CXSourceRange"} clang_getNullRange()
@cx CXSourceRange getNullRange {}
#309 Typedef{"Record CXSourceRange"} clang_getRange(CXSourceLocation, CXSourceLocation)
@cx CXSourceRange getRange {CXSourceLocation, CXSourceLocation}
#310 UInt clang_equalRanges(CXSourceRange, CXSourceRange)
@cx Uint32 equalRanges {CXSourceRange, CXSourceRange}
#311 Int clang_Range_isNull(CXSourceRange)
@cx Int32 Range_isNull {CXSourceRange}

    #312 Void clang_getExpansionLocation(CXSourceLocation, CXFile *, unsigned int *, unsigned int *, unsigned int *)
    #313 Void clang_getPresumedLocation(CXSourceLocation, CXString *, unsigned int *, unsigned int *)
    #314 Void clang_getInstantiationLocation(CXSourceLocation, CXFile *, unsigned int *, unsigned int *, unsigned int *)
    #315 Void clang_getSpellingLocation(CXSourceLocation, CXFile *, unsigned int *, unsigned int *, unsigned int *)

    #316 Typedef{"Record CXSourceLocation"} clang_getRangeStart(CXSourceRange)
    #317 Typedef{"Record CXSourceLocation"} clang_getRangeEnd(CXSourceRange)
    #321 UInt clang_getNumDiagnosticsInSet(CXDiagnosticSet)
    #322 Typedef{"Pointer CXDiagnostic"} clang_getDiagnosticInSet(CXDiagnosticSet, unsigned int)
    #324 Typedef{"Pointer CXDiagnosticSet"} clang_loadDiagnostics(const char *, enum CXLoadDiag_Error *, CXString *)
    #325 Void clang_disposeDiagnosticSet(CXDiagnosticSet)
    #326 Typedef{"Pointer CXDiagnosticSet"} clang_getChildDiagnostics(CXDiagnostic)
    #327 UInt clang_getNumDiagnostics(CXTranslationUnit)
    #328 Typedef{"Pointer CXDiagnostic"} clang_getDiagnostic(CXTranslationUnit, unsigned int)
    #329 Typedef{"Pointer CXDiagnosticSet"} clang_getDiagnosticSetFromTU(CXTranslationUnit)
    #330 Void clang_disposeDiagnostic(CXDiagnostic)
    #332 Typedef{"Record CXString"} clang_formatDiagnostic(CXDiagnostic, unsigned int)
    #333 UInt clang_defaultDiagnosticDisplayOptions()
    #334 Enum{"CXDiagnosticSeverity"} clang_getDiagnosticSeverity(CXDiagnostic)
    #335 Typedef{"Record CXSourceLocation"} clang_getDiagnosticLocation(CXDiagnostic)
    #336 Typedef{"Record CXString"} clang_getDiagnosticSpelling(CXDiagnostic)
    #337 Typedef{"Record CXString"} clang_getDiagnosticOption(CXDiagnostic, CXString *)
    #338 UInt clang_getDiagnosticCategory(CXDiagnostic)
    #339 Typedef{"Record CXString"} clang_getDiagnosticCategoryName(unsigned int)
    #340 Typedef{"Record CXString"} clang_getDiagnosticCategoryText(CXDiagnostic)
    #341 UInt clang_getDiagnosticNumRanges(CXDiagnostic)
    #342 Typedef{"Record CXSourceRange"} clang_getDiagnosticRange(CXDiagnostic, unsigned int)
    #343 UInt clang_getDiagnosticNumFixIts(CXDiagnostic)
    #344 Typedef{"Record CXString"} clang_getDiagnosticFixIt(CXDiagnostic, unsigned int, CXSourceRange *)
    #345 Typedef{"Record CXString"} clang_getTranslationUnitSpelling(CXTranslationUnit)
    #346 Typedef{"Pointer CXTranslationUnit"} clang_createTranslationUnitFromSourceFile(CXIndex, const char *, int, const char *const *, unsigned int, struct CXUnsavedFile *)
# TODO: enable here, move all to jl  
  #347 Typedef{"Pointer CXTranslationUnit"} clang_createTranslationUnit(CXIndex, const char *)
  #349 UInt clang_defaultEditingTranslationUnitOptions()
  #350 Typedef{"Pointer CXTranslationUnit"} clang_parseTranslationUnit(CXIndex, const char *, const char *const *, int, struct CXUnsavedFile *, unsigned int, unsigned int)
  #352 UInt clang_defaultSaveOptions(CXTranslationUnit)
  #354 Int clang_saveTranslationUnit(CXTranslationUnit, const char *, unsigned int)
  #355 Void clang_disposeTranslationUnit(CXTranslationUnit)
  #357 UInt clang_defaultReparseOptions(CXTranslationUnit)
  #358 Int clang_reparseTranslationUnit(CXTranslationUnit, unsigned int, struct CXUnsavedFile *, unsigned int)
  #360 Pointer{"Char_S"} clang_getTUResourceUsageName(enum CXTUResourceUsageKind)
  #365 Typedef{"Record CXTUResourceUsage"} clang_getCXTUResourceUsage(CXTranslationUnit)
  #366 Void clang_disposeCXTUResourceUsage(CXTUResourceUsage)

#370 Typedef{"Record CXCursor"} clang_getNullCursor()
@cx CXCursor getNullCursor {}
#TODO: enable
  #371 Typedef{"Record CXCursor"} clang_getTranslationUnitCursor(CXTranslationUnit)
  #@cx CXCursor {Ptr{Void}}

#372 UInt clang_equalCursors(CXCursor, CXCursor)
@cx Uint32 equalCursors {CXCursor, CXCursor}
#373 Int clang_Cursor_isNull(CXCursor)
@cx Int32 Cursor_isNull {CXCursor}
#374 UInt clang_hashCursor(CXCursor)
@cx Uint32 hashCursor {CXCursor}
#375 Enum{"CXCursorKind"} clang_getCursorKind(CXCursor)
@cx Uint32 getCursorKind {CXCursor}
#376 UInt clang_isDeclaration(enum CXCursorKind)
@cx Uint32 isDeclaration {CXCursorKind}
#377 UInt clang_isReference(enum CXCursorKind)
@cx Uint32 isReference {CXCursorKind}
#378 UInt clang_isExpression(enum CXCursorKind)
#379 UInt clang_isStatement(enum CXCursorKind)
#380 UInt clang_isAttribute(enum CXCursorKind)
#381 UInt clang_isInvalid(enum CXCursorKind)
#382 UInt clang_isTranslationUnit(enum CXCursorKind)
#383 UInt clang_isPreprocessing(enum CXCursorKind)
#384 UInt clang_isUnexposed(enum CXCursorKind)
#386 Enum{"CXLinkageKind"} clang_getCursorLinkage(CXCursor)
#387 Enum{"CXAvailabilityKind"} clang_getCursorAvailability(CXCursor)
#389 Enum{"CXLanguageKind"} clang_getCursorLanguage(CXCursor)
#390 Typedef{"Pointer CXTranslationUnit"} clang_Cursor_getTranslationUnit(CXCursor)
#393 Typedef{"Pointer CXCursorSet"} clang_createCXCursorSet()
#394 Void clang_disposeCXCursorSet(CXCursorSet)
#395 UInt clang_CXCursorSet_contains(CXCursorSet, CXCursor)
#396 UInt clang_CXCursorSet_insert(CXCursorSet, CXCursor)
#397 Typedef{"Record CXCursor"} clang_getCursorSemanticParent(CXCursor)
#398 Typedef{"Record CXCursor"} clang_getCursorLexicalParent(CXCursor)
#399 Void clang_getOverriddenCursors(CXCursor, CXCursor **, unsigned int *)
#400 Void clang_disposeOverriddenCursors(CXCursor *)
#401 Typedef{"Pointer CXFile"} clang_getIncludedFile(CXCursor)
#402 Typedef{"Record CXCursor"} clang_getCursor(CXTranslationUnit, CXSourceLocation)
#403 Typedef{"Record CXSourceLocation"} clang_getCursorLocation(CXCursor)
#404 Typedef{"Record CXSourceRange"} clang_getCursorExtent(CXCursor)
#409 Typedef{"Record CXType"} clang_getCursorType(CXCursor)
#410 Typedef{"Record CXType"} clang_getTypedefDeclUnderlyingType(CXCursor)
@cx CXType getTypedefDeclUnderlyingType {CXCursor}
#411 Typedef{"Record CXType"} clang_getEnumDeclIntegerType(CXCursor)
#412 LongLong clang_getEnumConstantDeclValue(CXCursor)
@cx Int64 getEnumConstantDeclValue {CXCursor}
#413 ULongLong clang_getEnumConstantDeclUnsignedValue(CXCursor)
@cx Uint64 getEnumConstantDeclUnsignedValue {CXCursor}
#414 Int clang_Cursor_getNumArguments(CXCursor)
@cx Int32 Cursor_getNumArguments {CXCursor}
#415 Typedef{"Record CXCursor"} clang_Cursor_getArgument(CXCursor, unsigned int)
@cx CXCursor Cursor_getArgument {CXCursor, Int32}
#416 UInt clang_equalTypes(CXType, CXType)
@cx Uint32 equalTypes {CXType, CXType}
#417 Typedef{"Record CXType"} clang_getCanonicalType(CXType)
@cx CXType getCanonicalType {CXType}
#418 Uint32 clang_isConstQualifiedType(CXType)
@cx Uint32 isConstQualifiedType {CXType}
#419 UInt clang_isVolatileQualifiedType(CXType)
@cx Uint32 isVolatileQualifiedType {CXType}
#420 UInt clang_isRestrictQualifiedType(CXType)
@cx Uint32 isRestrictQualifiedType {CXType}
#421 Typedef{"Record CXType"} clang_getPointeeType(CXType)
@cx CXType getPointeeType {CXType}
#422 Typedef{"Record CXCursor"} clang_getTypeDeclaration(CXType)
@cx CXCursor getTypeDeclaration {CXType}
#423 Typedef{"Record CXString"} clang_getDeclObjCTypeEncoding(CXCursor)
@cx CXString getDeclObjCTypeEncoding {CXCursor}
#424 Typedef{"Record CXString"} clang_getTypeKindSpelling(enum CXTypeKind)
@cx CXString getTypeKindSpelling {CXTypeKind}
#425 Enum{"CXCallingConv"} clang_getFunctionTypeCallingConv(CXType)
@cx Int32 getFunctionTypeCallingConv {CXType}
#426 Typedef{"Record CXType"} clang_getResultType(CXType)
@cx CXType getResultType {CXType}
#427 Int clang_getNumArgTypes(CXType)
@cx Int32 getNumArgTypes {CXType}
#428 Typedef{"Record CXType"} clang_getArgType(CXType, unsigned int)
@cx CXType getArgType {CXType, Uint32}
#429 UInt clang_isFunctionTypeVariadic(CXType)
@cx Uint32 isFunctionTypeVariadic {CXType}
#430 Typedef{"Record CXType"} clang_getCursorResultType(CXCursor)
@cx CXType getCursorResultType {CXCursor}
#431 UInt clang_isPODType(CXType)
@cx Uint32 isPODType {CXType}
#432 Typedef{"Record CXType"} clang_getElementType(CXType)
@cx CXType getElementType {CXType}
#433 LongLong clang_getNumElements(CXType)
@cx Int64 getNumElements {CXType}
#434 Typedef{"Record CXType"} clang_getArrayElementType(CXType)
@cx CXType getArrayElementType {CXType}
#435 LongLong clang_getArraySize(CXType)
@cx Int64 getArraySize {CXType}
#436 UInt clang_isVirtualBase(CXCursor)
@cx Uint32 isVirtualBase {CXCursor}
#438 Enum{"CX_CXXAccessSpecifier"} clang_getCXXAccessSpecifier(CXCursor)
@cx Int getCXXAccessSpecifier {CXCursor}
#439 UInt clang_getNumOverloadedDecls(CXCursor)
@cx Uint32 getNumOverloadedDecls {CXCursor}
#440 Typedef{"Record CXCursor"} clang_getOverloadedDecl(CXCursor, unsigned int)
@cx CXCursor getOverloadedDecl {CXCursor, Uint32}
    # what is this?
    #441 Typedef{"Record CXType"} clang_getIBOutletCollectionType(CXCursor)
    # Do not wrap.
    #444 UInt clang_visitChildren(CXCursor, CXCursorVisitor, CXClientData)
#445 Typedef{"Record CXString"} clang_getCursorUSR(CXCursor)
@cx CXString getCursorUSR {CXCursor}
    
    #446 Typedef{"Record CXString"} clang_constructUSR_ObjCClass(const char *)
    #447 Typedef{"Record CXString"} clang_constructUSR_ObjCCategory(const char *, const char *)
    #448 Typedef{"Record CXString"} clang_constructUSR_ObjCProtocol(const char *)
    #449 Typedef{"Record CXString"} clang_constructUSR_ObjCIvar(const char *, CXString)
    #450 Typedef{"Record CXString"} clang_constructUSR_ObjCMethod(const char *, unsigned int, CXString)
    #451 Typedef{"Record CXString"} clang_constructUSR_ObjCProperty(const char *, CXString)

#452 Typedef{"Record CXString"} clang_getCursorSpelling(CXCursor)
@cx CXString getCursorSpelling {CXCursor}
  # maybe
  #453 Typedef{"Record CXSourceRange"} clang_Cursor_getSpellingNameRange(CXCursor, unsigned int, unsigned int)
#454 Typedef{"Record CXString"} clang_getCursorDisplayName(CXCursor)
@cx CXString getCursorDisplayName {CXCursor}
#455 Typedef{"Record CXCursor"} clang_getCursorReferenced(CXCursor)
@cx CXCursor getCursorReferenced {CXCursor}
#456 Typedef{"Record CXCursor"} clang_getCursorDefinition(CXCursor)
@cx CXCursor getCursorDefinition {CXCursor}
#457 UInt clang_isCursorDefinition(CXCursor)
@cx Uint32 isCursorDefinition {CXCursor}
#458 Typedef{"Record CXCursor"} clang_getCanonicalCursor(CXCursor)
@cx CXCursor getCanonicalCursor {CXCursor}
    #459 Int clang_Cursor_getObjCSelectorIndex(CXCursor)
#460 UInt clang_CXXMethod_isStatic(CXCursor)
@cx Uint32 CXXMethod_isStatic {CXCursor}
#461 UInt clang_CXXMethod_isVirtual(CXCursor)
@cx Uint32 CXXMethod_isVirtual {CXCursor}
#462 Enum{"CXCursorKind"} clang_getTemplateCursorKind(CXCursor)
@cx Int32 getTemplateCursorKind {CXCursor}
#463 Typedef{"Record CXCursor"} clang_getSpecializedCursorTemplate(CXCursor)
@cx CXCursor getSpecializedCursorTemplate {CXCursor}

    #464 Typedef{"Record CXSourceRange"} clang_getCursorReferenceNameRange(CXCursor, unsigned int, unsigned int)
    # there is no way to get a CXToken..
    # also, cindex.py does not expose.
    #470 Typedef{"Enum CXTokenKind"} clang_getTokenKind(CXToken)
    @cx Int32 getTokenKind {CXToken}
    #471 Typedef{"Record CXString"} clang_getTokenSpelling(CXTranslationUnit, CXToken)
    @cx CXString getTokenSpelling {CXTranslationUnit, CXToken}
    
    #472 Typedef{"Record CXSourceLocation"} clang_getTokenLocation(CXTranslationUnit, CXToken)
    #473 Typedef{"Record CXSourceRange"} clang_getTokenExtent(CXTranslationUnit, CXToken)
    #474 Void clang_tokenize(CXTranslationUnit, CXSourceRange, CXToken **, unsigned int *)
    #475 Void clang_annotateTokens(CXTranslationUnit, CXToken *, unsigned int, CXCursor *)
    #476 Void clang_disposeTokens(CXTranslationUnit, CXToken *, unsigned int)

#477 Typedef{"Record CXString"} clang_getCursorKindSpelling(enum CXCursorKind)
@cx CXString getCursorKindSpelling {CXCursorKind}

    #478 Void clang_getDefinitionSpellingAndExtent(CXCursor, const char **, const char **, unsigned int *, unsigned int *, unsigned int *, unsigned int *)
  
  # these sound useful..
  #479 Void clang_enableStackTraces()
  #480 Void clang_executeOnThread(void (*)(void *), void *, unsigned int)

    # writing a C++ editor in Julia? let me be the first to salute you.
    #485 Enum{"CXCompletionChunkKind"} clang_getCompletionChunkKind(CXCompletionString, unsigned int)
    #486 Typedef{"Record CXString"} clang_getCompletionChunkText(CXCompletionString, unsigned int)
    #487 Typedef{"Pointer CXCompletionString"} clang_getCompletionChunkCompletionString(CXCompletionString, unsigned int)
    #488 UInt clang_getNumCompletionChunks(CXCompletionString)
    #489 UInt clang_getCompletionPriority(CXCompletionString)
    #490 Enum{"CXAvailabilityKind"} clang_getCompletionAvailability(CXCompletionString)
    #491 UInt clang_getCompletionNumAnnotations(CXCompletionString)
    #492 Typedef{"Record CXString"} clang_getCompletionAnnotation(CXCompletionString, unsigned int)
    #493 Typedef{"Record CXString"} clang_getCompletionParent(CXCompletionString, enum CXCursorKind *)
    #494 Typedef{"Pointer CXCompletionString"} clang_getCursorCompletionString(CXCursor)
    #499 UInt clang_defaultCodeCompleteOptions()
    #500 Pointer{"Typedef", "Record", "CXCodeCompleteResults"} clang_codeCompleteAt(CXTranslationUnit, const char *, unsigned int, unsigned int, struct CXUnsavedFile *, unsigned int, unsigned int)
    #501 Void clang_sortCodeCompletionResults(CXCompletionResult *, unsigned int)
    #502 Void clang_disposeCodeCompleteResults(CXCodeCompleteResults *)
    #503 UInt clang_codeCompleteGetNumDiagnostics(CXCodeCompleteResults *)
    #504 Typedef{"Pointer CXDiagnostic"} clang_codeCompleteGetDiagnostic(CXCodeCompleteResults *, unsigned int)
    #505 ULongLong clang_codeCompleteGetContexts(CXCodeCompleteResults *)
    #506 Enum{"CXCursorKind"} clang_codeCompleteGetContainerKind(CXCodeCompleteResults *, unsigned int *)
    #507 Typedef{"Record CXString"} clang_codeCompleteGetContainerUSR(CXCodeCompleteResults *)
    #508 Typedef{"Record CXString"} clang_codeCompleteGetObjCSelector(CXCodeCompleteResults *)

#509 Typedef{"Record CXString"} clang_getClangVersion()
@cx CXString getClangVersion {}
  
  # TODO: useful?
  #510 Void clang_toggleCrashRecovery(unsigned int)
  #512 Void clang_getInclusions(CXTranslationUnit, CXInclusionVisitor, CXClientData)

    #514 Typedef{"Pointer CXRemapping"} clang_getRemappings(const char *)
    #515 Typedef{"Pointer CXRemapping"} clang_getRemappingsFromFileList(const char **, unsigned int)
    #516 UInt clang_remap_getNumFiles(CXRemapping)
    #517 Void clang_remap_getFilenames(CXRemapping, unsigned int, CXString *, CXString *)
    #518 Void clang_remap_dispose(CXRemapping)
  
  # TODO: useful?
  #522 Void clang_findReferencesInFile(CXCursor, CXFile, CXCursorAndRangeVisitor)

    #575 Int clang_index_isEntityObjCContainerKind(CXIdxEntityKind)
    #576 Pointer{"Typedef", "Record", "CXIdxObjCContainerDeclInfo"} clang_index_getObjCContainerDeclInfo(const CXIdxDeclInfo *)
    #577 Pointer{"Typedef", "Record", "CXIdxObjCInterfaceDeclInfo"} clang_index_getObjCInterfaceDeclInfo(const CXIdxDeclInfo *)
    #578 Pointer{"Typedef", "Record", "CXIdxObjCCategoryDeclInfo"} clang_index_getObjCCategoryDeclInfo(const CXIdxDeclInfo *)
    #579 Pointer{"Typedef", "Record", "CXIdxObjCProtocolRefListInfo"} clang_index_getObjCProtocolRefListInfo(const CXIdxDeclInfo *)
    #580 Pointer{"Typedef", "Record", "CXIdxObjCPropertyDeclInfo"} clang_index_getObjCPropertyDeclInfo(const CXIdxDeclInfo *)
    #581 Pointer{"Typedef", "Record", "CXIdxIBOutletCollectionAttrInfo"} clang_index_getIBOutletCollectionAttrInfo(const CXIdxAttrInfo *)
    #582 Pointer{"Typedef", "Record", "CXIdxCXXClassDeclInfo"} clang_index_getCXXClassDeclInfo(const CXIdxDeclInfo *)
    #583 Typedef{"Pointer CXIdxClientContainer"} clang_index_getClientContainer(const CXIdxContainerInfo *)
    #584 Void clang_index_setClientContainer(const CXIdxContainerInfo *, CXIdxClientContainer)
    #585 Typedef{"Pointer CXIdxClientEntity"} clang_index_getClientEntity(const CXIdxEntityInfo *)
    #586 Void clang_index_setClientEntity(const CXIdxEntityInfo *, CXIdxClientEntity)
    #588 Typedef{"Pointer CXIndexAction"} clang_IndexAction_create(CXIndex)
    #589 Void clang_IndexAction_dispose(CXIndexAction)
    #592 Int clang_indexSourceFile(CXIndexAction, CXClientData, IndexerCallbacks *, unsigned int, unsigned int, const char *, const char *const *, int, struct CXUnsavedFile *, unsigned int, CXTranslationUnit *, unsigned int)
    #593 Int clang_indexTranslationUnit(CXIndexAction, CXClientData, IndexerCallbacks *, unsigned int, unsigned int, CXTranslationUnit)
    #594 Void clang_indexLoc_getFileLocation(CXIdxLoc, CXIdxClientFile *, CXFile *, unsigned int *, unsigned int *, unsigned int *)
    #595 Typedef{"Record CXSourceLocation"} clang_indexLoc_getCXSourceLocation(CXIdxLoc)

write_output()
