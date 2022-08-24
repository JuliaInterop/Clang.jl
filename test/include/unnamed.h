// Issue 233
struct Meow {
    int blah;
    union {
        float either1;
        int either2;
    };
    float moo;
};