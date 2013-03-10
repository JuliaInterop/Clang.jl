###############################################################################
# Julia wrapper generator using libclang from the LLVM project                #
###############################################################################

module wrap_c

using Clang.cindex
import cindex.TypKind, cindex.CurKind

### Wrappable type hierarchy

abstract CArg

type IntrinsicArg <: CArg
  cursor::cindex.CXCursor
end

type TypedefArg <: CArg
  cursor::cindex.CXCursor
end

type PtrArg <: CArg
  cursor::cindex.CXCursor
end

type StructArg <: CArg
  cursor::cindex.CXCursor
end

type FunctionArg <: CArg
  cursor::cindex.CXCursor
end

type EnumArg <: CArg
  cu_decl::cindex.CXCursor
  cu_typedef::Any
end

### Execution context for wrap_c

type WrapContext
  cindex::cindex.CXIndex
  typedef_prefix::ASCIIString
  clang_includes::Array{ASCIIString, 1}
  clang_args::Array{ASCIIString, 1}
  check_to_wrap::Function
#  wrap_cached::Set{ASCIIString}()
end

### These helpers will be written to the generated file
helper_macros = "
recurs_sym_type(ex::Any) = 
  (ex==None || typeof(ex)==Symbol || length(ex.args)==1) ? eval(ex) : Expr(ex.head, ex.args[1], recurs_sym_type(ex.args[2]))
macro c(ret_type, func, arg_types, lib)
  local _arg_types = Expr(:tuple, [recurs_sym_type(a) for a in arg_types.args]...)
  local _ret_type = recurs_sym_type(ret_type)
  local _args_in = Any[ symbol(string('a',x)) for x in 1:length(_arg_types.args) ]
  local _lib = eval(lib)
  quote
    \$(esc(func))(\$(_args_in...)) = ccall( (\$(string(func)), \$(Expr(:quote, _lib)) ), \$_ret_type, \$_arg_types, \$(_args_in...) )
  end
end

macro ctypedef(fake_t,real_t)
  real_t = recurs_sym_type(real_t)
  quote
    typealias \$fake_t \$real_t
  end
end"

__cache_wrapped = Set{ASCIIString}()

### libclang types to Julia types

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
  TypKind.CHAR_S      => Uint8,     # TODO check
  TypKind.SCHAR       => Uint8,     # TODO check
  TypKind.WCHAR       => Char,
  TypKind.SHORT       => Int16,
  TypKind.INT         => Int32,
  TypKind.LONG        => Int,
  TypKind.LONGLONG    => Int64,
  TypKind.FLOAT       => Float32,
  TypKind.DOUBLE      => Float64,
  TypKind.LONGDOUBLE  => Float64,   # TODO detect?
  TypKind.ENUM        => Int32,     # TODO arch check?
  TypKind.NULLPTR     => C_NULL
                                    # TypKind.UINT128 => TODO
  }

# Convert clang type to julia type
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
    # TODO: missing mappings should generate a warning
    return symbol( string( get(c_jl, typkind, :Void) ))
  end
end

### Build array of include definitions: ["-I", "incpath",...] plus extra args
function build_clang_args(includes, extras)
  reduce(vcat, [], vcat([["-I",x] for x in includes], extras))
end

### Retrieve function arguments for a given cursor
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

  if (has(__cache_wrapped, enum_name))
    return
  else
    add!(__cache_wrapped, enum_name)
  end

  println(ostrm, "# enum $enum_name")
  println(ostrm, "@ctypedef $enum_name Uint32")
  cl = cindex.children(argt.cu_decl)

  for i=1:cl.size
    cur_cu = cindex.ref(cl,i)
    cur_name = cindex.spelling(cur_cu)
    if (length(cur_name) < 1) continue end

    println(ostrm, "const ", cur_name, " = ", cindex.value(cur_cu))
  end
  cindex.cl_dispose(cl)
  println(ostrm, "# end")
end

function wrap(arg::FunctionArg, strm)
  @assert cu_kind(arg.cursor) == CurKind.FUNCTIONDECL

  cu_spelling = spelling(arg.cursor)
  add!(__cache_wrapped, name(arg.cursor))
  
  arg_types = function_args(arg.cursor)
  arg_list = tuple( [ctype_to_julia(x) for x in arg_types]... )
  ret_type = ctype_to_julia(cindex.return_type(arg.cursor))
  println(strm, "@c ", ret_type, " ", symbol(spelling(arg.cursor)), " ", arg_list, " shlib")
end

function wrap(arg::TypedefArg, strm)
  @assert cu_kind(arg.cursor) == CurKind.TYPEDEFDECL

  typedef_spelling = spelling(arg.cursor)
  add!(__cache_wrapped, typedef_spelling)

  cursor_type = cindex.cu_type(arg.cursor)
  td_type = cindex.resolve_type(cindex.getTypedefDeclUnderlyingType(arg.cursor))
  # initialize typealias in current context to avoid error TODO delete
  #:(typealias $typedef_spelling ctype_to_julia($td_type))
  
  println(strm, "@ctypedef ",  typedef_spelling, " ", ctype_to_julia(td_type) )
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
    # Skip wrapping cached item
    if (has(__cache_wrapped, cursor_name)) continue end

    towrap = None
    if (kind == CurKind.TYPEDEFDECL)
      towrap = TypedefArg(cursor)
    elseif (cu_kind(cursor) == CurKind.FUNCTIONDECL)
      towrap = FunctionArg(cursor)
    elseif (cu_kind(cursor) == CurKind.ENUMDECL)
      # TODO: need a better solution for this
      #  libclang does not provide xref between enum/typedef
      #  right now, if a typedef follows enum then we just assume it is
      #  for the enum declaration. this might not be true for anonymous enums.
      tdcu = topcl[i+1]
      tdcu = ((cindex.cu_kind(tdcu) == CurKind.TYPEDEFDECL) ? tdcu : None)
      towrap = EnumArg(cursor, tdcu)
    else
      continue
    end
    wrap(towrap, ostrm)
  end
  cindex.cl_dispose(topcl)
end

typealias StringsArray Array{ASCIIString,1}

### wrap_c_headers: main entry point
#   TODO: use dict for mapping from h file to wrapper file (or module?)
function wrap_c_headers(
    headers::StringsArray,          # header files to wrap
    clang_includes::StringsArray,   # clang include paths
    clang_extra_args::StringsArray, # additional {"-Arg", "value"} pairs for clang
    check_include::Function,        # called to determing inclusion status
    output_file::ASCIIString)       # eponymous

  for h in headers
    if !isfile(h)
      error(h, " cannot be found")
    end
  end
  for d in clang_includes
    if !isdir(d)
      error(d, " cannot be found")
    end
  end

  clang_args = build_clang_args(clang_includes, clang_extra_args)
  idx = cindex.idx_create(1,1)

  begin ostrm = open(output_file, "w")
    println(ostrm, helper_macros, "\n")
    for hfile in headers
      println(ostrm, "# header: $hfile")
      tunit = cindex.tu_parse(idx, hfile, clang_args)
      wrap_header(hfile, tunit, check_include, ostrm)
      println(ostrm)
    end
    close(ostrm)
  end
end

end # module wrap_c
