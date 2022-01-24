using Clang
using Clang.Generators
using Clang.Clang_jll
using LLVM

# compilation flags
CLANG_INC = joinpath(Clang_jll.artifact_dir, "lib", "clang", string(LLVM.version()), "include")
args = get_default_args("x86_64-linux-gnu")
push!(args, "-isystem" * CLANG_INC)

# create a context to hold the AST of the translation unit
ctx = create_context(joinpath(@__DIR__, "world.cpp"), args)

# this is the translation unit for `world.cpp`
tu = ctx.trans_units[1]

# get the cursor for the TU
# a cursor is a high-level stuff in libclang, it could stand for Decls, Stmts, Exprs, Types in Clang
tu_cursor = Clang.getTranslationUnitCursor(tu)

# we can collect all of the top-level cursors like
top_cursors = []
for cursor in children(tu_cursor)
    file_name = normpath(Clang.get_filename(cursor))
    # exclude those cursors in the "include"-ed system headers
    if endswith(file_name, "world.cpp")
        push!(top_cursors, cursor)
    end
end

# here we have two top-level cursors
# the first one is an `InclusionDirective` correspoding to the first line in the source code: "#include <string>"
# the second on is our `World` struct
top_cursors

world_cursor = top_cursors[2]

# now, we can use call `children` again to traversal the AST
v = children(world_cursor)

# our goal is to generate the following C++ code:
#
# types.add_type<World>("World")
#     .constructor<const std::string&>()
#     .constructor<jlcxx::cxxint_t>(false) // no finalizer
#     .constructor([] (const std::string& a, const std::string& b) { return new World(a + " " + b); })
#     .method("set", &World::set)
#     .method("greet_cref", &World::greet)
#     .method("greet_lambda", [] (const World& w) { return w.greet(); } );
cxx_code = ""

# all we need is looping through the top-level cursors and generate strings according to predefined rules.
# e.g.
# for `x` in `top_cursors`
#   if `x` isa `CLStructDecl` then:
struct_name = Clang.name(world_cursor)

cxx_code *= "types.add_type<$struct_name>(\"World\")"

#   for `y` in `x`
#     if `x` isa `CLConstructor` then:
cxx_code *= ".constructor"

# as the parameter type `const std::string&` is needed, we have to get this info from this `CLConstructor` cursor
ctor_cursor = v[1]

## HINT: use `dumpobj` interactively to print AST

# in this example, we can use `children` again, but there might be better options from libclang API
ctor_params_cursor = children(ctor_cursor)[1]

ty = Clang.getCursorType(ctor_params_cursor)

ty_str = Clang.spelling(ty)

cxx_code *= "<$ty_str>()"

# we can repeat this process to make rules and finally get a generator
cxx_code
