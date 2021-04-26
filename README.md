## Clang

[![Build Status](https://travis-ci.org/JuliaInterop/Clang.jl.svg?branch=master)](https://travis-ci.org/JuliaInterop/Clang.jl)
[![Build Status](https://github.com/JuliaInterop/Clang.jl/workflows/CI/badge.svg)](https://github.com/JuliaInterop/Clang.jl/actions)
![TagBot](https://github.com/JuliaInterop/Clang.jl/workflows/TagBot/badge.svg)
[![codecov](https://codecov.io/gh/JuliaInterop/Clang.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaInterop/Clang.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaInterop.github.io/Clang.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaInterop.github.io/Clang.jl/dev)

This package provides a Julia language wrapper for libclang: the stable, C-exported
interface to the LLVM Clang compiler. The [libclang API documentation](http://clang.llvm.org/doxygen/group__CINDEX.html)
provides background on the functionality available through libclang, and thus
through the Julia wrapper. The repository also hosts related tools built
on top of libclang functionality.

## Installation
```
pkg> dev Clang
```

## C-bindings generator

TODO: add docs

### Quick start

generator.toml
```
[general]
library_name = "libclang"
output_file_path = "./LibClang.jl"
module_name = "LibClang"
jll_pkg_name = "Clang_jll"
export_symbol_prefixes = ["CX", "clang_"]
```

generator.jl
```julia
using Clang.Generators
using Clang.LibClang.Clang_jll

cd(@__DIR__)

const INCLUDE_DIR = joinpath(Clang_jll.artifact_dir, "include") |> normpath
const CLANG_C_DIR = joinpath(INCLUDE_DIR, "clang-c")

headers = [joinpath(CLANG_C_DIR, header) for header in readdir(CLANG_C_DIR) if endswith(header, ".h")]
options = load_options(joinpath(@__DIR__, "generator.toml"))

# add compiler flags
args = get_default_args()
push!(args, "-I$INCLUDE_DIR")

headers = detect_headers(CLANG_C_DIR, args)

# add extra definition
@add_def time_t AbstractJuliaSIT JuliaCtime_t Ctime_t

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
```


