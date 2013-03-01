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
  TypKind.VOID        => :Void,
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

function build_clang_args(includes, extras)
  # Build array of include definitions: ["-I", "incpath",...] plus extra args
  reduce(vcat, [], vcat([["-I",x] for x in includes], extras))
end

function cursor_args(cursor::CXCursor)
  @assert cu_kind(cursor) == CurKind.FUNCTIONDECL

  cursor_type = cindex.cu_type(cursor)
  [cindex.getArgType(cursor_type, uint32(arg_i)) for arg_i in 0:cindex.getNumArgTypes(cursor_type)-1]
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

function pf(hdr, strm)
  
  clang_args = wrap_c.build_clang_args(clang_includes, clang_extraargs)
  idx = cindex.idx_create(1,1)
  tunit = cindex.tu_parse(idx, hdr, clang_args)
  topcu = cindex.getTranslationUnitCursor(tunit)
  tcl = children(topcu)
  
  for i=1:tcl.size
    cursor = tcl[i]
    
    if (cu_kind(cursor) != CurKind.FUNCTIONDECL || cu_file(cursor) != hdr) continue end
    
    arg_types = wrap_c.cursor_args(cursor)
    arg_list = tuple( [wrap_c.ctype_to_julia(x) for x in arg_types]... )
    ret_type = wrap_c.ctype_to_julia(cindex.return_type(cursor))

    println(arg_list) 
    println(strm, "@c ", ret_type, " ", symbol(spelling(cursor)), " ", arg_list, " \"libLLVM\"")
  end

end


end # module
