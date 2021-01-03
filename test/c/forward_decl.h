#ifndef __C_TEST_FORWARD_DECL_H__
#define __C_TEST_FORWARD_DECL_H__

// forward decl
struct c_fwdecl_t;

// empty struct
struct c_empty_t{};

// anonymous typedef
typedef struct {
  struct c_fwdecl_t*  fwdecl;  // a pointer 
} c_has_fwdecl_t;

// forward decl definition
struct c_fwdecl_t{
  int x;
};

// self reference
typedef struct c_selfref_t c_selfref_t;
struct c_selfref_t{
  c_selfref_t *x;
};

typedef struct c_fwdecl_t (*ptrcfwdeclarray)[10];

typedef struct c_selfref_t2{
  struct c_selfref_t2 *x;
} c_selfref_t2;

struct c_selfref_t3{
  struct c_selfref_t3 *x;
};
typedef struct c_selfref_t3 c_selfref_t3;

// opaque
typedef struct FOO* foo;

// func
typedef void (c_callback)(c_selfref_t* smp, void* userdata);
typedef c_callback** c_callback_t;

typedef void (c_callback2)();

#endif // __C_TEST_FORWARD_DECL_H__