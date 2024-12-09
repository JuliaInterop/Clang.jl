#include <stdint.h>

typedef enum __attribute__((flag_enum,enum_extensibility(open))) X : uint32_t X;
enum X : uint32_t {
  A = 2,
  B = 4,
  C = 6,
};
