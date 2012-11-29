#include "Index.h"
#include <cstring>
#include <vector>
#include <set>

#define DEBUG 0

#define CXType_s sizeof(CXType)
#define CXCursor_s sizeof(CXCursor)
#define CXString_s sizeof(CXString)

#define wci_saver(rtype) \
static inline rtype wci_save_##rtype(rtype i, char* o) \
  { memcpy(o, &i, rtype## _ ##s); }

wci_saver(CXCursor)
wci_saver(CXType)
wci_saver(CXString)

#define wci_getter(rtype) \
static inline rtype wci_get_##rtype(char* b) \
  { rtype c; memcpy(&c, b, rtype## _ ##s); return c; }

wci_getter(CXCursor)
wci_getter(CXType)
wci_getter(CXString)

typedef std::vector<CXCursor> CursorList;
typedef std::set<CursorList*> allcl_t;
allcl_t allCursorLists;

// to traverse AST with cursor visitor
CXChildVisitResult wci_visitCB(CXCursor cur, CXCursor par, CXClientData data)
{
  if (DEBUG) printf("visiting: %s\n", 
    clang_getCString(clang_getCursorDisplayName(cur)));
  CursorList* cl = (CursorList*)data;
  cl->push_back(cur);
  return CXChildVisit_Continue;
}

extern "C" {
#include "wrapcindex.h"

void* wci_initIndex(char* hdrFile, int excludePch, int displayDiag)
{
  // TODO: error message
  CXIndex wci_index = clang_createIndex(excludePch, displayDiag);
  if (wci_index == NULL)
    return NULL;
  CXTranslationUnit wci_basetu = clang_parseTranslationUnit( wci_index, hdrFile, NULL, 0, 0, 0, 0);
  if (wci_basetu == NULL)
    return NULL;
  return (void*) wci_basetu;
}

unsigned int wci_getChildren(char* cuin, CursorList* cl)
{
  CXCursor cu = wci_get_CXCursor(cuin);
  if (DEBUG) printf("getChildren display: %s\n", 
    clang_getCString(clang_getCursorDisplayName(cu)));
  if (DEBUG) printf("getChildren spelling: %s\n",
    clang_getCString(clang_getCursorSpelling(cu)));
  if (DEBUG) printf("getChildren cukind: %d\n", clang_getCursorKind(cu));
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

unsigned int wci_size_CXType() { return sizeof(CXType); }
unsigned int wci_size_CXCursor() { return sizeof(CXCursor); }
unsigned int wci_size_CXString() { return sizeof(CXString); }

void wci_getTUCursor(void* tu, char* cuout)
{
  CXCursor cu = clang_getTranslationUnitCursor((CXTranslationUnit)tu);
  wci_save_CXCursor(cu, cuout);
}
  

} // extern
