// anonymous typedef enum
typedef enum {
  Apple = 1
} Fruit;

// enum with a typedef
enum Banana {
  NotApple = 1
};
typedef enum Banana Fruit2;

// struct
typedef struct {
  int x;
  float y;
} Foo;

// struct with attribute syntax
typedef struct __attribute__((aligned(2)))
{
  signed char x,y;
} char2;

// anonymous typedef union
typedef union {void *ptr; int id;} handle;
