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

const wc = wrap_c.init(;
                        OutputFile = "libLLVM_h.jl",
                        CommonFile = "libLLVM_common.jl",
                        ClangIncludes = clang_includes,
                        ClangArgs = clang_extraargs,
                        header_library = "LLVM-3.3")

function wrap_libLLVM(wc::WrapContext, wrap_hdrs)
    wrap_c.wrap_c_headers(wc, convert(Vector{ASCIIString}, wrap_hdrs))
end
