Clang.jl provides an interface to libclang for the 
Julia language, and associated tools built on this
interface.

libclang is a stable, C-exported interface to a subset
of functionality provided by the Clang compiler, with 
a primary focus on exposing the C/C++/ObjC parse tree.

The [libclang API documentation](http://clang.llvm.org/doxygen/group__CINDEX.html)
provides background on the functionality available through libclang, and thus
through the Julia wrapper.

## Status

The cindex.jl wrapping encompasses most CXType, CXCursor,
and C++ related functions. A small convenience API is provided
for basic tasks related to index generation, and retreival of
cursor kind and type information.

A wrapper generator is in development to automatically create
Julia interfaces from C headers (src/wrap\_c.jl). Please see the
following repositories for examples of the wrapper driver and
generator output:

[libXML2](http://github.com/ihnorton/libXML2.jl)
[libAV](http://github.com/ihnorton/libAV.jl)

All testing and development so far has been on Ubuntu 12.04.1 (64-bit)

## Prerequisites

libclang >= 3.1 must be available as a shared library. libclang may
optionally be built by the Julia build system by setting 
BUILD_LLVM_CLANG=1 in julia/deps/Makefile.

## Installation

To install using the Julia package manager, use: Pkg.add("Clang")

## Usage
  ```julia
  using Clang.cindex

  julia> tu = tu_init("Index.h")   # Initialize and parse Index.h
  julia> topcu = tu_cursor(tu)     # get TU top cursor
  julia> topcl = children(topcu)
  julia> topcl.size
  595

  julia> cu = topcl[350]
  julia> cu_kind(cu) == CIndex.CurKind.FUNCTIONDECL
  true
  julia> name(topcl[350])
  "clang_parseTranslationUnit(CXIndex, const char *, const char *const *, int, struct CXUnsavedFile *, unsigned int, unsigned int)"
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

  For documentation of wrapped CIndex functions, see:

  http://clang.llvm.org/doxygen/group__CINDEX.html

  For a nice introduction to some capabilities and 
  limitations (fewer now) of the libclang API,
  see this post:

  http://eli.thegreenplace.net/2011/07/03/parsing-c-in-python-with-clang/

## Implementation

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
