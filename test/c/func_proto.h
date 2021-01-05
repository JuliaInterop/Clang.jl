// func proto in a struct
typedef struct foo {
    int(*funcptr)(char* x, int y);
    char x;
} foo;

// func proto in a union
typedef union foounion {
    int(*funcptr)(char* x, int y);
    char x;
} foounion;

// func proto in a func signature
void baz(const char* x,float(*funcsig)(void* data, int idx), int z);