typedef struct nested_struct
{
  union {
    const char* x;
    int y;
  } union_in_struct;

  struct {
    const char* x;
    int y;
  } struct_in_struct;
} nested_struct;
