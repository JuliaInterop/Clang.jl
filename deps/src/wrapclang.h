void  wci_getFileName(char* a1,char* a2) {
  CXString rx = clang_getFileName(a1);
  wci_save_CXString(rx,a2);
}
void  wci_getNullLocation(char* a1) {
  CXSourceLocation rx = clang_getNullLocation();
  wci_save_CXSourceLocation(rx,a1);
}
unsigned int wci_equalLocations(char* a1,char* a2) {
  CXSourceLocation l1 = wci_get_CXSourceLocation(a1);
  CXSourceLocation l2 = wci_get_CXSourceLocation(a2);
  return clang_equalLocations(l1,l2);
}
void  wci_getNullRange(char* a1) {
  CXSourceRange rx = clang_getNullRange();
  wci_save_CXSourceRange(rx,a1);
}
void  wci_getRange(char* a1,char* a2,char* a3) {
  CXSourceLocation l1 = wci_get_CXSourceLocation(a1);
  CXSourceLocation l2 = wci_get_CXSourceLocation(a2);
  CXSourceRange rx = clang_getRange(l1,l2);
  wci_save_CXSourceRange(rx,a3);
}
unsigned int wci_equalRanges(char* a1,char* a2) {
  CXSourceRange l1 = wci_get_CXSourceRange(a1);
  CXSourceRange l2 = wci_get_CXSourceRange(a2);
  return clang_equalRanges(l1,l2);
}
int wci_Range_isNull(char* a1) {
  CXSourceRange l1 = wci_get_CXSourceRange(a1);
  return clang_Range_isNull(l1);
}
void  wci_getNullCursor(char* a1) {
  CXCursor rx = clang_getNullCursor();
  wci_save_CXCursor(rx,a1);
}
void  wci_getTranslationUnitCursor(CXTranslationUnit a1,char* a2) {
  CXCursor rx = clang_getTranslationUnitCursor(a1);
  wci_save_CXCursor(rx,a2);
}
unsigned int wci_equalCursors(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXCursor l2 = wci_get_CXCursor(a2);
  return clang_equalCursors(l1,l2);
}
int wci_Cursor_isNull(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_Cursor_isNull(l1);
}
unsigned int wci_hashCursor(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_hashCursor(l1);
}
unsigned int wci_getCursorKind(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_getCursorKind(l1);
}
unsigned int wci_isDeclaration(CXCursorKind a1) {
  return clang_isDeclaration(a1);
}
unsigned int wci_isReference(CXCursorKind a1) {
  return clang_isReference(a1);
}
CXLinkageKind wci_getCursorLinkage(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_getCursorLinkage(l1);
}
CXAvailabilityKind wci_getCursorAvailability(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_getCursorAvailability(l1);
}
CXLanguageKind wci_getCursorLanguage(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_getCursorLanguage(l1);
}
void  wci_getCursorSemanticParent(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXCursor rx = clang_getCursorSemanticParent(l1);
  wci_save_CXCursor(rx,a2);
}
void  wci_getCursorLexicalParent(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXCursor rx = clang_getCursorLexicalParent(l1);
  wci_save_CXCursor(rx,a2);
}
void  wci_getCursorType(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXType rx = clang_getCursorType(l1);
  wci_save_CXType(rx,a2);
}
void  wci_getTypedefDeclUnderlyingType(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXType rx = clang_getTypedefDeclUnderlyingType(l1);
  wci_save_CXType(rx,a2);
}
void  wci_getEnumDeclIntegerType(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXType rx = clang_getEnumDeclIntegerType(l1);
  wci_save_CXType(rx,a2);
}
long long wci_getEnumConstantDeclValue(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_getEnumConstantDeclValue(l1);
}
unsigned long long wci_getEnumConstantDeclUnsignedValue(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_getEnumConstantDeclUnsignedValue(l1);
}
int wci_Cursor_getNumArguments(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_Cursor_getNumArguments(l1);
}
void  wci_Cursor_getArgument(char* a1,int a2,char* a3) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXCursor rx = clang_Cursor_getArgument(l1,a2);
  wci_save_CXCursor(rx,a3);
}
unsigned int wci_equalTypes(char* a1,char* a2) {
  CXType l1 = wci_get_CXType(a1);
  CXType l2 = wci_get_CXType(a2);
  return clang_equalTypes(l1,l2);
}
void  wci_getCanonicalType(char* a1,char* a2) {
  CXType l1 = wci_get_CXType(a1);
  CXType rx = clang_getCanonicalType(l1);
  wci_save_CXType(rx,a2);
}
unsigned int wci_isConstQualifiedType(char* a1) {
  CXType l1 = wci_get_CXType(a1);
  return clang_isConstQualifiedType(l1);
}
unsigned int wci_isVolatileQualifiedType(char* a1) {
  CXType l1 = wci_get_CXType(a1);
  return clang_isVolatileQualifiedType(l1);
}
unsigned int wci_isRestrictQualifiedType(char* a1) {
  CXType l1 = wci_get_CXType(a1);
  return clang_isRestrictQualifiedType(l1);
}
void  wci_getPointeeType(char* a1,char* a2) {
  CXType l1 = wci_get_CXType(a1);
  CXType rx = clang_getPointeeType(l1);
  wci_save_CXType(rx,a2);
}
void  wci_getTypeDeclaration(char* a1,char* a2) {
  CXType l1 = wci_get_CXType(a1);
  CXCursor rx = clang_getTypeDeclaration(l1);
  wci_save_CXCursor(rx,a2);
}
void  wci_getDeclObjCTypeEncoding(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXString rx = clang_getDeclObjCTypeEncoding(l1);
  wci_save_CXString(rx,a2);
}
void  wci_getTypeKindSpelling(CXTypeKind a1,char* a2) {
  CXString rx = clang_getTypeKindSpelling(a1);
  wci_save_CXString(rx,a2);
}
int wci_getFunctionTypeCallingConv(char* a1) {
  CXType l1 = wci_get_CXType(a1);
  return clang_getFunctionTypeCallingConv(l1);
}
void  wci_getResultType(char* a1,char* a2) {
  CXType l1 = wci_get_CXType(a1);
  CXType rx = clang_getResultType(l1);
  wci_save_CXType(rx,a2);
}
int wci_getNumArgTypes(char* a1) {
  CXType l1 = wci_get_CXType(a1);
  return clang_getNumArgTypes(l1);
}
void  wci_getArgType(char* a1,unsigned int a2,char* a3) {
  CXType l1 = wci_get_CXType(a1);
  CXType rx = clang_getArgType(l1,a2);
  wci_save_CXType(rx,a3);
}
unsigned int wci_isFunctionTypeVariadic(char* a1) {
  CXType l1 = wci_get_CXType(a1);
  return clang_isFunctionTypeVariadic(l1);
}
void  wci_getCursorResultType(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXType rx = clang_getCursorResultType(l1);
  wci_save_CXType(rx,a2);
}
unsigned int wci_isPODType(char* a1) {
  CXType l1 = wci_get_CXType(a1);
  return clang_isPODType(l1);
}
void  wci_getElementType(char* a1,char* a2) {
  CXType l1 = wci_get_CXType(a1);
  CXType rx = clang_getElementType(l1);
  wci_save_CXType(rx,a2);
}
long long wci_getNumElements(char* a1) {
  CXType l1 = wci_get_CXType(a1);
  return clang_getNumElements(l1);
}
void  wci_getArrayElementType(char* a1,char* a2) {
  CXType l1 = wci_get_CXType(a1);
  CXType rx = clang_getArrayElementType(l1);
  wci_save_CXType(rx,a2);
}
long long wci_getArraySize(char* a1) {
  CXType l1 = wci_get_CXType(a1);
  return clang_getArraySize(l1);
}
unsigned int wci_isVirtualBase(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_isVirtualBase(l1);
}
long long wci_getCXXAccessSpecifier(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_getCXXAccessSpecifier(l1);
}
unsigned int wci_getNumOverloadedDecls(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_getNumOverloadedDecls(l1);
}
void  wci_getOverloadedDecl(char* a1,unsigned int a2,char* a3) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXCursor rx = clang_getOverloadedDecl(l1,a2);
  wci_save_CXCursor(rx,a3);
}
void  wci_getCursorUSR(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXString rx = clang_getCursorUSR(l1);
  wci_save_CXString(rx,a2);
}
void  wci_getCursorSpelling(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXString rx = clang_getCursorSpelling(l1);
  wci_save_CXString(rx,a2);
}
void  wci_getCursorDisplayName(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXString rx = clang_getCursorDisplayName(l1);
  wci_save_CXString(rx,a2);
}
void  wci_getCursorReferenced(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXCursor rx = clang_getCursorReferenced(l1);
  wci_save_CXCursor(rx,a2);
}
void  wci_getCursorDefinition(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXCursor rx = clang_getCursorDefinition(l1);
  wci_save_CXCursor(rx,a2);
}
unsigned int wci_isCursorDefinition(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_isCursorDefinition(l1);
}
void  wci_getCanonicalCursor(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXCursor rx = clang_getCanonicalCursor(l1);
  wci_save_CXCursor(rx,a2);
}
unsigned int wci_CXXMethod_isStatic(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_CXXMethod_isStatic(l1);
}
unsigned int wci_CXXMethod_isVirtual(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_CXXMethod_isVirtual(l1);
}
int wci_getTemplateCursorKind(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_getTemplateCursorKind(l1);
}
void  wci_getSpecializedCursorTemplate(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXCursor rx = clang_getSpecializedCursorTemplate(l1);
  wci_save_CXCursor(rx,a2);
}
int wci_getTokenKind(char* a1) {
  CXToken l1 = wci_get_CXToken(a1);
  return clang_getTokenKind(l1);
}
void  wci_getTokenSpelling(CXTranslationUnit a1,char* a2,char* a3) {
  CXToken l2 = wci_get_CXToken(a2);
  CXString rx = clang_getTokenSpelling(a1,l2);
  wci_save_CXString(rx,a3);
}
void  wci_getCursorKindSpelling(CXCursorKind a1,char* a2) {
  CXString rx = clang_getCursorKindSpelling(a1);
  wci_save_CXString(rx,a2);
}
void  wci_getClangVersion(char* a1) {
  CXString rx = clang_getClangVersion();
  wci_save_CXString(rx,a1);
}
void* wci_getIncludedFile(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXFile rx = clang_getIncludedFile(l1);
  return rx;
}
