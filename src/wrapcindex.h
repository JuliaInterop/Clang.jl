void  wci_getCursorType(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXType rx = clang_getCursorType(l1);
  wci_save_CXType(rx,a2);
}
int wci_getCursorKind(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_getCursorKind(l1);
}
int wci_isPODType(char* a1) {
  CXType l1 = wci_get_CXType(a1);
  return clang_isPODType(l1);
}
void  wci_getTypeKindSpelling(CXTypeKind a1,char* a2) {
  CXString rx = clang_getTypeKindSpelling(a1);
  wci_save_CXString(rx,a2);
}
unsigned int wci_CXXMethod_isStatic(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_CXXMethod_isStatic(l1);
}
void  wci_Cursor_getArgument(char* a1,int a2,char* a3) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXCursor rx = clang_Cursor_getArgument(l1,a2);
  wci_save_CXCursor(rx,a3);
}
void  wci_getTypedefDeclUnderlyingType(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXType rx = clang_getTypedefDeclUnderlyingType(l1);
  wci_save_CXType(rx,a2);
}
void  wci_getCursorLexicalParent(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXCursor rx = clang_getCursorLexicalParent(l1);
  wci_save_CXCursor(rx,a2);
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
unsigned int wci_getTemplateCursorKind(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_getTemplateCursorKind(l1);
}
void  wci_getSpecializedCursorTemplate(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXCursor rx = clang_getSpecializedCursorTemplate(l1);
  wci_save_CXCursor(rx,a2);
}
void  wci_getResultType(char* a1,char* a2) {
  CXType l1 = wci_get_CXType(a1);
  CXType rx = clang_getResultType(l1);
  wci_save_CXType(rx,a2);
}
void  wci_getCursorResultType(char* a1,char* a2) {
  CXCursor l1 = wci_get_CXCursor(a1);
  CXType rx = clang_getCursorResultType(l1);
  wci_save_CXType(rx,a2);
}
void  wci_getTypeDeclaration(char* a1,char* a2) {
  CXType l1 = wci_get_CXType(a1);
  CXCursor rx = clang_getTypeDeclaration(l1);
  wci_save_CXCursor(rx,a2);
}
int wci_Cursor_isNull(char* a1) {
  CXCursor l1 = wci_get_CXCursor(a1);
  return clang_Cursor_isNull(l1);
}
void  wci_getPointeeType(char* a1,char* a2) {
  CXType l1 = wci_get_CXType(a1);
  CXType rx = clang_getPointeeType(l1);
  wci_save_CXType(rx,a2);
}
