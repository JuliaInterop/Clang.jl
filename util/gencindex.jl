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


fromeach(alen, fossas...) = begin
  f_l = map(length, fossas)
  if( !(min(f_l) == max(f_l) == alen) ) error("Inconsistent argument lengths") end
  r = {}
  for i in 1:length(fossas[1])
    push(r, { fossas[j][i] for j in 1:length(fossas)})
  end
  return r
end

is_struct(x) = (super(x) == StructArg ? true : false)
is_enum(x) = (super(x) == EnumArg ? true : false)

function to_c(io::IOStream, rtype, fname, args)
  f_atype(x) = begin
    if is_struct(x) return "char* "
    elseif is_enum(x) return "$x"
    else return c_types[x]
    end
  end

  comma = ( length(args)-1 > 0 ? "," : "" )
  
  if (is_struct(rtype))
    clf_types = map(x->f_atype(x),  vcat(args, {rtype}) )
    fargs = join(["$a a$i," for (i,a) in enumerate(clf_types)])
    println(io, "void wci_$fname($fargs) {")
    println(io, "  $rtype cx = wci_get_$rtype(a1);")
    vargs = join( {"a$i," for i in 2:length(args)} )[1:end-1]
    println(io, "  ", args[1], " rx = clang_$fname(cx$comma$vargs);")
    println(io, "  wci_save_$rtype(rx, a", string(length(args)+1), ");")
    println(io, "}")
  else
    clf_types = map(x->f_atype(x),  vcat({rtype}) )
    fargs = join(["$a a$i," for (i,a) in enumerate(clf_types)])[1:end-1]
    val_rtype = c_types[rtype]
    println(io, "$val_rtype wci_$fname($fargs) {")
    vargs = join( {"a$i," for i in 1:length(args)} )[1:end-1]
    println(io, "  ", val_rtype, " rx = clang_$fname($vargs);")
    println(io, "  return rx;")
    println(io, "}")
  

      
  end
#println("next")
#top_types = map(x->ref(c_types,x), vcat(args, {rtype}))
#  args = copy(largs)
#  f_rtype = c_types[rtype]
#  n_vargs = length(args)
#  lastarg = "a"*string(n_vargs+1)
#  if (typeof(rtype) == AbstractKind)
#    f_rtype = c_types[Void]
#    retvar = "wci_save_$rtype(rx, $lastarg);"
#  else
#    retvar = "return rx;"
#  end
#  if (typeof(args[1]) == AbstractKind)
#    in_t = args[1]
#  else
#    in_t = c_types[args[1]]
#  end
#  out_t = ""
#  if( length(args)>1 && typeof(args[2]) == AbstractKind)
#    out_t = ctypes[args[2]]
#  elseif(typeof(rtype) == AbstractKind)
#    out_t = rtype
#    push(args, out_t)
#  else
#    out_t = c_types[rtype]
#  end
#  f_args = join([string(c_types[args[i]])*" a"*string(i)*"," for i in 1:length(args)])[1:end-1]
#  c_args = ["a"*string(i) for i in length(args)]
#  va_args = join(["a"*string(i)*"," for i in 2:n_vargs])[1:end-1]
#  iarg = (typeof(args[1]) == AbstractKind ? "cx" : "a1")
#  if (length(va_args) > 0) va_args = strcat(", ", va_args) end
#  println(io, "$f_rtype wci_$fname($f_args) {")
#  if(typeof(args[1]) == AbstractKind)
#    println(io, "  $in_t cx = wci_get_$in_t(a1);")
#  end
#  println(io, "  $out_t rx = clang_$fname($iarg $va_args);")
#  println(io, "  $retvar")
#  println(io, "}")
  
end

function to_jl(io::IOStream, rtype, fname, args)
  push(symbols, "wci_$fname")
  arg_ids = ["a"*string(i) for i=1:length(args)]
  f_args = join([string(arg_ids[i])*"::"string(args[i])*"," for i in 1:length(args)])

  println(io, "function $fname($f_args)")
  f_rtype = rtype
  if(typeof(rtype) == AbstractKind)
    println(io, "  c = $rtype()")
    pass_data = "c.data,"
    f_rtype = "Void"
  end
  cc_atype(x) = (typeof(x) == AbstractKind ? "Ptr{Void}" : x)
  cc_rtype(x,y) = (typeof(x) == AbstractKind ? "$y.data" : y)
  ccall_args1 = join([string(i)*"," for i in map(cc_atype, args)])
  ccall_args2 = join([i*"," for i in map(cc_rtype, args, arg_ids)])
  println(io, "  ccall(wci_$fname, $f_rtype, ($ccall_args1), $ccall_args2)")
  if(typeof(rtype) == AbstractKind)
    println(io, "  return c")
  elseif(rtype == CXString)
    println(io, "  return get_string(c)")
  end
  println(io, "end")
end
to_jl(rtype, fname, args) = to_jl(stdout_stream, rtype, fname, args)

macro cx(rtype, fname, args)
  r,f,a = eval(rtype),string(fname),eval(args)
#  to_c(c_bfr, r, f, a) 
#  to_jl(jl_bfr, r,f,a)
  #println("to_c: ", fname)
  to_c(stdout_stream, r, f, a) 
#  to_jl(jl_bfr, r,f,a)
end

function write_output()
  flush(jl_bfr)
  flush(c_bfr)
  seek(jl_bfr,0)
  seek(c_bfr,0)
  
  f_base = open("../src/cindex_base.jl", "w")
  f_hdr = open("../src/wrapcindex.h", "w")
  for sym in symbols
    println(f_base, "$sym = dlsym(libwci, \"$sym\")")
  end
  for line in EachLine(jl_bfr)
    print(f_base, line)
  end
  for line in EachLine(c_bfr)
    print(f_hdr, line)
  end
  close(f_hdr)
  close(f_base)
end

@cx CXType getCursorType {CXCursor}
#@cx CXType getTypedefDeclUnderlyingType {CXCursor}
@cx Int32 isPODType {CXType}
@cx CXCursor getCursorLexicalParent {CXCursor}
#@cx CXType getEnumDeclIntegerType {CXCursor}
#@cx Int64 getEnumConstantDeclValue {CXCursor}
#@cx Uint64 getEnumConstantDeclUnsignedValue {CXCursor}
#@cx Int32 Cursor_getNumArguments {CXCursor}
@cx CXCursor Cursor_getArgument {CXCursor, Int32}
@cx CXString getTypeKindSpelling {CXTypeKind}
@cx CXString getCursorSpelling {CXCursor}
#@cx CXString getCursorDisplayName {CXCursor}
#@cx CXCursor getCursorReferenced {CXCursor}
#@cx CXCursor getCursorDefinition {CXCursor}
#@cx Uint32 isCursorDefinition {CXCursor}
#@cx CXCursor getCanonicalCursor {CXCursor}
#@cx Uint32 CXXMethod_isStatic {CXCursor}
#@cx Uint32 CXXMethod_isVirtual {CXCursor}
#@cx Uint32 getTemplateCursorKind {CXCursor}
@cx CXCursor getSpecializedCursorTemplate {CXCursor}


write_output()
