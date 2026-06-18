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

struct BitFieldWide toBitfieldWide(const struct MirrorWide *src) {
  struct BitFieldWide dst;
  dst.a = src->a;
  dst.b = src->b;
  return dst;
}

struct MirrorWide toMirrorWide(const struct BitFieldWide *src) {
  struct MirrorWide dst;
  dst.a = src->a;
  dst.b = src->b;
  return dst;
}

struct BitFieldZero toBitfieldZero(const struct MirrorZero *src) {
  struct BitFieldZero dst;
  dst.a = src->a;
  dst.b = src->b;
  dst.c = src->c;
  dst.d = src->d;
  return dst;
}

struct MirrorZero toMirrorZero(const struct BitFieldZero *src) {
  struct MirrorZero dst;
  dst.a = src->a;
  dst.b = src->b;
  dst.c = src->c;
  dst.d = src->d;
  return dst;
}
