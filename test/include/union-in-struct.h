#include <stdint.h>

struct B {
  uint64_t ba;
  uint64_t bb;
};

union union_B {
  struct B b;
};

struct A {
  char a;
  union union_B b;
};
