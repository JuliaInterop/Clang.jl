// issue #328
#define __cdecl

// issue #353
#define UCS_EMPTY_STATEMENT { }

// issue #356
#define S "abc"\
          "def"

// issue #357
#define SL L"string"

// issue #358
#define EL "DCAP_NONSPATIAL"

#define GINTBIG_MAX     ( (CPL_STATIC_CAST(GIntBig, 0x7FFFFFFF) << 32) | 0xFFFFFFFFU )
#define GUINTBIG_MAX    ( (CPL_STATIC_CAST(GUIntBig, 0xFFFFFFFFU) << 32) | 0xFFFFFFFFU )

// #389
#define foo foo
int foo(void);
