#define CONST 1
#define CONSTADD CONST + 2
#define CONSTSFT (1<<2)

typedef enum {
    Juneau = 0x0,
    Seattle = 0x1,
    Portland = 0x3
} WtoECapitals;

int func(int x, int y=1) {
    return x+y;
}
