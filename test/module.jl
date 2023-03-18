using Clang
# using Test

@testset "Module" begin
modulemap = """
module foo {
    module bar [system] {
        header "test.h"
        export *
    }
}

"""
header = """
#pragma once
typedef struct {int a;int b;} Bar;
"""

source = """
@import foo.bar;
"""

dir = mktempdir()
args = [
    "-x",
    "objective-c",
    "-fmodules",
    "-I$dir",
]

create(f,s) = begin
    fp = joinpath(dir,f);
    open(fp,"w") do io
        print(io,s)
    end
    fp
end

create("module.modulemap", modulemap)
h = create("test.h", header)
f = create("source.h", source)

index = Index()
tu = parse_header(index, f, args)
f = tu |> Clang.getTranslationUnitCursor |> children |> first |> file
mod = get_module(tu, f)
@test name(mod) == "bar"
@test full_name(mod) == "foo.bar"
@test full_name(parent_module(mod)) == "foo"
@test toplevel_headers(tu,mod) |> only |> name == h 
@test is_system(mod) == true
@test ast_file(mod) |> name != ""
end
