using Clang: init, LLVM_INCLUDE

const CLANG_INCLUDE = joinpath(@__DIR__, "..", "deps", "usr", "include", "clang-c") |> normpath
const CLANG_HEADERS = [joinpath(CLANG_INCLUDE, cHeader) for cHeader in readdir(CLANG_INCLUDE) if endswith(cHeader, ".h")]

function rewriter(ex::Expr)
    if Meta.isexpr(ex, :struct)
        block = ex.args[3]
        isempty(block.args) && (typename = ex.args[2]; return :(const $typename = Cvoid);)
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

header_filter(top_hdr::String, cursor_header::String) = (top_hdr == cursor_header)

wc = init(; headers = CLANG_HEADERS,
                   output_file = joinpath(@__DIR__, "libclang_api.jl"),
                   common_file = joinpath(@__DIR__, "libclang_common.jl"),
                   clang_includes = vcat(CLANG_INCLUDE, LLVM_INCLUDE),
                   clang_args = ["-I", joinpath(CLANG_INCLUDE, "..")],
                   header_wrapped = header_filter,
                   header_library = x->"libclang",
                   clang_diagnostics = true,
                   # rewriter = rewriter
                   )

run(wc)
