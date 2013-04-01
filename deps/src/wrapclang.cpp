#include <cstring>
#include <vector>
#include <set>

extern "C" {
#include "clang-c/Index.h"
}

#define wci_st(rtype) \
  static inline void wci_save_##rtype(rtype i, char* o) \
    { memcpy(o, &i, sizeof(rtype)); } \
  static inline rtype wci_get_##rtype(char* b) \
    { rtype c; memcpy(&c, b, sizeof(rtype)); return c; } \
  extern "C" unsigned int wci_size_##rtype() { return sizeof(rtype); }

// Struct helpers: memcpy shenanigans due to no structs byval
wci_st(CXSourceLocation)
wci_st(CXSourceRange)
wci_st(CXTUResourceUsageEntry)
wci_st(CXTUResourceUsage)
wci_st(CXCursor)
wci_st(CXType)
wci_st(CXToken)
wci_st(CXString)

// Test code
#define __STDC_LIMIT_MACROS
#define __STDC_CONSTANT_MACROS
#include "clang/AST/ASTContext.h"
#include "clang/AST/Mangle.h"
#include "clang/AST/DeclCXX.h"
#include "clang/AST/VTableBuilder.h"
#include "clang/AST/Type.h"

#include "CXCursor.h"
#include <string>
#include <iostream>
using namespace clang;

//class llvm::raw_string_ostream;
#define WCI_CHECK_DECL(D) \
  if(!D) { printf("unable to get cursor Decl\n"); return -1; }

extern "C" {

int wci_getCXXMethodVTableIndex(char* cuin)
{
  CXCursor cu = wci_get_CXCursor(cuin);

  Decl* MD = cxcursor::getCursorDecl(cu);
  WCI_CHECK_DECL(MD);

  const CXXMethodDecl* CXXMethod;
  if ( !(CXXMethod = dyn_cast<CXXMethodDecl>(MD)) )
  {
//    printf("failed cast to CXXMethodDecl\n");
    return -1;
  }

  ASTContext &astctx = CXXMethod->getASTContext();
  // TODO: perf, is this cached?
  VTableContext ctx = VTableContext(astctx);

  // Clang dies at assert for constructor or destructor, see GlobalDecl.h:32-33
  if (isa<CXXConstructorDecl>(CXXMethod) || isa<CXXDestructorDecl>(CXXMethod))
    return -1;
  else
    return ctx.getMethodVTableIndex(CXXMethod);
}

int wci_getCXXMethodMangledName(char* cuin, char* outbuf)
{
  CXCursor cu = wci_get_CXCursor(cuin);
  Decl* MD = cxcursor::getCursorDecl(cu);
  WCI_CHECK_DECL(MD);

  const CXXMethodDecl* CXXMethod;
  if ( !(CXXMethod = dyn_cast<CXXMethodDecl>(MD)) )
  {
//    printf("failed cast to CXXMethodDecl\n");
    return -1;
  }

  ASTContext &astctx = CXXMethod->getASTContext();
  VTableContext ctx = VTableContext(astctx);

  std::string sbuf; 
  llvm::raw_string_ostream os(sbuf);
  
  MangleContext* mc = astctx.createMangleContext();
  if (mc->shouldMangleDeclName( dyn_cast<NamedDecl>(MD)) ) {
    mc->mangleName( dyn_cast<NamedDecl>(MD), os);
  }
  else
  {
    return 0;
  }
  os.flush();

  std::strcpy(outbuf, sbuf.c_str());
  return sbuf.size();
}

typedef int (*ClassParentCB)(char*, void*);
int wci_getCXXClassParents(char* cuin, ClassParentCB visit_cb, void* cbdata)
{
  CXCursor cu = wci_get_CXCursor(cuin);
  CXTranslationUnit TU = static_cast<CXTranslationUnit>(cu.data[2]);

  Decl* MD = cxcursor::getCursorDecl(cu);
  WCI_CHECK_DECL(MD);

  const CXXRecordDecl* CXXClass;
  if ( !(CXXClass = dyn_cast<CXXRecordDecl>(MD)) )
    return -1;

  for(CXXRecordDecl::base_class_const_iterator it = CXXClass->bases_begin();
      it != CXXClass->bases_end(); ++it)
  {
    const CXXBaseSpecifier &Base = *it;
    RecordDecl *BaseDecl;
    QualType T = Base.getType();
    const RecordType *RT = T->getAs<RecordType>();
    if (RT == NULL)
    {
      std::cerr << "Error: missing record type" << std::endl;
      return -1;
    } else {
      BaseDecl = RT->getDecl();
    } 
    
    CXCursor cuback = cxcursor::MakeCXCursor(BaseDecl, TU); // TODO: something safer
    char* cubackptr = (char*)malloc(sizeof(CXCursor));
    memcpy(cubackptr, &cuback, sizeof(CXCursor));
    
    
    std::cout << "calling callback with: " << clang_getCString(clang_getCursorDisplayName(cuback)) << std::endl;
    (visit_cb)(cubackptr, cbdata);
  }
  return 0;
}

} // extern C
#undef __STDC_LIMIT_MACROS
#undef __STDC_CONSTANT_MACROS


typedef std::vector<CXCursor> CursorList;
typedef std::set<CursorList*> allcl_t;
allcl_t allCursorLists;

// to traverse AST with cursor visitor
// TODO: replace this with a C container
CXChildVisitResult wci_visitCB(CXCursor cur, CXCursor par, CXClientData data)
{
  CursorList* cl = (CursorList*)data;
  cl->push_back(cur);
  return CXChildVisit_Continue;
}

extern "C" {
#include "wrapclang.h"

unsigned int wci_getChildren(char* cuin, CursorList* cl)
{
  CXCursor cu = wci_get_CXCursor(cuin);
  clang_visitChildren(cu, wci_visitCB, cl);
  return 0;
}

void wci_getCursorFile(char* cuin, char* cxsout)
{
  CXCursor cu = wci_get_CXCursor(cuin);
  CXSourceLocation loc = clang_getCursorLocation( cu );
  CXFile cxfile;
  clang_getExpansionLocation(loc, &cxfile, 0, 0, 0);
  wci_save_CXString(clang_getFileName(cxfile), cxsout);
}

CursorList* wci_createCursorList()
{
  CursorList* cl = new CursorList();
  allCursorLists.insert(cl);
  return cl;
}

void wci_disposeCursorList(CursorList* cl)
{
  cl->clear();
  allCursorLists.erase(cl);
}

unsigned int wci_sizeofCursorList(CursorList* cl)
{
  return cl->size();
}

void wci_getCLCursor(char* cuout, CursorList* cl, int cuid)
{
  wci_save_CXCursor((*cl)[cuid], cuout);
}

const char* wci_getCString(char* csin )
{
  CXString cxstr = wci_get_CXString(csin);
  return clang_getCString(cxstr);
}

void wci_disposeString(char* csin)
{
  CXString cxstr = wci_get_CXString(csin);
  clang_disposeString(cxstr);
}

} // extern
