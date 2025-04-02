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

struct LargeBitField {
  double a;
  short b;
  unsigned long long c : 16;
  unsigned long long  d : 48;
  char e;
  int f;
};

struct LargeMirror {
  double a;
  short b;
  unsigned long long c;
  unsigned long long  d;
  char e;
  int f;
};

struct BitField toBitfield(const struct Mirror *mirror);
struct Mirror toMirror(const struct BitField *bf);
struct LargeBitField toLargeBitfield(const struct LargeMirror *mirror);
struct LargeMirror toLargeMirror(const struct LargeBitField *bf);

#endif /* BITFIELD */
