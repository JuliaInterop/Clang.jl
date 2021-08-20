# Clang
This package provides a Julia language wrapper for libclang: the stable, C-exported
interface to the LLVM Clang compiler. The [libclang API documentation](http://clang.llvm.org/doxygen/group__CINDEX.html)
provides background on the functionality available through libclang, and thus
through the Julia wrapper. The repository also hosts related tools built
on top of libclang functionality.

## Installation
Now, the package provides an out-of-box installation experience on Linux, macOS and Windows. You
could simply install it by running:
```
pkg> add Clang
```

## C-bindings generator
The package includes a generator to create Julia wrappers for C libraries from a collection of header files. The following declarations are currently supported:

- function: translated to Julia ccall (some caveats about variadic functions, see [Variadic Function](@ref))
- struct: translated to Julia struct
- enum: translated to [`Enum`](https://docs.julialang.org/en/v1/base/base/#Base.Enums.Enum) or [`CEnum`](https://github.com/JuliaInterop/CEnum.jl)
- union: translated to Julia struct
- typedef: translated to Julia typealias to underlying intrinsic type
- macro: limited support
- bitfield: experimental support

Here is a minimalistic example that wrappes example.h and prints the wrapper to screen.

First write a configuration script `generator.toml`.
```toml
[general]
library_name = "libclang"
output_file_path = "./LibClang.jl"
module_name = "LibClang"
jll_pkg_name = "Clang_jll"
export_symbol_prefixes = ["CX", "clang_"]
```
Then load the configurations and generate a wrapper.
```julia
using Clang.Generators
using Clang.LibClang.Clang_jll

cd(@__DIR__)

include_dir = joinpath(Clang_jll.artifact_dir, "include") |> normpath
clang_dir = joinpath(include_dir, "clang-c")

# wrapper generator options
options = load_options(joinpath(@__DIR__, "generator.toml"))

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()
push!(args, "-I$include_dir")

headers = [joinpath(clang_dir, header) for header in readdir(clang_dir) if endswith(header, ".h")]
# there is also an experimental `detect_headers` function for auto-detecting top-level headers in the directory
# headers = detect_headers(clang_dir, args)

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
```
Note that it might complain about missing some std headers, e.g. `fatal error: 'time.h' file not found`,
which could be fixed by adding `-Istdlib/include/on/your/specific/platform` to `clang_args`, for example,
```
# on macOS
using Clang: find_std_headers
for header in find_std_headers()
    push!(clang_args, "-I"*header)
end
```


!!! note "Compatibility"
    
    The generator above is introduced in Clang.jl 0.14. If you are working with older versions of Clang.jl, check [older versions of documentation](https://juliainterop.github.io/Clang.jl/v0.12/)


## LibClang
LibClang is a thin wrapper over libclang. It's one-to-one mapped to the libclang APIs.
By `using Clang.LibClang`, all of the `CX`/`clang_`-prefixed libclang APIs are imported into the
current namespace, with which you could build up your own tools from the scratch. If you are
unfamiliar with the Clang AST, a good starting point is the [Introduction to the Clang AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html).
