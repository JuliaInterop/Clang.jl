#
# Example script to wrap libLLVM (LLVM C interface)
#

using Clang.cindex
using Clang.wrap_c

LLVM_VER = "3.3"
LLVM_BUILD_TYPE="Release+Asserts"

JULIA_ROOT=abspath(JULIA_HOME, "../../")
LLVM_PATH=joinpath(JULIA_ROOT, "deps/llvm-$LLVM_VER")
libLLVM_path = joinpath(LLVM_PATH, "include/llvm-c")
clanginc_path = joinpath(LLVM_PATH, "build/$LLVM_BUILD_TYPE/lib/clang/3.3/include")

libllvm_hdrs = map(x->joinpath(libLLVM_path, x), 
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
    "BitReader.h"
    })

clang_includes = map(x::ASCIIString->joinpath(LLVM_PATH, x), [
    "build/$LLVM_BUILD_TYPE/lib/clang/3.3/include",
    "build/include/",
    "include"
    ])
clang_extraargs = ["-D", "__STDC_LIMIT_MACROS", "-D", "__STDC_CONSTANT_MACROS"]

const wc = wrap_c.init("libLLVM_h.jl", "libLLVM_common.jl", clang_includes,
                       clang_extraargs, (x...)->true, (x...)->true, (x...)->"libLLVM_h.jl")

function wrap_libLLVM(wc::WrapContext, wrap_hdrs::Vector{ASCIIString})
    wrap_c.wrap_c_headers(wc, wrap_hdrs)
end
