// 1. volatile array
typedef const int (* volatile foo)[3];

// 2. array
typedef char arrayType[3];

// 3. struct
struct MyStruct {
    int foo;
    char bar;
};

// 4. struct alias
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

// opaque
typedef struct VkInstance_T* VkInstance;