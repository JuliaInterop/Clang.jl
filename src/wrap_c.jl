JULIAHOME = EnvHash()["JULIAHOME"]
libLLVM_path = joinpath(JULIAHOME, "deps/llvm-3.2/include/llvm-c")
wrap_hdrs = map(x->joinpath(libLLVM_path, x), 
  {
  "BitWriter.h",
  "Target.h",
  "Initialization.h",
  "Disassembler.h",
  "Core.h",
  "TargetMachine.h",
  "Analysis.h",
  "ExecutionEngine.h",
  "Transforms/Vectorize.h",
  "Transforms/PassManagerBuilder.h",
  "Transforms/Scalar.h",
  "Transforms/IPO.h",
  "LinkTimeOptimizer.h",
  "Object.h",
  "EnhancedDisassembly.h",
  "BitReader.h"
  })

module wrap_c

using cindex
import cindex.CurKind, cindex.TypKind

c_jl = {
  TypKind.VOID => :Void,
  TypKind.BOOL => Bool,
  TypKind.CHAR_U => Uint8,
  TypKind.UCHAR => Uint8,
      #  TypKind.CHAR16 => TODO
      #  TypKind.CHAR32 => TODO
  TypKind.USHORT => Uint16,
  TypKind.UINT => Uint32,
  TypKind.ULONG => Uint,
  TypKind.ULONGLONG => Uint64,
      #  TypKind.UINT128 => bah
  TypKind.CHAR_S => Int8,
  TypKind.SCHAR => Int8,
  TypKind.WCHAR => Char,
  TypKind.SHORT => Int16,
  TypKind.INT => Int32,
  TypKind.LONG => Int,
  TypKind.LONGLONG => Int64,
  TypKind.FLOAT => Float32,
  TypKind.DOUBLE => Float64,
  TypKind.LONGDOUBLE => Float64, # TODO
  TypKind.NULLPTR => C_NULL
}

function ctype_to_julia(cutype::CXType)
  typkind = ty_kind(cxtype)
  # Special cases: TYPEDEF, POINTER
  if (typkind == TypKind.POINTER)
    ptr_ctype = cindex.getPointeeType(cutype)
    ptr_jltype = ctype_to_jl(ptr_ctype)
    return "Ptr{$ptr_jltype}"
  elseif (typkind == TypKind.TYPEDEF)
    return spelling( cindex.getTypeDeclaration(cutype) )
  else
    return get(c_jl, typkind, None)
  end
end

function build_clang_args(includes, extras)
  # Build array of include definitions: [...,"-I", "incpath",...]
  args = ASCIIString[]

  for hdr in includes
    push!(args, "-I")
    push!(args, hdr)
  end
  vcat(args, extras)
end

type CursorArgs

function cursor_args(cursor::CXCursor)
  @assert isa(cu_kind(cursor), CurKind.FUNCTIONDECL)

  cursor_type = cindex.cu_type(cursor)
  rtypes = []

  for arg_j = 0:cindex.getNumArgTypes(cursor_type)
        push!(rtypes,cindex.getArgType(cursor_type, uint32(arg_j)) )
  end
  return rtypes
end

end # Module wrap_c

module F ##############################
require("cindex")
using cindex
using wrap_c
import cindex.CurKind, cindex.TypKind
JULIAHOME=EnvHash()["JULIAHOME"]

out_path = "/cmn/git/libLLVM.jl"
libLLVM_path = joinpath(JULIAHOME, "deps/llvm-3.2/include")
clanginc_path = joinpath(JULIAHOME, "deps/llvm-3.2/Release/lib/clang/3.2/include")

clang_includes = map(x->joinpath(JULIAHOME, x), [
  "deps/llvm-3.2/build/Release/lib/clang/3.2/include",
  "deps/llvm-3.2/include",
  "deps/llvm-3.2/include",
  "deps/llvm-3.2/build/include/",
  "deps/llvm-3.2/include/"
  ])

clang_extraargs = ["-D", "__STDC_LIMIT_MACROS", "-D", "__STDC_CONSTANT_MACROS"]

function cursor_wrapping(cu::CXCursor)
    rtypes = Array(Any,0)
end


function pf(hdr)
  strm = open("out.txt", "w")
  #strm = STDOUT
  println(strm,"\n")

  clang_args = wrap_c.clang_args(clang_includes, clang_extraargs)
  println(clang_args)

  idx = cindex.idx_create(1,1)
  tu = cindex.tu_parse(idx, hdr, clang_args)
  topcu = cindex.getTranslationUnitCursor(tu)
  tcl = children(topcu)
  for i=1:tcl.size
    cu = tcl[i]
    if (cu_kind(cu) != CurKind.FUNCTIONDECL || cu_file(cu) != hdr) continue end
    arg_types = cursor_wrapping(tcl[i])
    ret_type = wrap_c.ctype_to_jl(cindex.return_type(cu))

    println(strm, "ccall( (:",spelling(cu), ",\"libLLVM\"),", ret_type, "(",
      [string(x,",") for x in arg_types], "),", ["a$x" for x in 1:length(arg_types)], ")")
  end
  close(strm)
end


end # module
