## Clang.jl

Clang.jl provides a Julia language wrapper for libclang: the stable, C-exported
interface to (a subset of) the LLVM Clang compiler. The [libclang API documentation](http://clang.llvm.org/doxygen/group__CINDEX.html)
provides background on the functionality available through libclang, and thus
through the Julia wrapper. The Clang.jl repository also hosts related tools built
on top of libclang functionality.

## C wrapper generator

Clang.jl includes a generator to create Julia wrappers for C libraries
from a collection of header files. The following declarations are currently supported:

* function: translated to Julia ccall, with full type translation
* typedef: translated to Julia typealias to underlying intrinsic type
* enum: translated to const value symbol

* struct: partial struct support may be enabled by setting WrapContext.options.wrap_structs = true
  * note: struct support is limited to intrinsic types. Unsupported constructs presently include:
    nested structs and unions, as well as fixed-size arrays.

Please see the following repositories for examples of the wrapper driver scripts and
generator output:

* [Sundials.jl](https://github.com/tshort/Sundials.jl): interface to the LLNL "SUite of Nonlinear and DIfferential/ALgebraic equation Solvers" package
* [libCURL.jl](https://github.com/amitmurthy/libCURL.jl): wrapper of cURL
* [libXML2.jl](http://github.com/ihnorton/libXML2.jl): wrapper of libxml2
* [libAV.jl](http://github.com/ihnorton/libAV.jl): work-in-progress wrapper of libavcodec and related headers

## C++ wrapper generator

The wip_cpp branch hosts a preliminary, work-in-progress C++ wrapper generator (Itanium ABI only).
For more information, see [this issue](https://github.com/ihnorton/Clang.jl/issues/20) and the C++ issue tag.

## Installation

### Prerequisites

libclang >= 3.1 must be available as a shared library. libclang may
optionally be built by the Julia build system by setting 
BUILD_LLVM_CLANG=1 in julia/deps/Makefile.

### Install

To install using the Julia package manager, use: Pkg.add("Clang")


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
