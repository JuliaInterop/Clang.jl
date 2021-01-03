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

  struct {
    char* x;
    double y;
  };
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

// issue 238
struct struct_with_union
{
  float x;
  union {
    double y;
    float z[10];
  } foo;
} struct_with_union;

