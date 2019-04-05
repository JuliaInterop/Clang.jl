## Clang

[![Build Status](https://travis-ci.org/JuliaInterop/Clang.jl.svg?branch=master)](https://travis-ci.org/JuliaInterop/Clang.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/u4rkpvm2y4o8bo8r/branch/master?svg=true)](https://ci.appveyor.com/project/Gnimuc/clang-jl/branch/master)
[![codecov](https://codecov.io/gh/JuliaInterop/Clang.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaInterop/Clang.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaInterop.github.io/Clang.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaInterop.github.io/Clang.jl/dev)

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

## Usage
### C-bindings generator
The package includes a generator to create Julia wrappers for C libraries from a collection of header files. The following declarations are currently supported:

- function: translated to Julia ccall(`va_list` and vararg argument are not supported)
- struct: translated to Julia struct
- enum: translated to `CEnum`
- union: translated to Julia struct
- typedef: translated to Julia typealias to underlying intrinsic type
- macro: limited support(see src/wrap_c.jl)

Here is a simple example:
```julia
using Clang

# LIBCLANG_HEADERS are those headers to be wrapped.
const LIBCLANG_INCLUDE = joinpath(@__DIR__, "..", "deps", "usr", "include", "clang-c") |> normpath
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
Note that it might complain about missing some stdlibs, e.g. `fatal error: 'time.h' file not found`,
which could be fixed by adding `-Istdlib/include/on/your/specific/platform` to `clang_args`, for example,
```
# on macOS
push!(clang_args, "-I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.14.sdk/usr/include")
```

#### Backward compatibility
If you miss those old behaviors before v0.8, please `Pkg.pin` the package to v0.8 and
make the following change in your old generator script:
```julia
using Clang: CLANG_INCLUDE
using Clang.Deprecated.wrap_c
using Clang.Deprecated.cindex
```

### Build a custom C-bindings generator
A custom C-bindings generator tends to be used on large codebases, often with multiple API versions to support. Building a generator requires some customization effort, so for small libraries the initial
investment may not pay off.

The above-mentioned C-bindings generator only exposes several entry points for customization.
In fact, it's actually not that hard to directly build your own C-bindings generator,
for example, the following script is used for generating `LibClang`, you could refer to docs for
further details.
```julia
using Clang

const LIBCLANG_INCLUDE = joinpath(@__DIR__, "..", "deps", "usr", "include", "clang-c") |> normpath
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
        child_header = filename(child)
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

### LibClang
LibClang is a thin wrapper over libclang. It's one-to-one mapped to the libclang APIs.
By `using Clang.LibClang`, all of the `CX`/`clang_`-prefixed libclang APIs are imported into the
current namespace, with which you could build up your own tools from the scratch. If you are
unfamiliar with the Clang AST, a good starting point is the [Introduction to the Clang AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html).
