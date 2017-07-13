using Clang.cindex
using Base.Test

top = cindex.parse_header(joinpath(dirname(@__FILE__), "cxx/cxxbasic.h");
                          cplusplus = true)

funcs = cindex.search(top, "func")
@test length(funcs) == 1
f = funcs[1]

#@test map(spelling, cindex.function_args(f)) == ["Int", "Int"]
@test map(spelling, cindex.function_args(f)) == ["x", "y"]
@test isa(return_type(f), IntType)

defs = cindex.function_arg_defaults(f)
#TODO enable me @test defs == (nothing, -10)


funcs = cindex.search(top, "func2")
@test length(funcs) == 1
f = funcs[1]

@test all(map(x->x.text, function_return_modifiers(f)) .== ["const", ])
