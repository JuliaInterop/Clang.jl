typedef const int (* volatile foo)[3];

typedef char arrayType[3];

struct MyStruct {
    int foo;
    char bar;
};

typedef struct MyStruct alias;

typedef struct Node Node;
struct Node {
    int data;
    Node *nextptr;
};

// issue #213
typedef enum _bar {
  BAR,
  BAZ
} bar;

// issue #214
typedef union secretunion SECRET;
