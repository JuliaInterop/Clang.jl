using Clang: init, LLVM_INCLUDE

const CLANG_INCLUDE = joinpath(@__DIR__, "..", "deps", "usr", "include", "clang-c") |> normpath
const CLANG_HEADERS = [joinpath(CLANG_INCLUDE, cHeader) for cHeader in readdir(CLANG_INCLUDE) if endswith(cHeader, ".h")]

header_filter(top_hdr::String, cursor_header::String) = (top_hdr == cursor_header)

wc = init(; headers = CLANG_HEADERS,
                   output_file = joinpath(@__DIR__, "libclang_api.jl"),
                   common_file = joinpath(@__DIR__, "libclang_common.jl"),
                   clang_includes = vcat(CLANG_INCLUDE, LLVM_INCLUDE),
                   clang_args = ["-I", joinpath(CLANG_INCLUDE, "..")],
                   header_wrapped = header_filter,
                   header_library = x->"libclang",
                   clang_diagnostics = true,
                   )

run(wc)
