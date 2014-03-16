using Clang.cindex
using Base.Test

top = cindex.parse_header("cxx/cbasic.h";cplusplus = true)

funcs = cindex.search(top, "func")
@test length(funcs) == 1
f = funcs[1]

#@test map(spelling, cindex.function_args(f)) == ASCIIString["Int", "Int"]
@test map(spelling, cindex.function_args(f)) == ASCIIString["x", "y"]
@test isa(return_type(f), IntType)

defs = cindex.function_arg_defaults(f)
@test defs == (nothing, 1)


funcs = cindex.search(top, "func2")
@test length(funcs) == 1
f = funcs[1]

@test all(map(x->x.text, function_return_modifiers(f)) .== ["const", ])

cl = search(top, "MyClass1")|>first
Clang.wt.wrap(STDOUT, cl)
Clang.wt.wrapjl(STDOUT, "mylib", cl)

cl = search(top, "MyClass2")|>first
Clang.wt.wrap(STDOUT, cl)
Clang.wt.wrapjl(STDOUT, "mylib", cl)