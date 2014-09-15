## Clang.jl

Clang.jl provides a Julia language wrapper for libclang: the stable, C-exported
interface to (a subset of) the LLVM Clang compiler. The [libclang API documentation](http://clang.llvm.org/doxygen/group__CINDEX.html)
provides background on the functionality available through libclang, and thus
through the Julia wrapper. The Clang.jl repository also hosts related tools built
on top of libclang functionality.

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

* [Gtk.jl](https://github.com/JuliaLang/Gtk.jl): Julia Gtk bindings (uses heavily customized generator)
* [CUDArt.jl](https://github.com/JuliaGPU/CUDArt.jl): Bindings to the CUDA Runtime library
* [CUFFT.jl](https://github.com/JuliaGPU/CUFFT.jl): Bindings to CUDA FFT library
* [Sundials.jl](https://github.com/tshort/Sundials.jl): interface to the LLNL "SUite of Nonlinear and DIfferential/ALgebraic equation Solvers" package
* [libCURL.jl](https://github.com/amitmurthy/libCURL.jl): wrapper of cURL
* [VideoIO.jl](https://github.com/kmsquire/VideoIO.jl): Julia bindings for libav/ffmpeg
* [WCSLIB.jl](https://github.com/JuliaAstro/WCSLIB.jl)
* [NIDAQ.jl](https://github.com/JaneliaSciComp/NIDAQ.jl): wrapper for NIDAQ data acquisition library

## Installation

### Prerequisites

libclang and libclang-dev (versions >= 3.1) are required. libclang may
optionally be built by the Julia build system by setting 
BUILD_LLVM_CLANG=1 in `julia/Make.user`.

When using a distribution packaged version, note the latest version 
may only be available from an optional pre-release archive (e.g. Ubuntu PPA).


### Install

To install using the Julia package manager, use: Pkg.add("Clang").
You can use an external LLVM/Clang to build Clang.jl by specifying a llvm-config:
```
ENV["LLVM_CONFIG"]="/usr/lib/llvm-3.3/bin/llvm-config"
Pkg.add("Clang")
```

## Background Information

### libclang wrapper status

The cindex.jl libclang wrapper encompasses most CXType, CXCursor,
and C++ related functions. A small convenience API is provided
for basic tasks related to index generation, and retrieval of
cursor kind and type information.

All testing and development so far has been on Ubuntu 12.04.1 (64-bit)



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
  See the examples/ and util/ folders for further usage 
  scenarios. Clang.jl is partially self-generating,
  including parsing of the enums (util/genCIndex_h.jl)

  There is a small convenience API exported by CIndex:
  
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

  For documentation of wrapped CIndex functions, see:

  http://clang.llvm.org/doxygen/group__CINDEX.html

  For a nice introduction to some capabilities and 
  limitations (fewer now) of the libclang API,
  see this post:

  http://eli.thegreenplace.net/2011/07/03/parsing-c-in-python-with-clang/

### Implementation

Most libclang functions accept and return small 
structs by value. As Julia does not (yet) have full struct 
support, the current Clang.jl implementation includes a 
C++ wrapper. clang functions are wrapped by a C++ function
that memcpys data to/from a Julia-owned memory array 
(passed by pointer)

see src/cindex_base.jl and deps/src/wrapclang.h for generated wrappers.

Some functions are manually wrapped for convenience and ease of
implementation, or to provide a more Julia-friendly API.

see src/Clang.jl and deps/src/wrapclang.cpp

### License

Clang.jl is licensed under the MIT license.
