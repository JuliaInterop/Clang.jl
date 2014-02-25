using Clang.cindex
using Base.Test

top = cindex.parse_header("cxx/cbasic.h";cplusplus = true)

funcs = cindex.search(top, "func")
@test length(funcs) == 1

f = funcs[1]

@test map(spelling, cindex.function_args(f)) == ASCIIString["Int", "Int"]

defs = cindex.function_arg_defaults(f)
@test defs == (nothing, 1)

