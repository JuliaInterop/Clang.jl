typedef union nested_union
{
  struct {
    const char* str;
    int x;
  } foo;

  struct {
    const char* str;
    int x;
    float y;
    double z;
  } bar;
} nested_union;
