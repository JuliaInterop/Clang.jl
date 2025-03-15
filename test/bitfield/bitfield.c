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

struct LargeBitField toLargeBitfield(const struct LargeMirror *src) {
  struct LargeBitField dst;
  dst.a = src->a;
  dst.b = src->b;
  dst.c = src->c;
  dst.d = src->d;
  dst.e = src->e;
  dst.f = src->f;
  return dst;
}

struct LargeMirror toLargeMirror(const struct LargeBitField *src) {
  struct LargeMirror dst;
  dst.a = src->a;
  dst.b = src->b;
  dst.c = src->c;
  dst.d = src->d;
  dst.e = src->e;
  dst.f = src->f;
  return dst;
}
