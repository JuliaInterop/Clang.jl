# Generator Tutorial

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