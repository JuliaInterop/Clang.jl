using Clang.Generators
using Clang.LibClang.Clang_jll
using Test

include("rewriter.jl")

@testset "Generators" begin
    INCLUDE_DIR = joinpath(Clang_jll.artifact_dir, "include") |> normpath
    CLANG_C_DIR = joinpath(INCLUDE_DIR, "clang-c")

    headers = [joinpath(CLANG_C_DIR, header) for header in readdir(CLANG_C_DIR) if endswith(header, ".h")]
    options = load_options(joinpath(@__DIR__, "test.toml"))

    # add compiler flags
    args = ["-I$INCLUDE_DIR"]

    # add extra definition and corresponding translate method
    struct JuliaCtime_t <: AbstractJuliaSIT end

    add_definition(Dict(:time_t => JuliaCtime_t()))

    Generators.translate(::JuliaCtime_t, options=Dict()) = :Int

    # create context
    ctx = create_context(headers, args, options)

    # build without printing so we can do custom rewriting
    build!(ctx, BUILDSTAGE_NO_PRINTING)

    rewrite!(ctx.dag)

    # print
    @test_logs (:info, "Done!") match_mode=:any build!(ctx, BUILDSTAGE_PRINTING_ONLY)
end
