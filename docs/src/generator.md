# Generator Tutorial

## Tutorial on wrapping a JLL package
In most situations, Clang.jl is used to export a Julia interface to a C library managed by a JLL package. A JLL package wraps an artifact which provides shared library that can be called with `ccall` syntax, and headers suitable for a C compiler. Clang.jl can translate the C headere into Julia files that can be directly used like normal Julia functions and types.

The general workflow of wrapping a JLL package is:

1. Locate the C headers relative to the artifact directory.
2. Find the compiler flags needed to parse these headers.
3. Create a .toml file with generator options.
4. Build a context with the above three and run.
5. Test and troubleshoot the wraper.

### Create a default generator
A generator context consists of a list of headers, a list of compiler flags, and generator options. Below creates a typical context and runs the generator:
```julia
using Clang.Generators
using Clang.LibClang.Clang_jll

cd(@__DIR__)

include_dir = joinpath(Clang_jll.artifact_dir, "include") |> normpath

# wrapper generator options
options = load_options(joinpath(@__DIR__, "generator.toml"))

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()
push!(args, "-I$include_dir")

# only wrap libclang headers in include/clang-c
header_dir = joinpath(include_dir, "clang-c")
headers = [joinpath(header_dir, header) for header in readdir(header_dir) if endswith(header, ".h")]

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
```
You can also use the experimental `detect_headers` function to automatically detect top-level headers in the directory
```julia
headers = detect_headers(header_dir, args)
```
You also need an options file `generator.toml` that to make this script work, you can refer to [this toml file](https://github.com/JuliaInterop/Clang.jl/blob/master/gen/generator.toml) for a reference.

### Skipping specific symbols
The C header may contain some symbols that are not correctly handled by Clang.jl, or need manual wrapping. For example, julia provides `tm` as `Libc.TmStruct`, so you may not want to map it to a new struct. As a workaround, you can skip these symbols. After that, if this symbol is needed, you can add it back in prologue. Prologue is handled by the `prologue_file_path` option.

* Add the symbol to `printer_blacklist` to avoid it from being wrapped.
* If the symbol is in system headers and causes Clang.jl to error before printing, apart from posting an issue, write `@add_def symbol_name` before generating to suppress it from being wrapped.

### Rewrite expressions before printing
You can also modifier the generated wrapped before it is printed. Clang.jl separates buildig process into generating and printing, you can run these two process separately and rewrite expressions before printing.
```julia
# build without printing so we can do custom rewriting
build!(ctx, BUILDSTAGE_NO_PRINTING)

# custom rewriter
function rewrite!(e::Expr)
end

function rewrite!(dag::ExprDAG)
    for node in get_nodes(dag)
        for expr in get_exprs(node)
            rewrite!(expr)
        end
    end
end

rewrite!(ctx.dag)

# print
build!(ctx, BUILDSTAGE_PRINTING_ONLY)
```

### Multi-platform configuration
Some headers may contain system-dependent symbols such as `long` or `char`, or system-indenpendent symbols may be resolved to system depent ones, for example, `int64_t` may be defined as `long`. You can skip these symbols and add them back manually as in [Skipping specific symbols](@ref). If the differences are two large to be manually fixed, you can generate wrappers for each platform as in [CImGUI.jl](https://github.com/JuliaImGui/LibCImGui.jl/blob/9af63ee69dc109000dabdb30ef86073d546738c3/gen/generator.jl).

## Variadic Function
With the help of `@ccall` macro, variadic C functions can be from Julia, for example, `@ccall printf("%d\n"::Cstring; 123::Cint)::Cint` can be used to call the C function `printf`. Note that those arguments after the semicolon `;` are variadic arguments.

If `wrap_variadic_function` in `codegen` section of options is set to `true`, `Clang.jl` will generate wrappers for variadic C functions, for example, `printf` will be wrapped as:
```julia
@generated function printf(fmt, va_list...)
        :(@ccall(libexample.printf(fmt::Ptr{Cchar}; $(to_c_type_pairs(va_list)...))::Cint))
    end
```
It can be called just like normal Julia functions without specifying types: `LibExample.printf("%d\n", 123)`.

!!! note
    Although variadic functions are supported, the C type `va_list` can not be used from Julia.

### Type Correspondence

However, variadic C functions must be called with the correct argument types. The most useful ones are listed below:

| C type                              | ccall signature                                  | Julia type                             |
|-------------------------------------|--------------------------------------------------|----------------------------------------|
| Integers and floating point numbers | the same type                                    | the same type                          |
| Struct `T`                          | a concrete Julia struct `T` with the same layout | `T`                                    |
| Pointer (`T*`)                      | `Ref{T}` or `Ptr{T}`                             | `Ref{T}` or `Ptr{T}` or any array type |
| String (`char*`)                    | `Cstring` or `Ptr{Cchar}`                        | `String`                               |

As observed from the table, if you want to pass strings or arrays to C, you need to annotate the type as `Ptr{T}` or `Ref{T}` (or `Cstring`), otherwise the struct that represents the `String` or `Array`type instead of the buffer itself will be passed. There are two methods to pass arguments of these types:
* directly use @ccall macro: `@ccall printf("%s\n"; "hello"::Cstring)::Cint`. You can also create wrappers for common use cases of this.
* overload `to_c_type` to map Julia type to correct ccall signature type: add `to_c_type(::Type{String}) = Cstring` to prologue (prologue can be added by setting `prologue_file_path` in options). Then all arguments of String will be annotated as `Cstring`.

For a complete tutorial on calling C functions, refer to [Calling C and Fortran Code](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/#Calling-C-and-Fortran-Code) in the Julia manual.