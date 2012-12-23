module cindex
using Base
import Base.ref

export cu_type, cu_kind, ty_kind, name, spelling, is_function, is_null,
  value, children, cu_file
export resolve_type, return_type
export tu_init, tu_cursor
export CXType, CXCursor, CXString, CXTypeKind, CursorList

libclang = dlopen("libclang")
const libwci = "../lib/libwrapcindex"

# Type definitions for wrapped types

typealias CXTypeKind Int32
typealias CXCursorKind Int32
typealias CXTranslationUnit Ptr{Void}
const CXString_size = ccall( ("wci_size_CXString", libwci), Int, ())

# work-around: ccall followed by composite_type in @eval gives error.
get_sz(sym) = @eval ccall( ($(strcat("wci_size_", sym)), $libwci), Int, ())

for st in Any[
    :CXUnsavedFile, :CXSourceLocation, :CXSourceRange,
    :CXTUResourceUsageEntry, :CXTUResourceUsage, :CXCursor, :CXType,
    :CXToken, :CXFile ]
  # Generate container types from the above list
  sz_name = symbol(strcat(st,"_size"))
  @eval begin
    const $sz_name = get_sz($("$st"))
    type $(st)
      data::Array{Uint8,1}
      $st() = new(Array(Uint8, $sz_name))
    end
  end
end

type CXString
  data::Array{Uint8,1}
  str::ASCIIString
  CXString() = new(Array(Uint8, CXString_size), "")
end

type CursorList
  ptr::Ptr{Void}
  size::Int
end

function get_string(cx::CXString)
  p::Ptr{Uint8} = ccall( (:wci_getCString, libwci), 
    Ptr{Uint8}, (Ptr{Void},), cx.data)
  if (p == C_NULL)
    cx.str = ""
  else
    cx.str = bytestring(p)
    ccall( (:wci_disposeString, libwci), Void, (Ptr{Uint8},), p)
  end
  cx.str
end

# These require statements must follow type definitions above.
require("../src/cindex_base.jl")
require("../src/cindex_h.jl")

# TODO: macro version should be more efficient.
anymatch(first, args...) = any({==(first, a) for a in args})

cu_type(c::CXCursor) = getCursorType(c)
cu_kind(c::CXCursor) = getCursorKind(c)
ty_kind(c::CXType) = reinterpret(Int32, c.data[1:4])[1]
name(c::CXCursor) = getCursorDisplayName(c)
spelling(c::CXType) = getTypeKindSpelling(ty_kind(c))
spelling(c::CXCursor) = getCursorSpelling(c)
is_function(c::CXCursor) = (cu_kind(c) == CurKind.FUNCTIONDECL)
is_function(t::CXType) = (ty_kind(t) == TypKind.FUNCTIONPROTO)
is_null(c::CXCursor) = (Cursor_isNull(c) != 0)

function resolve_type(rt::CXType)
  # This helper attempts to work around some limitations of the
  # current libclang API.
  if cu_kind(rt) == cindex.TypKind.UNEXPOSED
    # try to resolve Unexposed type to cursor definition.
    rtdef_cu = cindex.getTypeDeclaration(rt)
    if (!is_null(rtdef_cu) && cu_kind(rtdef_cu) != CurKind.NODECLFOUND)
      return cu_type(rtdef_cu)
    end
  end
  # otherwise, this will either be a builtin or unexposed
  # client needs to sort out.
  return rt
end
function return_type(c::CXCursor)
  is_function(c) ? resolve_type( getCursorResultType(c) ) : 
    error("return_type Cursor argument must be a function")
end

function value(c::CXCursor)
  if cu_kind(c) != CurKind.ENUMCONSTANTDECL
    error("Not a value cursor.")
  end
  t = cu_type(c)
  if anymatch(ty_kind(t), 
    TypKind.INT, TypKind.LONG, TypKind.LONGLONG)
      return getEnumConstantDeclValue(c)
  end
  if anymatch(ty_kind(t),
    TypKind.UINT, TypKind.ULONG, TypKind.ULONGLONG)
      return getEnumConstantDeclUnsignedValue(c)
  end
end

tu_init(hdrfile::Any) = tu_init(hdrfile, 0,0)
tu_init(hdrfile::Any, exclPCHDecl::Int, dispDiag::Int) = 
  ccall( (:wci_initIndex, libwci),
      Ptr{Void}, 
      (Ptr{Uint8}, Uint8, Uint8),
      convert(Ptr{Uint8}, hdrfile), exclPCHDecl, dispDiag)

dispose_tu() = ""

function tu_cursor(tu::Ptr{Void})
  cuout = CXCursor()
  ccall( (:wci_getTUCursor, libwci),
    Void,
    (Ptr{Void}, Ptr{Uint8}), tu, cuout.data)
  return cuout
end

function cl_create()
  cl = CursorList(C_NULL,0)
  cl.ptr = ccall( (:wci_createCursorList, libwci),
    Ptr{Void},
    () )
  return cl
end

function cl_dispose(cl::CursorList)
  ccall( (:wci_disposeCursorList, libwci),
    None,
    (Ptr{Void},), cl.ptr)
  cl.ptr = C_NULL
  cl.size = 0
end

cl_size(cl::CursorList) = cl.size
cl_size(clptr::Ptr{Void}) =
  ccall( (:wci_sizeofCursorList, libwci),
    Int,
    (Ptr{Void},), clptr)

function ref(cl::CursorList, clid::Int)
  if (clid < 1 || clid > cl.size) error("Index out of range or empty list") end 
  cu = CXCursor()
  ccall( (:wci_getCLCursor, libwci),
    Void,
    (Ptr{Void}, Ptr{Void}, Int), cu.data, cl.ptr, clid-1)
  return cu
end

function children(cu::CXCursor)
  cl = cl_create() 
  ccall( (:wci_getChildren, libwci),
    Ptr{Void},
      (Ptr{Void}, Ptr{Void}), cu.data, cl.ptr)
  cl.size = cl_size(cl.ptr)
  return cl
end

function cu_file(cu::CXCursor)
  str = CXString()
  ccall( (:wci_getCursorFile, libwci),
    Void,
      (Ptr{Void}, Ptr{Void}), cu.data, str.data)
  return get_string(str)
end

end # module
