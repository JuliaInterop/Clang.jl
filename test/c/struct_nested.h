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

typedef struct nested_struct2
{
  struct {
    struct {
      int x;
    } nest2, nest3;
    char s;
  } nest1;

} nested_struct2;
