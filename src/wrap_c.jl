module wrap_c

using cindex
import cindex.CurKind, cindex.TypKind

helper_macros = L"macro c(ret_type, func, arg_types, lib)
  ret_type = eval(ret_type)
  args_in = Any[ symbol(string('a',x)) for x in 1:length(arg_types.args) ]
  quote
    $(esc(func))($(args_in...)) = ccall( ($(string(func)), $lib), $ret_type, $(arg_types), $(args_in...) )
  end
end

macro typedef(alias, real)
  real = eval(real)
  :( typealias alias eval(real) )
end
"


c_jl = {
  TypKind.VOID        => Void,
  TypKind.BOOL        => Bool,
  TypKind.CHAR_U      => Uint8,
  TypKind.UCHAR       => Uint8,
  TypKind.CHAR16      => Uint16,
  TypKind.CHAR32      => Uint32,
  TypKind.USHORT      => Uint16,
  TypKind.UINT        => Uint32,
  TypKind.ULONG       => Uint,
  TypKind.ULONGLONG   => Uint64,
  TypKind.CHAR_S      => Uint8,     # todo check
  TypKind.SCHAR       => Uint8,     # todo check
  TypKind.WCHAR       => Char,
  TypKind.SHORT       => Int16,
  TypKind.INT         => Int32,
  TypKind.LONG        => Int,
  TypKind.LONGLONG    => Int64,
  TypKind.FLOAT       => Float32,
  TypKind.DOUBLE      => Float64,
  TypKind.LONGDOUBLE  => Float64,   # todo detect?
  TypKind.ENUM        => Int32,     # todo arch check?
  TypKind.NULLPTR     => C_NULL
                                    # TypKind.UINT128 => todo
  }

function ctype_to_julia(cutype::CXType)
  typkind = ty_kind(cutype)
  # Special cases: TYPEDEF, POINTER
  if (typkind == TypKind.POINTER)
    ptr_ctype = cindex.getPointeeType(cutype)
    ptr_jltype = ctype_to_julia(ptr_ctype)
    return Ptr{ptr_jltype}
  elseif (typkind == TypKind.TYPEDEF)
    return symbol( string( spelling( cindex.getTypeDeclaration(cutype) ) ) )
  else
    return symbol( string( get(c_jl, typkind, :Void) ) )
  end
end

type WrapContext
  cxindex::cindex.CXIndex
  typedef_prefix::ASCIIString
  clang_includes::Array{ASCIIString, 1}
  clang_args::Array{ASCIIString, 1}
end

function build_clang_args(includes, extras)
  # Build array of include definitions: ["-I", "incpath",...] plus extra args
  reduce(vcat, [], vcat([["-I",x] for x in includes], extras))
end

function cursor_args(cursor::CXCursor)
  @assert cu_kind(cursor) == CurKind.FUNCTIONDECL

  cursor_type = cindex.cu_type(cursor)
  [cindex.getArgType(cursor_type, uint32(arg_i)) for arg_i in 0:cindex.getNumArgTypes(cursor_type)-1]
end

function wrap_function(strm, cursor)
  arg_types = cursor_args(cursor)
  arg_list = tuple( [ctype_to_julia(x) for x in arg_types]... )
  ret_type = ctype_to_julia(cindex.return_type(cursor))
  println(strm, "@c ", ret_type, " ", symbol(spelling(cursor)), " ", arg_list, " shlib")
end

# Avoid regenerating typedefs from earlier translation unit includes.
__cache_typedefs = Set{ASCIIString}()

function wrap_typedef(strm, cursor)
  @assert cu_kind(cursor) == CurKind.TYPEDEFDECL

  typedef_spelling = spelling(cursor)
  if (has(__cache_typedefs, typedef_spelling))
    # pass
  else
    cursor_type = cindex.cu_type(cursor)
    td_type = cindex.resolve_type(cindex.getTypedefDeclUnderlyingType(cursor))
    :(typealias $typedef_spelling ctype_to_julia($td_type))
    println(strm, "typealias ",  typedef_spelling, " ", ctype_to_julia(td_type) )
    add!(__cache_typedefs, typedef_spelling)
  end
end

function wrap_header(hfile, tunit, ostrm)
  topcu = cindex.getTranslationUnitCursor(tunit)
  tcl = children(topcu)
  
  for i=1:tcl.size
    cursor = tcl[i]
    kind = cu_kind(cursor)

    if (kind == CurKind.TYPEDEFDECL)
      wrap_c.wrap_typedef(ostrm, cursor)
    elseif (cu_kind(cursor) == CurKind.FUNCTIONDECL && cu_file(cursor) == hfile)
      wrap_c.wrap_function(ostrm, cursor)
    end
  end
  cindex.cl_dispose(tcl)
end

function wrap_c_headers(headers, clang_includes, clang_extra_args, out_file)
  clang_args = build_clang_args(clang_includes, clang_extra_args)
  println("clang args: ", clang_args)
  idx = cindex.idx_create(1,1)

  begin ostrm = open(out_file, "w")
    println(ostrm, helper_macros, "\n")
    for hfile in headers
      tunit = cindex.tu_parse(idx, hfile, clang_args)
      println("tunit: ", tunit)
      wrap_header(hfile, tunit, ostrm)
    end
    close(ostrm)
  end
end

end # module wrap_c
