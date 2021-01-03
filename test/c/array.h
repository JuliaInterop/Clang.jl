#ifndef __C_TEST_ARRAY_H__
#define __C_TEST_ARRAY_H__

typedef struct bar {
    int x;
} bar;

typedef int foo[10];
typedef bar foo2[5];

typedef struct c_struct {
    double x;
} c_struct;

typedef struct {
  int x; 
  c_struct y[10]; 
} c_struct_with_array;

typedef struct {
  int x; 
  c_struct y[]; 
} c_struct_with_iarray;

typedef struct c_opaque* c_opaqueptr;

typedef struct {
  int x; 
  c_opaqueptr y[10]; 
} c_struct_with_array_opaque;

struct c_fddecl;
typedef struct c_fddecl *cfdarray[10];

typedef struct {
  int x; 
  struct c_fddecl *y[10];
} c_struct_with_array_fddecl;

struct c_fddecl{
    float y;
    int x;
};

typedef struct c_fddecl (*cfdptr)[10];

#endif // __C_TEST_ARRAY_H__