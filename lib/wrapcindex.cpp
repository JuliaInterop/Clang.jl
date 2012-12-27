#include "Index.h"
#include <cstring>
#include <vector>
#include <set>

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
#include "wrapcindex.h"

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
