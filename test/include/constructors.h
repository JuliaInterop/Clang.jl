typedef struct _PackedFloat3 {
    union {
        struct {
            float x;
            float y;
            float z;
        };
        float elements[3];
    };
} PackedFloat3;


typedef struct _ConstructorTestNormal {
    PackedFloat3 arg1;
    PackedFloat3 arg2;
} ConstructorTestNormal;
