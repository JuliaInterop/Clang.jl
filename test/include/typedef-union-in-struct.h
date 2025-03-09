#include <stddef.h>

typedef union {
  int i;
  long l;
  long long l64;
  double d[2];
} BIGTYPE;

typedef struct {
  char type;
  char flags;
  char flags2;
  BIGTYPE value;
} C_STRUCT;
