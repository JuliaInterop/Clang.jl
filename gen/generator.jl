using Clang.wrap_c
using Clang.cindex
import Clang.llvm_config

const LLVM_VERSION = readchomp(`$llvm_config --version`)
const LLVM_LIBDIR  = readchomp(`$llvm_config --libdir`)
const LLVM_INCLUDE = joinpath(LLVM_LIBDIR, "clang", LLVM_VERSION, "include")

const CLANG_INCLUDE = joinpath(@__DIR__, "..", "deps", "usr", "clang+llvm-6.0.0-x86_64-apple-darwin", "include", "clang-c") |> normpath
const CLANG_HEADERS = [joinpath(CLANG_INCLUDE, cHeader) for cHeader in readdir(CLANG_INCLUDE) if endswith(cHeader, ".h")]

function rewriter(ex::Expr)
    if Meta.isexpr(ex, :struct)
        block = ex.args[3]
        isempty(block.args) && (typename = ex.args[2]; return :(const $typename = Ptr{Cvoid});)
    end
    Meta.isexpr(ex, :function) || return ex
    signature = ex.args[1]
    for i = 2:length(signature.args)
        func_arg = signature.args[i]
        if !(func_arg isa Symbol) && Meta.isexpr(func_arg, :(::))
            signature.args[i] = func_arg.args[1]
        end
    end
    return ex
end
rewriter(A::Array) = [rewriter(a) for a in A]
rewriter(arg) = arg

wrap_header(top_hdr::String, cursor_header::String) = (top_hdr == cursor_header)

wc = wrap_c.init(; headers = CLANG_HEADERS,
                   output_file = joinpath(@__DIR__, "..", "src", "cindex", "cindex_api.jl"),
                   common_file = joinpath(@__DIR__, "..", "src", "cindex", "cindex_common.jl"),
                   clang_includes = vcat(CLANG_INCLUDE, LLVM_INCLUDE),
                   clang_args = ["-I", joinpath(CLANG_INCLUDE, "..")],
                   header_wrapped = wrap_header,
                   header_library = x->"libclang",
                   clang_diagnostics = true,
                   rewriter = rewriter
                   )

run(wc)
