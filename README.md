Clang.jl provides a wrapping of libclang for the 
Julia language (http://julialang.org). The goal of
Clang.jl is to facilitate access to C and C++ source
parse trees from Julia.

libclang is the stable interface to the Clang compiler 
from the LLVM project. libclang provides a C interface
to a subset of Clang functionality, with a primary focus 
on exposing the C/C++/ObjC parser AST.

libclang API docs: http://clang.llvm.org/doxygen/group__CINDEX.html

## Status

Preliminary. Most CXType, CXCursor, and C++ related 
functions are wrapped, and a few convenience functions
are provided.

All testing and development so far has been on Ubuntu 12.04.1 (64-bit)

## Prerequisites

libclang >= 3.1 must be available as a shared library. libclang can
optionally be built by the Julia build system by setting 
BUILD_LLVM_CLANG=1 in julia/deps/Makefile.

## Installation

Pkg.add("Clang")

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

Most libclang functions pass and return small 
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
