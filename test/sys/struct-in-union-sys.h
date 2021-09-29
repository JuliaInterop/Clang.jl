typedef struct __pthread_internal_list
{
    struct __pthread_internal_list *__prev;
} __pthread_list_t;

typedef union
{
    struct __pthread_mutex_s
    {
        __pthread_list_t __list;
    } __data;
    char __size[1];
} pthread_mutex_t;
