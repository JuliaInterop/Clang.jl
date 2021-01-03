#ifndef __C_TEST_MUTUAL_REF_H__
#define __C_TEST_MUTUAL_REF_H__

struct bar;
typedef struct bar bar;

struct foo {
    bar *x;
};

struct bar {
    struct foo *x;
};

#endif // __C_TEST_MUTUAL_REF_H__