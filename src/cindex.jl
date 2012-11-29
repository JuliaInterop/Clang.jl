module cindex
using Base
import Base.ref

libclang = dlopen("libclang")
libwci = dlopen("./libwrapcindex.so")
const CXCursor_size = ccall( dlsym(libwci, "wci_size_CXCursor"), Int, ())
const CXType_size = ccall( dlsym(libwci, "wci_size_CXType"), Int, ())
const CXString_size = ccall( dlsym(libwci, "wci_size_CXString"), Int, ())

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
  cached::Bool
  CXString() = new(Array(Uint8, CXString_size), "", false)
end

type CursorList
  ptr::Ptr{Void}
  size::Int
end

function to_string(cx::CXString)
  if (cx.string != None) return cx.str end
  p::Ptr{Uint8} = ccall(dlsym(libwci, "wci_get_cstring"), 
    Ptr{Uint8}, (Ptr{Void},), cx.data)
  cx.str = bytestring(p)
  cx.cached = true
  cx.str
end

load("cindex_base.jl")

init_tu(hdrfile::Any) = init_tu(hdrfile, 0,0)
init_tu(hdrfile::Any, exclPCHDecl::Int, dispDiag::Int) = 
  ccall(dlsym(libwci, "wci_initIndex"),
      Ptr{Void}, 
      (Ptr{Uint8}, Uint8, Uint8),
      convert(Ptr{Uint8}, hdrfile), exclPCHDecl, dispDiag)

dispose_tu() = ""

function tu_cursor(tu::Ptr{Void})
  cuout = CXCursor()
  ccall(dlsym(libwci, "wci_getTUCursor"),
    Void,
    (Ptr{Void}, Ptr{Uint8}), tu, cuout.data)
  return cuout
end

function cl_create()
  cl = CursorList(C_NULL,0)
  cl.ptr = ccall(dlsym(libwci, "wci_createCursorList"),
    Ptr{Void},
    () )
  return cl
end

function cl_dispose(cl::CursorList)
  ccall(dlsym(libwci, "wci_disposeCursorList"),
    None,
    (Ptr{Void},), cl.ptr)
  cl.ptr = C_NULL
  cl.length = 0
end

cl_size(cl::CursorList) = cl.size
cl_size(clptr::Ptr{Void}) =
  ccall(dlsym(libwci, "wci_sizeofCursorList"),
    Int,
    (Ptr{Void},), clptr)

function ref(cl::CursorList, clid::Int)
  if (clid < 1 || clid > cl.size) error("Index out of range or empty list") end 
  cu = CXCursor()
  ccall(dlsym(libwci, "wci_getCLCursor"),
    Void,
    (Ptr{Void}, Ptr{Void}, Int), cu.data, cl.ptr, clid-1)
  return cu
end

function children(cu::CXCursor)
  cl = cl_create() 
  ccall(dlsym(libwci, "wci_getChildren"),
    Ptr{Void},
      (Ptr{Void}, Ptr{Void}), cu.data, cl.ptr)
  cl.size = cl_size(cl.ptr)
  return cl
end

end # module
