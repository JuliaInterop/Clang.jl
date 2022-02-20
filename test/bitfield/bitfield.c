#include "bitfield.h"

struct BitField toBitfield(const struct Mirror *src) {
  struct BitField dst;
  dst.a = src->a;
  dst.b = src->b;
  dst.c = src->c;
  dst.d = src->d;
  dst.e = src->e;
  dst.f = src->f;
  return dst;
}

struct Mirror toMirror(const struct BitField *src) {
  struct Mirror dst;
  dst.a = src->a;
  dst.b = src->b;
  dst.c = src->c;
  dst.d = src->d;
  dst.e = src->e;
  dst.f = src->f;
  return dst;
}
