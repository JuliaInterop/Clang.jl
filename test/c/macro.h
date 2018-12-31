#define G_URI_RESERVED_CHARS_SUBCOMPONENT_DELIMITERS "!$&'()*+,;="

#define FOO(x, a, b) (a) <= (x) && (x) < (b)
void macro_range(void) {
    int foo = 1;
    int x = 0;
    x = FOO(foo, 1, x);
}
