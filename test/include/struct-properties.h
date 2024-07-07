typedef struct {
    int i;
} TypedefStruct;

struct Other {
    int i;
};

struct WithFields {
    int int_value;
    int* int_ptr;

    struct Other struct_value;
    struct Other* struct_ptr;
    TypedefStruct typedef_struct_value;

    int array[2];
};
