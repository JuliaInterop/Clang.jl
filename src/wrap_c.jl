e##############################################################################
# Julia wrapper generator using libclang from the LLVM project                #
###############################################################################

module wrap_c
  version = v"0.0.0"

using Clang.cindex
import ..cindex.TypKind, ..cindex.CurKind

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
  typedef::Any
end

type FunctionArg <: CArg
  cursor::cindex.CXCursor
end

type EnumArg <: CArg
  cursor::cindex.CXCursor
  typedef::Any
end

reserved_words = ["type", "end"]

### Execution context for wrap_c
typealias StringsArray Array{ASCIIString,1}

# InternalOptions
type InternalOptions
  wrap_structs::Bool
end
InternalOptions() = InternalOptions(false)

# WrapContext object stores shared information about the wrapping session
type WrapContext
  out_path::ASCIIString
  common_file::ASCIIString
  clang_includes::StringsArray       # clang include paths
  clang_extra_args::StringsArray     # additional {"-Arg", "value"} pairs for clang
  header_wrapped::Function           # called to determine cursor inclusion status
  header_library::Function           # called to determine shared library for given header
  header_outfile::Function           # called to determine output file group for given header
  index::cindex.CXIndex
  common_stream
  cache_wrapped::Set{ASCIIString}
  output_streams::Dict{ASCIIString, IOStream}
  options::InternalOptions
end
WrapContext(op,cmn,incl,extra,hwrap,hlib,hout) = WrapContext(op,cmn,incl,extra,hwrap,hlib,hout,
                                                  cindex.idx_create(1,1),None,Set{ASCIIString}(),
                                                  Dict{ASCIIString,IOStream}(), InternalOptions())



### These helpers will be written to the generated file
helper_macros = "macro c(ret_type, func, arg_types, lib)
  local args_in = Any[ symbol(string('a',x)) for x in 1:length(arg_types.args) ]
  quote
    \$(esc(func))(\$(args_in...)) = ccall( (\$(string(func)), \$(Expr(:quote, lib)) ), \$ret_type, \$arg_types, \$(args_in...) )
  end
end

macro ctypedef(fake_t,real_t)
  quote
    typealias \$fake_t \$real_t
  end
end"

### libclang types to Julia types

c_jl = {
  TypKind.VOID        => Void,
  TypKind.BOOL        => Bool,
  TypKind.CHAR_U      => Uint8,
  TypKind.UCHAR       => Cuchar,
  TypKind.CHAR16      => Uint16,
  TypKind.CHAR32      => Uint32,
  TypKind.USHORT      => Uint16,
  TypKind.UINT        => Uint32,
  TypKind.ULONG       => Culong,
  TypKind.ULONGLONG   => Culonglong,
  TypKind.CHAR_S      => Uint8,     # TODO check
  TypKind.SCHAR       => Uint8,     # TODO check
  TypKind.WCHAR       => Char,
  TypKind.SHORT       => Int16,
  TypKind.INT         => Cint,
  TypKind.LONG        => Clong,
  TypKind.LONGLONG    => Clonglong,
  TypKind.FLOAT       => Cfloat,
  TypKind.DOUBLE      => Cdouble,
  TypKind.LONGDOUBLE  => Float64,   # TODO detect?
  TypKind.ENUM        => Cint,      # TODO arch check?
  TypKind.NULLPTR     => C_NULL,
                                    # TypKind.UINT128 => TODO
  "size_t"            => :Csize_t,
  "ptrdiff_t"         => :Cptrdiff_t
  
  }

# Convert clang type to julia type
function ctype_to_julia(cutype::CXType)
  typkind = ty_kind(cutype)
  # Special cases: TYPEDEF, POINTER
  if (typkind == TypKind.POINTER)
    ptr_ctype = cindex.getPointeeType(cutype)
    ptr_jltype = ctype_to_julia(ptr_ctype)
    return Ptr{ptr_jltype}
  elseif (typkind == TypKind.TYPEDEF || typkind == TypKind.RECORD)
    basename = string( spelling( cindex.getTypeDeclaration(cutype) ) )
    return symbol( get(c_jl, basename, basename))
  else
    # TODO: missing mappings should generate a warning
    return symbol( string( get(c_jl, typkind, :Void) ))
  end
