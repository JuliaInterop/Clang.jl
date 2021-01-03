#ifndef __C_TEST_TYPEDEF_H__
#define __C_TEST_TYPEDEF_H__

// advanced examples from https://cdecl.org
typedef char * const (*(* const ptr2array_of_ptr2func)[5])(int );
typedef int (*(*ptr2func)(const void *))[3];
typedef char ** const * const ptr2ptr2ptr2char;
typedef char (*(*array_of_ptr2func[3])())[5];
typedef char (*(*func())[5])();

typedef const int (* volatile volatile_array)[3];
typedef char array_3_element[3];

struct MyStruct {
    int foo;
    char bar;
};

typedef struct MyStruct alias;

struct Node {
    int data;
    Node *nextptr;
};
typedef struct Node Node;

struct Node2 {
    int data;
    struct Node2 *nextptr;
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

#define XXXXX 5
enum someEnum{
    one = XXXXX,
    two,
    three
};

// duplicated typedef
struct c_tdsn_t{
  int x;
};
typedef struct c_tdsn_t c_tdsn_t;
typedef struct c_tdsn_t c_tdsn1_t;
typedef c_tdsn_t c_tdsn1_t;

// typedef loop
struct c_tdloopy_t;
typedef struct c_tdloopy_t c_tdloopy_t2;
typedef c_tdloopy_t2 c_tdloopy_t3;
typedef c_tdloopy_t3 c_tdloopy_t;

#endif // __C_TEST_TYPEDEF_H__