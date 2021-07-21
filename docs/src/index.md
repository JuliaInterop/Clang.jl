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

- function: translated to Julia ccall(`va_list` and vararg argument are not supported)
- struct: translated to Julia struct
- enum: translated to [`CEnum`](https://github.com/JuliaInterop/CEnum.jl)
- union: translated to Julia struct
- typedef: translated to Julia typealias to underlying intrinsic type
- macro: limited support(see src/wrap_c.jl)

Here is a simple example:
```julia
using Clang
using Clang_jll # `pkg> activate Clang`

# LIBCLANG_HEADERS are those headers to be wrapped.
const LIBCLANG_INCLUDE = joinpath(dirname(Clang_jll.libclang_path), "..", "include", "clang-c") |> normpath
const LIBCLANG_HEADERS = [joinpath(LIBCLANG_INCLUDE, header) for header in readdir(LIBCLANG_INCLUDE) if endswith(header, ".h")]

wc = init(; headers = LIBCLANG_HEADERS,
            output_file = joinpath(@__DIR__, "libclang_api.jl"),
            common_file = joinpath(@__DIR__, "libclang_common.jl"),
            clang_includes = vcat(LIBCLANG_INCLUDE, CLANG_INCLUDE),
            clang_args = ["-I", joinpath(LIBCLANG_INCLUDE, "..")],
            header_wrapped = (root, current)->root == current,
            header_library = x->"libclang",
            clang_diagnostics = true,
            )

run(wc)
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


## Build a custom C-bindings generator
A custom C-bindings generator tends to be used on large codebases, often with multiple API versions to support. Building a generator requires some customization effort, so for small libraries the initial
investment may not pay off.

The above-mentioned C-bindings generator only exposes several entry points for customization.
In fact, it's actually not that hard to directly build your own C-bindings generator,
for example, the following script is used for generating `LibClang`, you could refer to [LibClang Tutorial](@ref) for
further details.

Write a config file `generator.toml`:
```
[general]
library_name = "libclang"
output_file_path = "./LibClang.jl"
module_name = "LibClang"
jll_pkg_name = "Clang_jll"
export_symbol_prefixes = ["CX", "clang_"]
```

and a Julia script `generator.jl`:
```julia
using Clang.Generators
using Clang.LibClang.Clang_jll

cd(@__DIR__)

include_dir = joinpath(Clang_jll.artifact_dir, "include") |> normpath
clang_dir = joinpath(include_dir, "clang-c")

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

Please refer to [this toml file](https://github.com/JuliaInterop/Clang.jl/blob/master/gen/generator.toml) for a full list of configuration options.

### v0.12 example
The generator above is the recommended generator for v0.14 and above. There was another generator wrappper before, here is an example.
```julia
using Clang
using Clang_jll # `pkg> activate Clang`

const LIBCLANG_INCLUDE = joinpath(dirname(Clang_jll.libclang_path), "..", "include", "clang-c") |> normpath
const LIBCLANG_HEADERS = [joinpath(LIBCLANG_INCLUDE, header) for header in readdir(LIBCLANG_INCLUDE) if endswith(header, ".h")]

# create a work context
ctx = DefaultContext()

# parse headers
parse_headers!(ctx, LIBCLANG_HEADERS,
               args=["-I", joinpath(LIBCLANG_INCLUDE, "..")],
               includes=vcat(LIBCLANG_INCLUDE, CLANG_INCLUDE),
               )

# settings
ctx.libname = "libclang"
ctx.options["is_function_strictly_typed"] = false
ctx.options["is_struct_mutable"] = false

# write output
api_file = joinpath(@__DIR__, "libclang_api.jl")
api_stream = open(api_file, "w")

for trans_unit in ctx.trans_units
    root_cursor = getcursor(trans_unit)
    push!(ctx.cursor_stack, root_cursor)
    header = spelling(root_cursor)
    @info "wrapping header: $header ..."
    # loop over all of the child cursors and wrap them, if appropriate.
    ctx.children = children(root_cursor)
    for (i, child) in enumerate(ctx.children)
        child_name = name(child)
        child_header = get_filename(child)
        ctx.children_index = i
        # choose which cursor to wrap
        startswith(child_name, "__") && continue  # skip compiler definitions
        child_name in keys(ctx.common_buffer) && continue  # already wrapped
        child_header != header && continue  # skip if cursor filename is not in the headers to be wrapped

        wrap!(ctx, child)
    end
    @info "writing $(api_file)"
    println(api_stream, "# Julia wrapper for header: $(basename(header))")
    println(api_stream, "# Automatically generated using Clang.jl\n")
    print_buffer(api_stream, ctx.api_buffer)
    empty!(ctx.api_buffer)  # clean up api_buffer for the next header
end
close(api_stream)

# write "common" definitions: types, typealiases, etc.
common_file = joinpath(@__DIR__, "libclang_common.jl")
open(common_file, "w") do f
    println(f, "# Automatically generated using Clang.jl\n")
    print_buffer(f, dump_to_buffer(ctx.common_buffer))
end

# uncomment the following code to generate dependency and template files
# copydeps(dirname(api_file))
# print_template(joinpath(dirname(api_file), "LibTemplate.jl"))
```

## LibClang
LibClang is a thin wrapper over libclang. It's one-to-one mapped to the libclang APIs.
By `using Clang.LibClang`, all of the `CX`/`clang_`-prefixed libclang APIs are imported into the
current namespace, with which you could build up your own tools from the scratch. If you are
unfamiliar with the Clang AST, a good starting point is the [Introduction to the Clang AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html).
