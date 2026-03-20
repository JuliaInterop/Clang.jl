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

struct BitFieldWide {
  unsigned long long a : 12;
  unsigned long long b : 52;
};

struct MirrorWide {
  unsigned long long a;
  unsigned long long b;
};

struct BitFieldZero {
  unsigned int a : 3;
  unsigned int b : 4;
  unsigned int : 0;
  unsigned int c : 5;
  unsigned int d : 11;
};

struct MirrorZero {
  unsigned int a;
  unsigned int b;
  unsigned int c;
  unsigned int d;
};

struct BitField toBitfield(const struct Mirror *mirror);
struct Mirror toMirror(const struct BitField *bf);
struct BitFieldWide toBitfieldWide(const struct MirrorWide *mirror);
struct MirrorWide toMirrorWide(const struct BitFieldWide *bf);
struct BitFieldZero toBitfieldZero(const struct MirrorZero *mirror);
struct MirrorZero toMirrorZero(const struct BitFieldZero *bf);

#endif /* BITFIELD */
