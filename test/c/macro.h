//　pure definition
#define JULIA_CLANG_MACRO_TEST

// macro constants
#define CONSTANT_LITERALS_1 0
#define CONSTANT_LITERALS_2 1.0f
#define CONSTANT_LITERALS_3 0x10
#define CONSTANT_LITERALS_4 0x10u
#define CONSTANT_LITERALS_5 0123
#define CONSTANT_LITERALS_6 'x'
#define CONSTANT_LITERALS_7 "abcdefg"

// issue #206
#define ISSUE_206 "!$&'()*+,;="

// macro constants bracket version
#define CONSTANT_LITERALS_BRACKET ( 0x10u )

// macro constants with function call
#define CONSTANT_BY_FUNCCALL FUNCCALL ( CONSTANT_LITERALS_1 , 0xffffffffUL )

// macro constants with simple arithmetic
#define CONSTANT_BY_ARITHMETIC FUNCCALL ( CONSTANT_LITERALS_1 - CONSTANT_LITERALS_2 , ( 16ULL * ( ( 1ULL << 32 ) - 2ULL ) ) )
#define EQUALS_A_B (A == B)

// macro alias
#define ALIAS_DATATYPE int
#define ALIAS_THAT_SHOULD_SKIP EXTERN API

// function-like macros
#define SUM(a,b) (a + b)
#define SQR(c)  ((c) * (c))
#define VERSION(major,minor,sub) \
    (((major)*1000ULL + (minor))*1000ULL + (sub))

// issue #266: empty function-like macros
#define EMPTY_FUNCLIKE(x)

// C11's _Generic
#define GrB_Matrix_setElement(C,x,i,j)                    \
    _Generic                                              \
    (                                                     \
        (x),                                              \
        const bool      : GrB_Matrix_setElement_BOOL   ,  \
              bool      : GrB_Matrix_setElement_BOOL   ,  \
        const int8_t    : GrB_Matrix_setElement_INT8   ,  \
              int8_t    : GrB_Matrix_setElement_INT8   ,  \
        const uint8_t   : GrB_Matrix_setElement_UINT8  ,  \
              uint8_t   : GrB_Matrix_setElement_UINT8  ,  \
        const int16_t   : GrB_Matrix_setElement_INT16  ,  \
              int16_t   : GrB_Matrix_setElement_INT16  ,  \
        const uint16_t  : GrB_Matrix_setElement_UINT16 ,  \
              uint16_t  : GrB_Matrix_setElement_UINT16 ,  \
        const int32_t   : GrB_Matrix_setElement_INT32  ,  \
              int32_t   : GrB_Matrix_setElement_INT32  ,  \
        const uint32_t  : GrB_Matrix_setElement_UINT32 ,  \
              uint32_t  : GrB_Matrix_setElement_UINT32 ,  \
        const int64_t   : GrB_Matrix_setElement_INT64  ,  \
              int64_t   : GrB_Matrix_setElement_INT64  ,  \
        const uint64_t  : GrB_Matrix_setElement_UINT64 ,  \
              uint64_t  : GrB_Matrix_setElement_UINT64 ,  \
        const float     : GrB_Matrix_setElement_FP32   ,  \
              float     : GrB_Matrix_setElement_FP32   ,  \
        const double    : GrB_Matrix_setElement_FP64   ,  \
              double    : GrB_Matrix_setElement_FP64   ,  \
        const void *    : GrB_Matrix_setElement_UDT    ,  \
              void *    : GrB_Matrix_setElement_UDT       \
    )                                                     \
    (C, x, i, j)

// macro range test
#define FOO(x, a, b) (a) <= (x) && (x) < (b)
void macro_range(void) {
    int foo = 1;
    int x = 0;
    x = FOO(foo, 1, x);
}






