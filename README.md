## Clang

[![CI](https://github.com/JuliaInterop/Clang.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/JuliaInterop/Clang.jl/actions/workflows/ci.yml)
[![TagBot](https://github.com/JuliaInterop/Clang.jl/actions/workflows/TagBot.yml/badge.svg)](https://github.com/JuliaInterop/Clang.jl/actions/workflows/TagBot.yml)
[![codecov](https://codecov.io/gh/JuliaInterop/Clang.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaInterop/Clang.jl)
[![docs-stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaInterop.github.io/Clang.jl/stable)
[![docs-dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaInterop.github.io/Clang.jl/dev)
[![GitHub Discussions](https://img.shields.io/github/discussions/JuliaInterop/Clang.jl)](https://github.com/JuliaInterop/Clang.jl/discussions)

Clang.jl generates Julia bindings for C libraries from their header files. It is built on
Clang's C++ API through [ClangCompiler.jl](https://github.com/JuliaInterop/ClangCompiler.jl), so
record layouts, canonical declarations and macro definitions come from the compiler itself.

> [!WARNING]
> **The libclang binding was removed after v0.19.** `Clang.LibClang`, `CLCursor`, `CLType`,
> `parse_headers`, `children`, `spelling` and the rest of the object layer no longer exist —
> libclang and clang-cpp both register LLVM's global command-line options statically, so no
> process can load both, and the generator needs the C++ side. If you used Clang.jl to *walk an
> AST* rather than to generate bindings, pin `Clang@0.19` or use ClangCompiler.jl directly.

## Installation

```
pkg> add Clang
```

If you'd like to use the old generator(Clang.jl v0.13), please checkout [this branch](https://github.com/JuliaInterop/Clang.jl/tree/old-generator) for the documentation. Should you have any questions on how to upgrade the generator script, feel free to submit a post/request in the [Discussions](https://github.com/JuliaInterop/Clang.jl/discussions) area.

## Binding Generator

Clang.jl provides a module `Clang.Generators` for auto-generating C library bindings for Julia language from C headers.

### Quick start

Write a config file `generator.toml`:
```
[general]
library_name = "libfoo"
output_file_path = "./LibFoo.jl"
module_name = "LibFoo"
jll_pkg_name = "Foo_jll"
export_symbol_prefixes = ["FOO_", "foo_"]
```

and a Julia script `generator.jl`:
```julia
using Clang.Generators
using Foo_jll                          # replace this with your jll package

cd(@__DIR__)

include_dir = normpath(Foo_jll.artifact_dir, "include")
header_dir = joinpath(include_dir, "foo")

options = load_options(joinpath(@__DIR__, "generator.toml"))

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()  # Note you must call this function firstly and then append your own flags
push!(args, "-I$include_dir")

headers = [joinpath(header_dir, h) for h in readdir(header_dir) if endswith(h, ".h")]
# there is also an experimental `detect_headers` function for auto-detecting top-level headers in the directory
# headers = detect_headers(header_dir, args)

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
```

See [CXX-FRONTEND.md](./CXX-FRONTEND.md) for the full list of configuration options.

### Examples

The binding generator is currently used by many projects in the Julia package ecosystem and you can take them as good examples.

- [JuliaSparse/SparseArrays.jl](https://github.com/JuliaSparse/SparseArrays.jl): generate platform-specific bindings for SuiteSparse
- [maleadt/LLVM.jl](https://github.com/maleadt/LLVM.jl): generate platform-specific bindings for LLVM (multiple versions)
- [JuliaGPU/VulkanCore.jl](https://github.com/JuliaGPU/VulkanCore.jl): generate platform-specific bindings for Vulkan with optional third-party JLL dependencies
- [JuliaGPU/oneAPI.jl](https://github.com/JuliaGPU/oneAPI.jl): generate bindings for oneAPI and format the generated code with [JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl)
- [JuliaGeo/GDAL.jl](https://github.com/JuliaGeo/GDAL.jl): generate bindings for GDAL with customized docstrings extracted from doxygen
- [JuliaGeo/LibGEOS.jl](https://github.com/JuliaGeo/LibGEOS.jl): generate bindings for LibGEOS with customized rewriter
- [JuliaMultimedia/CSFML.jl](https://github.com/JuliaMultimedia/CSFML.jl): generate bindings for CSFML with multiple library names
- [SciML/Sundials.jl](https://github.com/SciML/Sundials.jl): generate bindings for Sundials with highly customized rewriter

Other Users:
- [CEED/libCEED](https://github.com/CEED/libCEED): libCEED's Julia binding
- [JuliaGPU/CUDA.jl](https://github.com/JuliaGPU/CUDA.jl): CUDA programming in Julia
- [scipopt/SCIP.jl](https://github.com/scipopt/SCIP.jl): Julia interface to the SCIP solver
- [JuliaParallel/MPI.jl](https://github.com/JuliaParallel/MPI.jl): MPI interface for the Julia language
- [JuliaGPU/Metal.jl](https://github.com/JuliaGPU/Metal.jl): Metal programming in Julia
- [JuliaIO/VideoIO.jl](https://github.com/JuliaIO/VideoIO.jl): Reading and writing of video files in Julia
- [JuliaGPU/AMDGPU.jl](https://github.com/JuliaGPU/AMDGPU.jl): AMD GPU (ROCm) programming in Julia
- [JuliaGeo/Proj.jl](https://github.com/JuliaGeo/Proj.jl): Julia wrapper around the PROJ cartographic projections library
- [JuliaIO/PNGFiles.jl](https://github.com/JuliaIO/PNGFiles.jl): Julia wrapper around libpng
- [JuliaSparse/KLU.jl](https://github.com/JuliaSparse/KLU.jl): Julia wrapper around the SuiteSparse solver KLU
- [JuliaGraphics/FreeType.jl](https://github.com/JuliaGraphics/FreeType.jl): FreeType bindings for Julia