end

### eliminate symbol from the final type representation
rep_type(t) = begin
  replace(string(t), ":", "")
end

### Tuple representation without quotes
rep_args(v) = begin    
  o = memio()
  print(o, "(")
  s = first = start(v)
  r = (!done(v,s))
  while r
    x,s = next(v,s)
    print(o, x)
    done(v,s) && break
    print(o, ", ")
  end
  r && (s == next(v,first)[2]) && print(o, ",")
  print(o, ")")
  seek(o, 0)
  readall(o)
end

### Build array of include definitions: ["-I", "incpath",...] plus extra args
function build_clang_args(includes, extras)
  reduce(vcat, [], vcat([["-I",x] for x in includes], extras))
end

### Retrieve function arguments for a given cursor
function function_args(cursor::CXCursor)
  #@assert cu_kind(cursor) == CurKind.FUNCTIONDECL

  cursor_type = cindex.cu_type(cursor)
  [cindex.getArgType(cursor_type, uint32(arg_i)) for arg_i in 0:cindex.getNumArgTypes(cursor_type)-1]
end

### Wrap enum. NOTE: we write this to wc.common_stream
function wrap(wc::WrapContext, argt::EnumArg, strm::IOStream)
  enum = cindex.name(argt.cursor)
  enum_typedef = if (typeof(argt.typedef) == cindex.CXCursor)
      cindex.name(argt.typedef)
    else
      ""
    end
  enum_name = 
    if (enum != "") enum
    elseif (enum_typedef != "") enum_typedef
    else "ANONYMOUS"
    end

  if (contains(wc.cache_wrapped, enum_name))
    return
  elseif(argt.typedef == None)
    add!(wc.cache_wrapped, enum_name)
  end

  println(wc.common_stream, "# enum $enum_name")
  cl = cindex.children(argt.cursor)

  for i=1:cl.size
    cur_cu = cindex.ref(cl,i)
    cur_name = cindex.spelling(cur_cu)
    if (length(cur_name) < 1) continue end

    println(wc.common_stream, "const ", cur_name, " = ", cindex.value(cur_cu))
  end
  cindex.cl_dispose(cl)
  println(wc.common_stream, "# end")
end

function wrap(wc::WrapContext, arg::StructArg, strm::IOStream)
  @assert cu_kind(arg.cursor) == CurKind.STRUCTDECL

  st = cindex.name(arg.cursor)
  st_typedef = if (typeof(arg.typedef) == cindex.CXCursor)
      cindex.name(arg.typedef)
    else
      ""
    end
  st_name = 
    if (st != "") st
    elseif (st_typedef != "") st_typedef
    else
      # TODO: come up with a better idea
      "ANONYMOUS_"*string(round(rand()*10000,5))
    end

  if (contains(wc.cache_wrapped, st_name))
    return
  else
    # Cache this regardless of typedef
    add!(wc.cache_wrapped, st_name)
  end

  cl = cindex.children(arg.cursor)
  if (cl.size == 0)
    # Probably a forward declaration.
    # TODO: check on this. any nesting that we need to handle?
    return
  end

  println(wc.common_stream, "type $st_name")

  for i=1:cl.size
    cur_cu = cindex.ref(cl,i)
    cur_name = cindex.spelling(cur_cu)

    if (cu_kind(cur_cu) != CurKind.FIELDDECL)
      warn("STRUCT: Skipping non-field declaration: $cur_name in: $st_name")
      continue
    end
    if (length(cur_name) < 1) 
      warn("STRUCT: Skipping unnamed struct member in: $st_name")
      continue 
    end
    if (contains(reserved_words, cur_name)) cur_name = "_"*cur_name end

    ty = resolve_type(cindex.cu_type(cur_cu))

    println(wc.common_stream, "  ", cur_name, "::", rep_type(ctype_to_julia(ty)))
  end
  cindex.cl_dispose(cl)
  println(wc.common_stream, "end")
