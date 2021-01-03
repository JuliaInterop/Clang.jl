#ifndef __C_TEST_INSANE_H__
#define __C_TEST_INSANE_H__

// yes, yes, this is legal, but anyone who writes code like this must be a masochist
// welp, just found one: 
//   https://stackoverflow.com/questions/19668681/typedef-a-struct-to-a-point-with-the-same-name-as-the-struct
typedef struct c_ins_name {
    int x;
    char y;
} *c_ins_name;

struct foo {
    struct c_ins_name x;
    c_ins_name y;
};

// int insane(c_ins_name x, struct c_ins_name y);

// typedef an identifier that has the same name as a tag-type "A" but 
// the underlying type is actually something else
struct Foo {
  int x;
};

struct Bar {
  int x;
};

typedef struct Foo Bar;
typedef struct Bar Foo;

// use the same name for structs and functions
struct post {
    char m;
};

void post(struct post m);

#endif // __C_TEST_INSANE_H__

