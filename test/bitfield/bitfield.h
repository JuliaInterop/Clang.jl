#ifndef BITFIELD
#define BITFIELD

struct BitField {
    int a : 5;
};

struct Mirror {
    int a;
};

struct BitField toBitfield(const struct Mirror *mirror);
struct Mirror toMirror(const struct BitField *bf);

#endif /* BITFIELD */
