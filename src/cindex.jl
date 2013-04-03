module cindex

import Base.getindex

export cu_type, cu_kind, ty_kind, name, spelling, is_function, is_null,
  value, children, cu_file
export resolve_type, return_type
export tu_init, tu_cursor, tu_parse, tu_dispose
export CXType, CXCursor, CXString, CXTypeKind, CursorList

const libwci = :libwrapclang

# Type definitions for wrapped types
typealias CXIndex Ptr{Void}
typealias CXUnsavedFile Ptr{Void}
typealias CXFile Ptr{Void}
typealias CXTypeKind Int32
typealias CXCursorKind Int32
typealias CXTranslationUnit Ptr{Void}
const CXString_size = ccall( ("wci_size_CXString", libwci), Int, ())

# Work-around: ccall followed by composite_type in @eval gives error.
get_sz(sym) = @eval ccall( ($(string("wci_size_", sym)), :($(libwci))), Int, ())

# Generate container types
for st in Any[
    :CXSourceLocation, :CXSourceRange,
    :CXTUResourceUsageEntry, :CXTUResourceUsage, :CXCursor, :CXType,
    :CXToken ]
  sz_name = symbol(string(st,"_size"))
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

# These include statements must follow type definitions above.
include("cindex_base.jl")
include("cindex_h.jl")

# TODO: macro version should be more efficient.
anymatch(first, args...) = any({==(first, a) for a in args})

cu_type(c::CXCursor) = getCursorType(c)
cu_kind(c::CXCursor) = getCursorKind(c)
ty_kind(c::CXType) = reinterpret(Int32, c.data[1:4])[1]
name(c::CXCursor) = getCursorDisplayName(c)
spelling(c::CXType) = getTypeKindSpelling(ty_kind(c))
spelling(c::CXCursor) = getCursorSpelling(c)
is_function(c::CXCursor) = true # (cu_kind(c) == CurKind.FUNCTIONDECL || cu_kind(c) == 15)
is_function(t::CXType) = (ty_kind(t) == TypKind.FUNCTIONPROTO)
is_null(c::CXCursor) = (Cursor_isNull(c) != 0)

function resolve_type(rt::CXType)
  # This helper attempts to work around some limitations of the
  # current libclang API.
  if ty_kind(rt) == cindex.TypKind.UNEXPOSED
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

function return_type(c::CXCursor, resolve::Bool)
  if (!is_function(c))
    error("return_type Cursor argument must be a function")
  end
  if (resolve)
    return resolve_type( getCursorResultType(c) )
  else
    return getCursorResultType(c)
  end
end
return_type(c::CXCursor) = return_type(c, true)

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

tu_init(hdrfile::Any) = tu_init(hdrfile, 0, false)
function tu_init(hdrfile::Any, diagnostics, cpp::Bool)
  idx = idx_create(0,diagnostics)
  tu = tu_parse(idx, hdrfile, (cpp ? ["-x", "c++"] : [""]))
  return tu
end

tu_dispose(tu::CXTranslationUnit) = ccall( (:clang_disposeTranslationUnit, "libclang"), Void, (Ptr{Void},), tu)

tu_cursor(tu::CXTranslationUnit) = getTranslationUnitCursor(tu)

tu_parse(CXIndex, source_filename::ASCIIString) = tu_parse(CXIndex, source_filename, [""])
tu_parse(CXIndex, source_filename::ASCIIString, cl_args::Array{ASCIIString,1}) =
  tu_parse(CXIndex, source_filename, cl_args, length(cl_args), C_NULL, 0, 0)
tu_parse(CXIndex, source_filename::ASCIIString, 
         cl_args::Array{ASCIIString,1}, num_clargs,
         unsaved_files::CXUnsavedFile, num_unsaved_files,
         options) =
  ccall( (:clang_parseTranslationUnit, "libclang"),
    CXTranslationUnit,
    (Ptr{Void}, Ptr{Uint8}, Ptr{Ptr{Uint8}}, Uint32, Ptr{Void}, Uint32, Uint32), 
      CXIndex, source_filename,
      cl_args, num_clargs,
      unsaved_files, num_unsaved_files, options)

idx_create() = idx_create(0,0)
idx_create(excludeDeclsFromPCH::Int, displayDiagnostics::Int) =
  ccall( (:clang_createIndex, "libclang"),
    CXTranslationUnit,
    (Int32, Int32),
    excludeDeclsFromPCH, displayDiagnostics)

#Typedef{"Pointer CXFile"} clang_getFile(CXTranslationUnit, const char *)
getFile(tu::CXTranslationUnit, file::ASCIIString) = 
  ccall( (:clang_getFile, "libclang"),
    CXFile,
    (Ptr{Void}, Ptr{Uint8}), tu, file)

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

function getindex(cl::CursorList, clid::Int, default::UnionType)
  try
    getindex(cl, clid)
  catch
    return default
  end
end
function getindex(cl::CursorList, clid::Int)
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
