using Clang
using Clang.Generators
using Clang.LibClang.Clang_jll
using Test
using Clang.Generators: strip_comment_markers

include("rewriter.jl")

@testset "Generators" begin
    INCLUDE_DIR = normpath(Clang_jll.artifact_dir, "include")
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

@testset "Comments" begin
    @test strip_comment_markers("/* abc */") == ["abc "]
    @test strip_comment_markers("/** abc */") == ["abc "]
    @test strip_comment_markers("/*< abc */") == ["abc "]
    @test strip_comment_markers("/// hello") == ["hello"]
    @test strip_comment_markers("/**\n * line1\n * line2\n */") == ["line1", "line2"]
    @test strip_comment_markers("/*!\n * line1\n * line2\n */") == ["line1", "line2"]
    @test strip_comment_markers("    /// line1\n    /// line2") == ["line1", "line2"]
    @test strip_comment_markers("//! line1\n//! line2") == ["line1", "line2"]
    @test strip_comment_markers("//! line1") == ["line1"]
    @test strip_comment_markers("//< line1") == ["line1"]
end

@testset "Resolve dependency" begin
    args = get_default_args()
    headers = joinpath(@__DIR__, "include", "dependency.h")
    options = Dict("general" => Dict{String,Any}(
            "output_file_path" => joinpath(@__DIR__, "LibDependency.jl")))
    ctx = create_context(headers, args, options)
    build!(ctx)
    @test include("LibDependency.jl") isa Any
end

@testset "Issue 320" begin
    args = get_default_args()
    dir = joinpath(@__DIR__, "sys")
    push!(args, "-isystem$dir")
    headers = [joinpath(@__DIR__, "include", "test.h")]
    ctx = create_context(headers, args)
    @add_def stat
    @test build!(ctx, BUILDSTAGE_NO_PRINTING) isa Any
end

@testset "Escape anonymous name with var\"\"" begin
    args = get_default_args()
    headers = joinpath(@__DIR__, "include", "escape-with-var.h")
    options = Dict("general" => Dict{String,Any}(
            "output_file_path" => joinpath(@__DIR__, "LibEscapeWithVar.jl")))
    ctx = create_context(headers, args, options)
    build!(ctx)
    @test include("LibEscapeWithVar.jl") isa Any
end

@testset "Issue 307" begin
    args = get_default_args()
    dir = joinpath(@__DIR__, "sys")
    push!(args, "-isystem$dir")
    headers = joinpath(@__DIR__, "include", "struct-in-union.h")
    ctx = create_context(headers, args)
    @test build!(ctx, BUILDSTAGE_NO_PRINTING) isa Any

    headers = joinpath(@__DIR__, "include", "nested-struct.h")
    ctx = create_context(headers, args)
    @test build!(ctx, BUILDSTAGE_NO_PRINTING) isa Any

    headers = joinpath(@__DIR__, "include", "nested-declaration.h")
    ctx = create_context(headers, args)
    @test_broken try
        build!(ctx, BUILDSTAGE_NO_PRINTING) isa Any
        true
    catch
        false
    end
end

@testset "Issue 327" begin
    tu = parse_header(Index(), joinpath(@__DIR__, "include/void-type.h"))
    root = Clang.getTranslationUnitCursor(tu)
    func = children(root)[]
    ret_type = Clang.getCursorResultType(func)
    @test ret_type isa CLVoid
end

@testset "Issue 355" begin
    tu = parse_header(Index(), joinpath(@__DIR__, "include/return-funcptr.h"))
    root = Clang.getTranslationUnitCursor(tu)
    func = children(root)[3]
    @test length(get_function_args(func)) == 1
end

@testset "macros" begin
    ctx = create_context(joinpath(@__DIR__, "include/macro.h"), get_default_args())
    @test_logs (:info, "Done!") match_mode = :any build!(ctx)
end

@testset "#368" begin
    ctx = create_context(joinpath(@__DIR__, "include/union-in-struct.h"),
                         get_default_args())
    @test_logs (:info, "Done!") match_mode = :any build!(ctx)
    @test ctx.dag.nodes[end].id == :A
    @test ctx.dag.nodes[end].type isa Generators.StructLayout
end

@testset "Issue 376" begin
    ctx = create_context(joinpath(@__DIR__, "include/macro-dependency.h"), get_default_args())
    @test build!(ctx) isa Any
end
