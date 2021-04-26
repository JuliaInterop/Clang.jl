using Clang.Generators
using Clang.LibClang.Clang_jll
using Test

include("rewriter.jl")

@testset "Generators" begin
    INCLUDE_DIR = joinpath(Clang_jll.artifact_dir, "include") |> normpath
    CLANG_C_DIR = joinpath(INCLUDE_DIR, "clang-c")

    options = load_options(joinpath(@__DIR__, "test.toml"))

    # add compiler flags
    args = get_default_args()
    push!(args, "-I$INCLUDE_DIR")

    # search top-level headers
    headers = detect_headers(CLANG_C_DIR, args)

    # add extra definition
    @add_def time_t AbstractJuliaSIT JuliaCtime_t Ctime_t

    # create context
    ctx = create_context(headers, args, options)

    # build without printing so we can do custom rewriting
    build!(ctx, BUILDSTAGE_NO_PRINTING)

    rewrite!(ctx.dag)

    # print
    @test_logs (:info, "Done!") match_mode=:any build!(ctx, BUILDSTAGE_PRINTING_ONLY)
end
