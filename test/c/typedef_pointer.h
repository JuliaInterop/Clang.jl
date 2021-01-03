typedef int *intptr;

typedef int (*funcptr)(float, int);

typedef struct {
    double x;
} *P;

// issue #190
typedef struct {
    double x;
} FOO, BAR, *FOOP, **BAZ;

FOOP test1(double a, double b, FOOP c);

typedef struct {
    int x;
} *FOOPTR, *FOOPTR2;

typedef struct {
    float x;
} **BARPTR;