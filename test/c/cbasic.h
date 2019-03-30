#define CONST 1
#define CONSTADD CONST + 2
#define CONSTSFT (1<<2)

typedef enum {
    Juneau = 0x0,
    Seattle = 0x1,
    Portland = 0x3
} WtoECapitals;

int func1(int a, double b, double* c, void* d);

int func_constarr_arg(double x[3]);
