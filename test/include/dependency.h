#ifndef DEPENDENCY
#define DEPENDENCY

// Issue 325
typedef struct {
  union {
    int numeric;
    int guid;
  } id;
} NodeId;

// Macro dependency
#define FIRST SECOND
#define SECOND 1

#endif /* DEPENDENCY */
