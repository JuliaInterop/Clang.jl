CINDEX.jl provides a wrapping of libclang for the 
Julia language (http://julialang.org)

libclang is a C interface to the Clang compiler from
the LLVM project. libclang provides access to a subset
of the Clang functionality, primarily geared to C/C++/ObjC
AST parsing.

## Status

Preliminary. Most CXType, CXCursor, and C++ related 
functions are wrapped, providing AST traversing,
referencing, and type information.

All testing and development so far has been on Ubuntu 12.04.1 (64-bit)

## Usage
  ```julia
  load("cindex")
  using cindex

  julia> tu = tu_init("Index.h")   # Initialize and parse Index.h
  julia> topcu = tu_cursor(tu)     # get TU top cursor
  julia> topcl = children(topcu)

  julia> cu = topcl[350]
  julia> cu_kind(cu) == cindex.CurKind.FUNCTIONDECL
  true
  julia> name(topcl[350])
  "clang_parseTranslationUnit(CXIndex, const char *, const char *const *, int, struct CXUnsavedFile *, unsigned int, unsigned int)"
  ```
  See the examples folder for further usage scenarios.

  There is a small convenience API exported by cindex:
  
    tu_init     # init and parse file to TranslationUnit
    tu_cursor   # get top cursor from TranslationUnit
    children    # gets CXCursor children; accessed by ref.
    cu_kind     # cindex.CurKind enum
    ty_kind     # cindex.TypKind enum
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

## Prerequisites

libclang must be available as a shared library. libclang can
optionally be built by the Julia build system by setting 
BUILD_LLVM_CLANG=1 in julia/deps/Makefile.

## Implementation

Most libclang functions pass and return small 
structs by value. As Julia does not (yet) have full struct 
support, the current CINDEX.jl implementation includes a 
C++ wrapper. clang functions are wrapped by a C++ function
that memcpys data to/from a Julia-owned memory array 
(passed by pointer)

see src/cindex_base.jl and src/wrapcindex.h for generated wrappers.

Some functions are manually wrapped for convenience and ease of
implementation, or to provide a more Julia-friendly API.

see src/cindex.jl and src/wrapcindex.cpp

### License

CINDEX.jl is licensed under the MIT license.
