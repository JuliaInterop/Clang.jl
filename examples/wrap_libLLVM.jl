JULIAHOME=EnvHash()["JULIAHOME"]
libLLVM_path = joinpath(JULIAHOME, "deps/llvm-3.2/include/llvm-c")
clanginc_path = joinpath(JULIAHOME, "deps/llvm-3.2/Release/lib/clang/3.2/include")

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

clang_includes = map(x->joinpath(JULIAHOME, x), [
  "deps/llvm-3.2/build/Release/lib/clang/3.2/include",
  "deps/llvm-3.2/include",
  "deps/llvm-3.2/include",
  "deps/llvm-3.2/build/include/",
  "deps/llvm-3.2/include/"
  ])
clang_extraargs = ["-D", "__STDC_LIMIT_MACROS", "-D", "__STDC_CONSTANT_MACROS"]

using Clang.cindex
using Clang.wrap_c
function wrap_libLLVM()
  wrap_c.wrap_c_headers(wrap_hdrs, clang_includes, clang_extraargs, "libLLVM_h.jl")
end
