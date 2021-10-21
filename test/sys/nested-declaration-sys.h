struct Outer
{
    // Inner is visible in global scope
    struct Inner
    {
        int i;
    } inner;
};

typedef struct Inner Inner_t;
