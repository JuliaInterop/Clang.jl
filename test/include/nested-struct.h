#include "struct-in-union-sys.h"

typedef struct
{
    struct
    {
        pthread_mutex_t lock;
    } s;
} test_t;
