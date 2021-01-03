#ifndef __C_TEST_FUNCTION_H__
#define __C_TEST_FUNCTION_H__

// issue 279
struct stat {
    char state;
};

void flux_stat_watcher_get_rstat(struct stat *stat);

// enums
enum tenumfwdecl;
typedef enum tenumfwdecl tenumfwdecl;
typedef enum tenumfwdecl* tenumptropaque;

enum tsimpleenum {
    SE1 = 0x0,
    SE2 = 0x1,
    SE3 = 0x3
};

enum __attribute__((packed)) tpackenum {
    PE1 = 0x0,
    PE2 = 0x1,
    PE3 = 0x3,
    PE4 = PE3
};

int foo(enum tsimpleenum x, enum tpackenum y, enum tenumfwdecl* z);
int bar(tenumfwdecl* x, tenumptropaque y);
// int baz(tenumfwdecl x, enum tenumfwdecl y); // this is not valid

// no proto
int noproto();
tenumptropaque noproto2();

// structs
struct tstructfwdecl;
typedef struct tstructfwdecl tstructfwdecl;
typedef struct tstructfwdecl* tstructptropaque;

struct tsimplestruct {
    int x;
};

struct __attribute__((packed)) tpackstruct {
    int x;
    char y;
    char z;
    float w;
};

int foo2(struct tsimplestruct x, struct tpackstruct y, struct tstructfwdecl* z);
int bar2(tstructfwdecl* x, tstructptropaque y);
// int baz2(tstructfwdecl x, struct tstructfwdecl y); // this is not valid 

// unions
union tunionfwdecl;
typedef union tunionfwdecl tunionfwdecl;
typedef union tunionfwdecl* tunionptropaque;

union tsimpleunion {
    int x;
};

union __attribute__((packed)) tpackunion {
    int x;
    char y;
    char z;
    float w;
};

int foo3(union tsimpleunion x, union tpackunion y, union tunionfwdecl* z);
int bar3(tunionfwdecl* x, tunionptropaque y);
// int baz3(tunionfwdecl x, union tunionfwdecl y); // this is not valid 




#endif // __C_TEST_FUNCTION_H__