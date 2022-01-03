#include "bitfield.h"

struct BitField toBitfield(const struct Mirror *src) {
  struct BitField dst;
  dst.a = src->a;
  return dst;
}

struct Mirror toMirror(const struct BitField *src) {
  struct Mirror dst;
  dst.a = src->a;
  return dst;
}
