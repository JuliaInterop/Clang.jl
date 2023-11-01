#include <stdlib.h>
#include <stdbool.h>

struct mutualref {
  int type;

  struct buffer *buffer;

  int n_dims;
  int64_t ne[10]; 
  size_t nb[10]; 

  int32_t op_params[10 / sizeof(int32_t)];

  bool is_param;

  struct mutualref *grad;
  struct mutualref *src[10];

  struct mutualref *view_src;
  size_t view_offs;
  
  void *data;

  char padding[12];
};