end

function wrap(wc::WrapContext, arg::FunctionArg, strm::IOStream)
  @assert cu_kind(arg.cursor) == CurKind.FUNCTIONDECL

  cu_spelling = spelling(arg.cursor)
  add!(wc.cache_wrapped, name(arg.cursor))
  
  arg_types = function_args(arg.cursor)
  arg_list = tuple( [rep_type(ctype_to_julia(x)) for x in arg_types]... )
  ret_type = ctype_to_julia(cindex.return_type(arg.cursor))
  println(strm, "@c ", rep_type(ret_type), " ",
          symbol(spelling(arg.cursor)), " ",
          rep_args(arg_list), " ", wc.header_library(cu_file(arg.cursor)) )
end

function wrap(wc::WrapContext, arg::TypedefArg, strm::IOStream)
  @assert cu_kind(arg.cursor) == CurKind.TYPEDEFDECL

  typedef_spelling = spelling(arg.cursor)
  if(contains(wc.cache_wrapped, typedef_spelling))
    return
  else
    add!(wc.cache_wrapped, typedef_spelling)
  end

  cursor_type = cindex.cu_type(arg.cursor)
  td_type = cindex.resolve_type(cindex.getTypedefDeclUnderlyingType(arg.cursor))
  # initialize typealias in current context to avoid error TODO delete
  #:(typealias $typedef_spelling ctype_to_julia($td_type))
  
  println(wc.common_stream, "@ctypedef ",  typedef_spelling, " ", rep_type(ctype_to_julia(td_type)) )
end

function wrap_header(wc::WrapContext, topcu::CXCursor, top_hdr, ostrm::IOStream)
  println("WRAPPING HEADER: $top_hdr")
  
  topcl = children(topcu)

  # Loop over all of the child cursors and wrap them, if appropriate.
  for i=1:topcl.size
    cursor = topcl[i]
    cursor_hdr = cu_file(cursor)
    cursor_name = name(cursor)
    kind = cu_kind(cursor)

    # Heuristic to decide what should be wrapped:
    #  1. always wrap things in the current top header (ie not includes)
    #  2. everything else is from includes, wrap if:
    #     - the client wants it wc.header_wrapped == True
    #     - the item has not already been wrapped (ie not in wc.cache_wrapped)
    if (cursor_hdr == top_hdr)
      # pass
    elseif (!wc.header_wrapped(top_hdr, cu_file(cursor)) ||
            contains(wc.cache_wrapped, cursor_name) )
      continue
    end

    towrap = None
    if (kind == CurKind.TYPEDEFDECL)
      towrap = TypedefArg(cursor)
    elseif (cu_kind(cursor) == CurKind.FUNCTIONDECL)
      towrap = FunctionArg(cursor)
    elseif (cu_kind(cursor) == CurKind.ENUMDECL)
      # TODO: need a better solution for this
      #  libclang does not provide xref between each cursor for typedef'd enum
      #  right now, if a typedef follows enum then we just assume it is
      #  for the enum declaration. this might not be true for anonymous enums.
      
      tdcu = None
      if (i<topcl.size)
        tdcu = getindex(topcl, i+1)
        tdcu = ((cindex.cu_kind(tdcu) == CurKind.TYPEDEFDECL) ? tdcu : None)
      end
      towrap = EnumArg(cursor, tdcu)
    elseif (wc.options.wrap_structs && cu_kind(cursor) == CurKind.STRUCTDECL)
      tdcu = None
      if (i<topcl.size)
        tdcu = getindex(topcl, i+1)
        ((cindex.cu_kind(tdcu) == CurKind.TYPEDEFDECL) ? tdcu : None)
      end
      towrap = StructArg(cursor, tdcu)
    else
      continue
    end
    wrap(wc, towrap, ostrm)
  end
  cindex.cl_dispose(topcl)
