struct ExStruct {
    int    kind;
    char*  name;
    float* data;
};

void* ExFunction (int kind, char* name, float* data) {
    struct ExStruct st;
    st.kind = kind;
    st.name = name;
    st.data = data;
}
