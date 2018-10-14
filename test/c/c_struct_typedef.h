struct Str
{
  int x;
};

typedef struct Str Str;

/* If this remains unparseable, char2 should be omitted from the file */
struct __attribute__((aligned(2))) char2
{
  signed char x,y;
};

typedef struct char2 char2;
