module cindex
using Base
import Base.ref

libclang = dlopen("libclang")
const libwci = "./libwrapcindex"
const CXCursor_size = ccall( (:wci_size_CXCursor, libwci), Int, ())
const CXType_size = ccall( (:wci_size_CXType, libwci), Int, ())
const CXString_size = ccall( (:wci_size_CXString, libwci), Int, ())

typealias CXTypeKind Int32
type CXCursor
  data::Array{Uint8, 1}
  CXCursor() = new(Array(Uint8, CXCursor_size))
end

type CXType
  data::Array{Uint8,1}
  CXType() = new(Array(Uint8, CXType_size))
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

load("cindex_base.jl")
load("cindex_h.jl")

anymatch(first, args...) = any({==(first, a) for a in args})

cxtype(c::CXCursor) = getCursorType(c)
kind(c::CXCursor) = getCursorKind(c)
kind(c::CXType) = reinterpret(Int32, c.data[1:4])[1]
name(c::CXCursor) = getCursorDisplayName(c)
spelling(c::CXType) = getTypeKindSpelling(typekind(c))
spelling(c::CXCursor) = getCursorSpelling(c)

value(c::CXCursor) = begin 
  if kind(c) != CurKind.ENUMCONSTANTDECL
    error("Not a value cursor.")
  end
  t = cxtype(c)
  if anymatch(kind(t), 
    TypKind.INT, TypKind.LONG, TypKind.LONGLONG)
      return getEnumConstantDeclValue(c)
  end
  if anymatch(kind(t),
    TypKind.UINT, TypKind.ULONG, TypKind.ULONGLONG)
      return getEnumConstantDeclUnsignedValue(c)
  end
end

init_tu(hdrfile::Any) = init_tu(hdrfile, 0,0)
init_tu(hdrfile::Any, exclPCHDecl::Int, dispDiag::Int) = 
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
