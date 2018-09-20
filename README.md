## Clang.jl

[![Build status](https://api.travis-ci.org/ihnorton/Clang.jl.svg?branch=master)](https://travis-ci.org/ihnorton/Clang.jl)

Clang.jl provides a Julia language wrapper for libclang: the stable, C-exported
interface to (a subset of) the LLVM Clang compiler. The [libclang API documentation](http://clang.llvm.org/doxygen/group__CINDEX.html)
provides background on the functionality available through libclang, and thus
through the Julia wrapper. The Clang.jl repository also hosts related tools built
on top of libclang functionality.

If you are unfamiliar with the Clang AST and plan to access the internals of this library
(as opposed to accessing the 'wrap-c' bindings), a good starting point is the
[Introduction to the Clang AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html).

## Installation
Before installing Clang.jl, you might need to install `libclang` related packages(llvm-6.0,
llvm-6.0-tools, libclang-6.0-dev) on Linux. To use your LLVM/Clang in other places, you could
set an environment variable `LLVM_CONFIG` to that path. On Windows, you need to install [LLVM officially
released prebuild binaries](http://releases.llvm.org/download.html) and the corresponding
environment variable is `LLVM_WINDOWS`.

```
pkg> add Clang
```

## Getting Started
Installation requirements are listed down page.

[Clang.jl Documentation](http://clangjl.readthedocs.org/)

Example notebooks:
------------------

[Usage Examples](http://nbviewer.ipython.org/urls/raw.github.com/ihnorton/Clang.jl/master/examples/example_notebook.ipynb)

[Parsing C with Clang and Julia](http://nbviewer.ipython.org/urls/raw.github.com/ihnorton/Clang.jl/master/examples/parsing_c_with_clangjl/notebook.ipynb)

## C wrapper generator

Clang.jl includes a generator to create Julia wrappers for C libraries
from a collection of header files. The following declarations are currently supported:

* function: translated to Julia ccall, with full type translation
* typedef: translated to Julia typealias to underlying intrinsic type
* enum: translated to const value symbol
* struct: partial struct support may be enabled by setting WrapContext.options.wrap_structs = true

## Users
Clang.jl tends to be used on large codebases, often with multiple API versions to support. Building a generator requires some customization effort, so
for small libraries the initial investment may not pay off.

* [Gtk.jl](https://github.com/JuliaLang/Gtk.jl): Julia Gtk bindings (uses heavily customized generator)
* [CUDArt.jl](https://github.com/JuliaGPU/CUDArt.jl): Bindings to the CUDA Runtime library
* [CUFFT.jl](https://github.com/JuliaGPU/CUFFT.jl): Bindings to CUDA FFT library
* [Sundials.jl](https://github.com/tshort/Sundials.jl): interface to the LLNL "SUite of Nonlinear and DIfferential/ALgebraic equation Solvers" package
* [LibCURL.jl](https://github.com/JuliaWeb/LibCURL.jl): wrapper of cURL
* [VideoIO.jl](https://github.com/kmsquire/VideoIO.jl): Julia bindings for libav/ffmpeg
* [WCSLIB.jl](https://github.com/JuliaAstro/WCSLIB.jl)
* [NIDAQ.jl](https://github.com/JaneliaSciComp/NIDAQ.jl): wrapper for NIDAQ data acquisition library


## Background Information

### libclang wrapper status

The cindex.jl libclang wrapper encompasses most CXType, CXCursor,
and C++ related functions. A small convenience API is provided
for basic tasks related to index generation, and retrieval of
cursor kind and type information.

### cindex.jl Usage
```julia
using Clang.cindex

julia> topcu = cindex.parse_header("Index.h") # Parse Index.h, returning the root cursor
julia> children(topcu).size
2148

julia> cu = cindex.search(top, "clang_parseTranslationUnit")[1]
julia> cu_kind(cu) == CIndex.CurKind.FUNCTIONDECL
true
julia> name(cu)
"clang_parseTranslationUnit(CXIndex, const char *, const char *const *, int, struct CXUnsavedFile *, unsigned int, unsigned int)"

julia> tkl = tokenize(cu)
julia> for tk in tkl
           println(tk) # use tk.text to get underlying string
       end
Identifier("CXTranslationUnit")
Identifier("clang_parseTranslationUnit")
Punctuation("(")
Identifier("CXIndex")
Identifier("CIdx")
Punctuation(",")
Keyword("const")
Keyword("char")
Punctuation("*")
Identifier("source_filename")
```
See the examples folder for further usage scenarios. Clang.jl is partially self-generating,
including parsing of the enums.

There is a small convenience API exported by CIndex:
```
  tu_init     # init and parse file to TranslationUnit
  tu_cursor   # get top cursor from TranslationUnit
  children    # gets CXCursor children; accessed by ref.
  cu_kind     # CIndex.CurKind enum
  ty_kind     # CIndex.TypKind enum
  name        # get the DisplayName of a CXCursor
  spelling    # get spelling of a CXCursor or CXType
  cu_file     # file in which cursor was declared
  is_function # CXCursor or CXType
  is_null     # CXCursor
  tokenize    # get tokens underlying given cursor
```
For documentation of wrapped CIndex functions, see:

http://clang.llvm.org/doxygen/group__CINDEX.html

For a nice introduction to some capabilities and
limitations (fewer now) of the libclang API,
see this post:

http://eli.thegreenplace.net/2011/07/03/parsing-c-in-python-with-clang/
