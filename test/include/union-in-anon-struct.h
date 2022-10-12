// Issue 233
typedef struct {
    int blah;
    union {
        float either1;
        int either2;
    };
    float moo;
} Meow;
