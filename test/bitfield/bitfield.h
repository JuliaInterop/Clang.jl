#ifndef BITFIELD
#define BITFIELD

struct BitField {
  char a;
  double b;
  int c;
  int d : 3;
  int e : 4;
  unsigned int f : 2;
};

struct Mirror {
  char a;
  double b;
  int c;
  int d;
  int e;
  unsigned int f;
};

struct BitField toBitfield(const struct Mirror *mirror);
struct Mirror toMirror(const struct BitField *bf);

#endif /* BITFIELD */
