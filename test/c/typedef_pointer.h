typedef int *intptr;

typedef int (*funcptr)(float, int);

// issue #190
typedef struct {
    double x;
} FOO, *FOOP;

FOOP test1(double a, double b, FOOP c);
