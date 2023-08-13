typedef struct A A;
typedef struct B B;
typedef struct C C;

struct B;
struct C;

struct B
{
    B* x;
};

struct C
{
    B y[10];
};

typedef struct vector_C
{
    C* c;
} vector_C;

typedef struct pool_C
{
    vector_C vc;
} pool_C;

struct A
{
    pool_C pc;
    C* c;
};