end

function header_output_stream(wc::WrapContext, hfile)
  jloutfile = wc.header_outfile(hfile)
  if (_x = get(wc.output_streams, jloutfile, None)) != None
    return _x
  else
    strm = IOStream("")
    try strm = open(jloutfile, "w")
    catch error("Unable to create output: $jloutfile for header: $hfile") end
    wc.output_streams[jloutfile] = strm
  end
  return strm
end    

function sort_common_includes(strm::IOBuffer)
  # TODO: too many temporaries
  seek(strm,0)
  col1 = Dict{ASCIIString,Int}() 
  col2 = Dict{ASCIIString,Int}()
  tmp = Dict{Int,ASCIIString}()
  pos = Int[]
  fnl = ASCIIString[]

  for (i,ln) in enumerate(readlines(strm))
    tmp[i] = ln
    if (m = match(r"@ctypedef (\w+) (?:Ptr{)?(\w+)(?:}?)", ln)) != nothing
      col1[m.captures[1]] = i
      col2[m.captures[2]] = i
    end
  end
  for s in sort(collect(keys(col2)))
    if( (m = get(col1, s, None))!=None)
      push!(fnl, tmp[m])
      push!(pos, m)
    end
  end
 
  kj = setdiff(1:length(keys(tmp)), pos)
  vcat(fnl,[tmp[i] for i in kj])
end

### init: setup wrapping context 
function init(
    out_path::ASCIIString,
    common_file::ASCIIString,
    clang_includes::StringsArray,
    clang_extra_args::StringsArray,
    header_wrapped::Function,
    header_library::Function,
    header_outfile::Function)

  WrapContext(out_path,common_file,clang_includes,clang_extra_args,header_wrapped,header_library,header_outfile)
end

### wrap_c_headers: main entry point
#   TODO: use dict for mapping from h file to wrapper file (or module?)
function wrap_c_headers(
    wc::WrapContext,          # wrapping context
    headers::StringsArray)    # header files to wrap

  println(wc.clang_includes)

  # Check headers!
  for h in headers
    if !isfile(h)
      error(h, " cannot be found")
    end
  end
  for d in wc.clang_includes
    if !isdir(d)
      error(d, " cannot be found")
    end
  end

  clang_args = build_clang_args(wc.clang_includes, wc.clang_extra_args)

  # Output stream for common items: typedefs, enums, etc.
  wc.common_stream = IOBuffer()

  # Generate the wrappings
  try
    for hfile in headers
      ostrm = header_output_stream(wc, hfile)
      println(ostrm, "# Julia wrapper for header: $hfile")
      println(ostrm, "# Automatically generated using Clang.jl wrap_c, version $version\n")

      tunit = cindex.tu_parse(wc.index, hfile, clang_args,
                              cindex.TranslationUnit_Flags.None)
      topcu = cindex.getTranslationUnitCursor(tunit)
      wrap_header(wc, topcu, hfile, ostrm)

      println(ostrm)
    end 
  finally
    [close(os) for os in values(wc.output_streams)]
  end

  # Sort the common includes so that things aren't used out-of-order
  incl_lines = sort_common_includes(wc.common_stream)
  open(wc.common_file, "w") do strm
    # Write the helper macros
    println(strm, helper_macros, "\n")
    [print(strm, l) for l in incl_lines]
  end
  
  close(wc.common_stream)
end

###############################################################################

function get_top_cursor(wc::WrapContext, header)
  tunit = cindex.tu_parse(wc.index, header,
                  build_clang_args(wc.clang_includes, wc.clang_extra_args),
                  cindex.TranslationUnit_Flags.None)
  topcu = cindex.getTranslationUnitCursor(tunit)
end

end # module wrap_c
