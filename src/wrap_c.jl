module wrap_c

using Clang.cindex
import cindex.TypKind, cindex.CurKind

abstract CArg
  abstract TypedefArg <: CArg
  abstract PtrArg <: CArg
  abstract StructArg <: CArg
  abstract FunctionArg <: CArg

type IntrinsicArg <: CArg
  cursor::cindex.CXCursor
end

type EnumArg <: CArg
  cu_decl::cindex.CXCursor
  cu_typedef::cindex.CXCursor
end

type WrapContext
  cindex::cindex.CXIndex
  typedef_prefix::ASCIIString
  clang_includes::Array{ASCIIString, 1}
  clang_args::Array{ASCIIString, 1}
  check_to_wrap::Function
end

helper_macros = "macro c(ret_type, func, arg_types, lib)
  local _ret_type = eval(ret_type)
  local _args_in = Any[ symbol(string('a',x)) for x in 1:length(arg_types.args) ]
  local _lib = @eval \$lib
  quote
    \$(esc(func))(\$(_args_in...)) = ccall( (\$(string(func)), \$(Expr(:quote, _lib)) ), \$(_ret_type), \$(arg_types), \$(_args_in...) )
  end
end"

__cache_wrapped = Set{ASCIIString}()

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
    return symbol( string( get(c_jl, typkind, :Void) ))
  end
end

function build_clang_args(includes, extras)
  # Build array of include definitions: ["-I", "incpath",...] plus extra args
  reduce(vcat, [], vcat([["-I",x] for x in includes], extras))
end

function function_args(cursor::CXCursor)
  @assert cu_kind(cursor) == CurKind.FUNCTIONDECL

  cursor_type = cindex.cu_type(cursor)
  [cindex.getArgType(cursor_type, uint32(arg_i)) for arg_i in 0:cindex.getNumArgTypes(cursor_type)-1]
end

function wrap(argt::EnumArg, ostrm)
  enum = cindex.name(argt.cu_decl)
  enum_typedef = if (typeof(argt.cu_typedef) == cindex.CXCursor)
      cindex.name(argt.cu_typedef)
    else
      ""
    end
  enum_name = 
    if (enum != "") enum
    elseif (enum_typedef != "") enum_typedef
    else "ANONYMOUS"
    end
  
  cl = cindex.children(argt.cu_decl)

  for i=1:cl.size
    cur_cu = cindex.ref(cl,i)
    cur_name = cindex.spelling(cur_cu)
    if (length(cur_name) < 1) continue end

    println(ostrm, "const ", cur_name, " = ", cindex.value(cur_cu))
  end
  cindex.cl_dispose(cl)
  println(ostrm, "# end")
  if enum != "" && enum_typedef != ""
      println(ostrm, "# const $(enum_typedef) == ENUM_$(enum)")
  end
  println(ostrm)
end

function wrap_function(strm, cursor)
  cu_spelling = spelling(cursor)
  arg_types = function_args(cursor)
  arg_list = tuple( [ctype_to_julia(x) for x in arg_types]... )
  ret_type = ctype_to_julia(cindex.return_type(cursor))
  println(strm, "@c ", ret_type, " ", symbol(spelling(cursor)), " ", arg_list, " shlib")
end

function wrap_typedef(strm, cursor)
  @assert cu_kind(cursor) == CurKind.TYPEDEFDECL

  typedef_spelling = spelling(cursor)
  cursor_type = cindex.cu_type(cursor)
  td_type = cindex.resolve_type(cindex.getTypedefDeclUnderlyingType(cursor))
  # initialize typealias in current context to avoid error
  :(typealias $typedef_spelling ctype_to_julia($td_type))
  
  println(strm, "typealias ",  typedef_spelling, " ", ctype_to_julia(td_type) )
end

function wrap_header(hfile, tunit, check_incl::Function, ostrm)
  topcu = cindex.getTranslationUnitCursor(tunit)
  topcl = children(topcu)
  
  for i=1:topcl.size
    cursor = topcl[i]
    cursor_name = name(cursor)
    kind = cu_kind(cursor)

    # Skip wrapping based on function supplied by client
    if (!check_incl(cu_file(cursor))) continue end

    cuhash = cindex.hashCursor(cursor)
    if has(__cursor_cache, cuhash) continue end

    if (kind == CurKind.TYPEDEFDECL)
      wrap_c.wrap_typedef(ostrm, cursor)
      add!(__cache_wrapped, cursor_name)
    elseif (cu_kind(cursor) == CurKind.FUNCTIONDECL)
      wrap_c.wrap_function(ostrm, cursor)
      add!(__cache_wrapped, cursor_name)
    elseif (cu_kind(cursor) == CurKind.ENUMDECL)
      # todo: need a better solution for this
      #  right now, if a typedef follows enum then assume it is
      #  for the enum declation.
      tdcu = topcl[i+1]
      tdcu = ((cindex.cu_kind(tdcu) == CurKind.TYPEDEFDECL) ? tdcu : None)
      wrap(EnumArg(cursor, tdcu), ostrm)
    else
      continue
    end
    # Should only get here after match in if() above
    # we cache the cursor hash to avoid re-wrapping
    add!(__cursor_cache, cuhash)
  end
  cindex.cl_dispose(topcl)
end

# todo: use dict for mapping from h file to wrapper file (or module?)
function wrap_c_headers(headers, clang_includes, clang_extra_args, check_incl::Function, out_file)
  clang_args = build_clang_args(clang_includes, clang_extra_args)
  println("clang args: ", clang_args)
  idx = cindex.idx_create(1,1)

  begin ostrm = open(out_file, "w")
    println(ostrm, helper_macros, "\n")
    for hfile in headers
      tunit = cindex.tu_parse(idx, hfile, clang_args)
      wrap_header(hfile, tunit, check_incl, ostrm)
    end
    close(ostrm)
  end
end

end # module wrap_c
