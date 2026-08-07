# Clang
This package generates Julia bindings for C libraries from their header files. It is built on
Clang's C++ API through [ClangCompiler.jl](https://github.com/JuliaInterop/ClangCompiler.jl), so
record layouts, canonical declarations and macro definitions come from the compiler itself
rather than being reconstructed.

!!! warning "libclang was removed"
    Up to and including v0.19, this package also shipped a libclang binding — `Clang.LibClang`,
    `CLCursor`, `CLType`, `parse_headers`, `children`, `spelling` and an object layer of some
    300 cursor types. That is gone. libclang and clang-cpp both register LLVM's global
    command-line options statically, so no process can load both, and the generator needs the
    C++ side. Code that used Clang.jl to **walk an AST** rather than to generate bindings should
    pin `Clang@0.19` or use ClangCompiler.jl directly.

## Installation
Now, the package provides an out-of-box installation experience on Linux, macOS and Windows. You
could simply install it by running:
```
pkg> add Clang
```

To run the tests, use the usual `] test` command.

## C-bindings generator
The package includes a generator to create Julia wrappers for C libraries from a collection of header files. The following declarations are currently supported:

- function: translated to Julia ccall (some caveats about variadic functions, see [Variadic Function](@ref))
- struct: translated to Julia struct
- enum: translated to [`Enum`](https://docs.julialang.org/en/v1/base/base/#Base.Enums.Enum) or [`CEnum`](https://github.com/JuliaInterop/CEnum.jl)
- union: translated to Julia struct
- typedef: translated to Julia typealias to underlying intrinsic type
- macro: object-like macros are parsed as C by clang and translated from the typed AST
- bitfield: supported, with generated accessors

The following example wraps a JLL package's headers and prints the wrapper to `LibFoo.jl`.

First write a configuration script `generator.toml`.
```toml
[general]
library_name = "libfoo"
output_file_path = "./LibFoo.jl"
module_name = "LibFoo"
jll_pkg_name = "Foo_jll"
export_symbol_prefixes = ["FOO_", "foo_"]
```
Then load the configurations and generate a wrapper.
```julia
using Clang.Generators
using Foo_jll

cd(@__DIR__)

include_dir = normpath(Foo_jll.artifact_dir, "include")
header_dir = joinpath(include_dir, "foo")

# wrapper generator options
options = load_options(joinpath(@__DIR__, "generator.toml"))

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()
push!(args, "-I$include_dir")

headers = [joinpath(header_dir, h) for h in readdir(header_dir) if endswith(h, ".h")]
# there is also a `detect_headers` function for auto-detecting top-level headers in a directory
# headers = detect_headers(header_dir, args)

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
```



!!! note "Compatibility"
    
    The generator above is introduced in Clang.jl 0.14. If you are working with older versions
    of Clang.jl, check [older versions of documentation](https://juliainterop.github.io/Clang.jl/v0.12/).
    The libclang object layer was removed after v0.19 — see the warning at the top.


