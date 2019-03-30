using Clang
using Test

# only test this on Linux since "time.h" is missing on other platforms by default.
if get(ENV, "TRAVIS_OS_NAME", "") == "linux"

# LIBCLANG_HEADERS are those headers to be wrapped.
const LIBCLANG_INCLUDE = joinpath(@__DIR__, "..", "deps", "usr", "include", "clang-c") |> normpath
const LIBCLANG_HEADERS = [joinpath(LIBCLANG_INCLUDE, header) for header in readdir(LIBCLANG_INCLUDE) if endswith(header, ".h")]

@testset "generator" begin
    api_path = joinpath(@__DIR__, "..", "gen", "libclang_api.jl") |> normpath
    common_path = joinpath(@__DIR__, "..", "gen", "libclang_common.jl") |> normpath
    test_api_path = joinpath(@__DIR__, "test_api.jl")
    test_common_path = joinpath(@__DIR__, "test_common.jl")
    wc = init(; headers = LIBCLANG_HEADERS,
                output_file = test_api_path,
                common_file = test_common_path,
                clang_includes = vcat(LIBCLANG_INCLUDE, CLANG_INCLUDE),
                clang_args = ["-I", joinpath(LIBCLANG_INCLUDE, "..")],
                header_wrapped = (root, current)->root == current,
                header_library = x->"libclang",
                clang_diagnostics = true)
    run(wc)
    @test read(test_api_path, String) == read(api_path, String)
    @test read(test_common_path, String) == read(common_path, String)
end

end
