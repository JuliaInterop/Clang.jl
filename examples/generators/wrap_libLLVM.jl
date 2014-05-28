#
# Example script to wrap libLLVM (LLVM C interface)
#

using Clang.cindex
using Clang.wrap_c

LLVM_VER = "3.3"
LLVM_BUILD_TYPE="Release+Asserts"

JULIA_ROOT=abspath(JULIA_HOME, "../../")
LLVM_PATH=joinpath(JULIA_ROOT, "deps/llvm-$LLVM_VER")
libLLVM_PATH = joinpath(LLVM_PATH, "include/llvm-c")
clanginc_path = joinpath(LLVM_PATH, "build/$LLVM_BUILD_TYPE/lib/clang/3.3/include")

libllvm_hdrs = map(x->joinpath(libLLVM_PATH, x),
                    split(readall(`find $libLLVM_PATH -name *.h`))
                  )

clang_includes = map(x::ASCIIString->joinpath(LLVM_PATH, x), [
    "build/$LLVM_BUILD_TYPE/lib/clang/3.3/include",
    "build/include/",
    "include"
    ])
clang_extraargs = ["-D", "__STDC_LIMIT_MACROS", "-D", "__STDC_CONSTANT_MACROS"]

const wc = wrap_c.init(;
                        output_file = "libLLVM_h.jl",
                        common_file = "libLLVM_common.jl",
                        clang_includes = clang_includes,
                        clang_args = clang_extraargs,
                        header_library = x->:libllvm,
                        header_wrapped = (x,y)->contains(y, "LLVM") )

function wrap_libLLVM(wc::WrapContext, wrap_hdrs)
    wrap_c.wrap_c_headers(wc, convert(Vector{ASCIIString}, wrap_hdrs))
end

if !isinteractive()
    wrap_libLLVM(wc, libllvm_hdrs)
end
