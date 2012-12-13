jl_bfr = memio()
c_bfr = memio()

abstract StructArg
abstract CXCursor <: StructArg
abstract CXType <: StructArg
abstract CXString <: StructArg

abstract EnumArg
abstract CXTypeKind <: EnumArg

c_types = {
  Int32 => "int",
  Uint32 => "unsigned int",
  Int64 => "long long",
  Uint64 => "unsigned long long",
  CXCursor => "char*",
  CXType => "char*",
  CXString => "char*",
  Void => "void",
  CXTypeKind => "CXTypeKind",
  }

symbols = {}

is_struct(x) = (super(x) == StructArg ? true : false)
is_enum(x) = (super(x) == EnumArg ? true : false)

type Arg
  cname::String
  ctype::String
end

function flatten(f...)
  ret = {}
  upret(x) = push(ret, x)
  flt(k) = (typeof(k) == Array{Any,1}) ? (for x in k upret(x) end) : upret(k)
  map(flt, f)
  return ret
end

function to_c(io::IOStream, rtype, fname, args)
  c_ret = is_struct(rtype) ? "void " : c_types[rtype]
  c_args = map(x->ref(c_types,x), is_struct(rtype) ? flatten(args,{rtype}) : args )
  
  named_args = { Arg("a$i", a) for (i,a) in enumerate(c_args) }
  declargs = join( [x.ctype*" "*x.cname*"," for x in named_args])[1:end-1]
  
  println(io, "$c_ret wci_$fname($declargs) {")

  cl_args = {}
  for (i,a) in enumerate(args)
    if is_struct(a)
      println(io, "  $a l$i = wci_get_$a(a$i);")
      push(cl_args, "l$i")
    else
      push(cl_args, "a$i")
    end
  end
  cl_fargs = join( ["$a," for a in cl_args])[1:end-1]
  
  if is_struct(rtype)
    println(io, "  $rtype rx = clang_$fname($cl_fargs);")
    println(io, "  wci_save_$rtype(rx,a", string(length(args)+1), ");")
  else
    println(io, "  return clang_$fname($cl_fargs);")
  end
  println(io, "}")
end

function to_jl(io::IOStream, rtype, fname, args)
  push(symbols, "wci_$fname")
  arg_ids = ["a"*string(i) for i=1:length(args)]
  f_args = join([string(arg_ids[i])*"::"string(args[i])*"," for i in 1:length(args)])

  println(io, "function $fname($f_args)")
  f_rtype = rtype
  ret_data = ""
  ret_ptr = ""
  if( is_struct(rtype) )
    println(io, "  c = $rtype()")
    ret_data = "c.data,"
    ret_ptr = "Ptr{Void}"
    f_rtype = "Void"
  end
  cc_atype(x) = (
    if (is_struct(x)) return "Ptr{Void}"
    else return x end)
  cc_rtype(x,y) = (
    if (is_struct(x)) return "$y.data"
    else return y end)
  ccall_args1 = join([string(i)*"," for i in map(cc_atype, args)])
  ccall_args2 = join([i*"," for i in map(cc_rtype, args, arg_ids)])
  println(io, "  ccall( (:wci_$fname, libwci), $f_rtype, ($ccall_args1$ret_ptr), $ccall_args2 $ret_data)")
  if(rtype == CXString)
    println(io, "  return get_string(c)")
  elseif ( is_struct(rtype) )
    println(io, "  return c")
  end
  println(io, "end")
end
to_jl(rtype, fname, args) = to_jl(stdout_stream, rtype, fname, args)

function write_output()
  flush(jl_bfr)
  flush(c_bfr)
  seek(jl_bfr,0)
  seek(c_bfr,0)
  
  # Write Julia wrapper functions
  f_base = open("../src/cindex_base.jl", "w")
  
  println(f_base, "libwci = \"./libwrapcindex.so\"")
  for line in EachLine(jl_bfr)
    print(f_base, line)
  end

  # Write C wrapper functions
  f_hdr = open("../src/wrapcindex.h", "w")
  for line in EachLine(c_bfr)
    print(f_hdr, line)
  end

  close(f_hdr)
  close(f_base)
end

macro cx(rtype, fname, args)
  r,f,a = eval(rtype),string(fname),eval(args)
  to_c(c_bfr, r, f, a) 
  to_jl(jl_bfr, r,f,a)
end

@cx CXType getCursorType {CXCursor}
@cx Int32 getCursorKind {CXCursor}
@cx Int32 isPODType {CXType}
@cx CXString getTypeKindSpelling {CXTypeKind}
@cx Uint32 CXXMethod_isStatic {CXCursor}
@cx CXCursor Cursor_getArgument {CXCursor, Int32}
@cx CXType getTypedefDeclUnderlyingType {CXCursor}
@cx CXCursor getCursorLexicalParent {CXCursor}
@cx CXType getEnumDeclIntegerType {CXCursor}
@cx Int64 getEnumConstantDeclValue {CXCursor}
@cx Uint64 getEnumConstantDeclUnsignedValue {CXCursor}
@cx Int32 Cursor_getNumArguments {CXCursor}
@cx CXString getCursorSpelling {CXCursor}
@cx CXString getCursorDisplayName {CXCursor}
@cx CXCursor getCursorReferenced {CXCursor}
@cx CXCursor getCursorDefinition {CXCursor}
@cx Uint32 isCursorDefinition {CXCursor}
@cx CXCursor getCanonicalCursor {CXCursor}
@cx Uint32 CXXMethod_isVirtual {CXCursor}
@cx Uint32 getTemplateCursorKind {CXCursor}
@cx CXCursor getSpecializedCursorTemplate {CXCursor}

write_output()
