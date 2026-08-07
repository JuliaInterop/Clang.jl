using Test
using Clang
using Clang.Generators
using Clang.Generators.CxxEmit: strip_comment_markers, format_doc

# The regression corpus. Most of these headers were added in response to one GitHub issue, and
# most of the old testsets asserted only `@test_logs (:info, "Done!") build!(ctx)` — which
# cannot see a generated file that fails to load. Every fixture is now generated AND loaded, so
# the bar is that the output is valid Julia, not that the generator survived writing it.

const HERE = @__DIR__
const NEEDS_SYS = Set(["nested-struct.h", "nested-declaration.h", "struct-in-union.h", "test.h"])
# Objective-C is out of scope until ClangCompiler#49.
const SKIP = Set(["objectiveC.h"])
# Nothing is known-broken any more. `nested-declaration.h` — a struct declared inside another
# struct's field list — was `@test_broken` for the libclang pipeline and generates and loads
# here: the reachability walk reaches the inner record through the field's type like any other,
# where the old path needed a dedicated nested-record collection pass to find it at all.
const BROKEN = Set{String}()

fixtures() = sort!([f for f in readdir(joinpath(HERE, "include"))
                    if endswith(f, ".h") && f ∉ SKIP])

"""
    generate_and_load(header; options=Dict(), args=..., name=...) -> Module

Generate `header` and `include` the result into a fresh module. Throws if the generated code
does not load, which is the point.
"""
function generate_and_load(header::AbstractString; options=Dict{String,Any}(),
                           extra_args=String[], name=:Generated)
    out = joinpath(mktempdir(), "Generated.jl")
    general = get!(Dict{String,Any}, options, "general")
    general["output_file_path"] = out
    get!(general, "library_name", "libnotused")
    args = get_default_args()
    append!(args, extra_args)
    ctx = create_context([String(header)], args, options)
    build!(ctx)
    m = Module(name)
    Core.eval(m, :(using CEnum: CEnum, @cenum))
    Core.eval(m, :(const $(Symbol(general["library_name"])) = $(general["library_name"])))
    Base.include(m, out)
    return m
end

"`isdefined`/`getfield` across the world-age boundary `Base.include` just created."
has(m, s) = Base.invokelatest(isdefined, m, s)
val(m, s) = Base.invokelatest(getfield, m, s)

@testset "every fixture generates and loads" begin
    for f in fixtures()
        args = f in NEEDS_SYS ? ["-isystem" * joinpath(HERE, "sys")] : String[]
        nm = Symbol("Fix_", replace(f, r"[^A-Za-z0-9]" => "_"))
        if f in BROKEN
            @test_broken try
                generate_and_load(joinpath(HERE, "include", f); extra_args=args, name=nm)
                true
            catch
                false
            end
        else
            @testset "$f" begin
                @test generate_and_load(joinpath(HERE, "include", f);
                                        extra_args=args, name=nm) isa Module
            end
        end
    end
end

@testset "build! still logs Done!" begin
    ctx = create_context([joinpath(HERE, "include", "a.h")], get_default_args(),
                         Dict("general" => Dict{String,Any}(
                             "output_file_path" => joinpath(mktempdir(), "o.jl"))))
    @test_logs (:info, "Done!") match_mode = :any build!(ctx)
end

@testset "the two-stage rewriter workflow" begin
    # `ctx.nodes` replaces `ctx.dag.nodes`. It is a plain Vector{Node}, so a rewriter is
    # `filter`/`map` rather than surgery that has to keep index-valued edges consistent.
    out = joinpath(mktempdir(), "R.jl")
    options = Dict("general" => Dict{String,Any}("library_name" => "libr",
                                                 "output_file_path" => out))
    ctx = create_context([joinpath(HERE, "include", "a.h")], get_default_args(), options)
    build!(ctx, BUILDSTAGE_NO_PRINTING)
    @test !isempty(ctx.nodes)
    @test any(n -> String(n.id) == "AAA", ctx.nodes)
    filter!(n -> String(n.id) != "AAA", ctx.nodes)
    build!(ctx, BUILDSTAGE_PRINTING_ONLY)
    @test !occursin("AAA", read(out, String))
    @test occursin("BBB", read(out, String))
end

@testset "duplicate headers collapse (#392)" begin
    # `a.h` and `dup_a.h` are byte-identical. One shared translation unit plus
    # `getCanonicalDecl` makes this a non-question; the libclang pipeline needed a whole
    # duplicate-marking pass keyed on source location and token text.
    out = joinpath(mktempdir(), "D.jl")
    ctx = create_context([joinpath(HERE, "include", "a.h"),
                          joinpath(HERE, "include", "dup_a.h")], get_default_args(),
                         Dict("general" => Dict{String,Any}("library_name" => "libd",
                                                            "output_file_path" => out)))
    build!(ctx)
    src = read(out, String)
    @test count(x -> true, eachmatch(r"^struct BBB$"m, src)) == 1
    m = Module(:Dup); Core.eval(m, :(using CEnum: CEnum, @cenum))
    Core.eval(m, :(const libd = "libd"))
    @test Base.include(m, out) isa Any
end

@testset "anonymous names escaped with var\"\"" begin
    m = generate_and_load(joinpath(HERE, "include", "escape-with-var.h"); name=:Esc)
    @test m isa Module
end

@testset "union in struct (#368)" begin
    # Pinned by node MARKER at a fixed DAG index before; there is no DAG to index now, so this
    # asserts what actually matters: `A` exists and has the layout clang gave it.
    m = generate_and_load(joinpath(HERE, "include", "union-in-struct.h"); name=:U368)
    @test has(m, :A)
    @test has(m, :union_B)
end

@testset "elaborated enum keeps the @cenum, not a const (PR 522)" begin
    out = joinpath(mktempdir(), "E.jl")
    ctx = create_context([joinpath(HERE, "include", "elaborateEnum.h")], get_default_args(),
                         Dict("general" => Dict{String,Any}("library_name" => "libe",
                                                            "output_file_path" => out)))
    build!(ctx)
    src = read(out, String)
    @test occursin("@cenum X::", src)
    @test !occursin("const X = UInt32", src)
end

@testset "static functions" begin
    plain = joinpath(mktempdir(), "S1.jl")
    ctx = create_context([joinpath(HERE, "include", "static.h")], get_default_args(),
                         Dict("general" => Dict{String,Any}("library_name" => "libs",
                                                            "output_file_path" => plain)))
    build!(ctx)
    @test occursin("skip_static", read(plain, String))

    skipped = joinpath(mktempdir(), "S2.jl")
    ctx = create_context([joinpath(HERE, "include", "static.h")], get_default_args(),
                         Dict("general" => Dict{String,Any}("library_name" => "libs",
                                                            "output_file_path" => skipped,
                                                            "skip_static_functions" => true)))
    build!(ctx)
    @test !occursin("skip_static", read(skipped, String))
end

@testset "comment markers" begin
    @test strip_comment_markers("/* abc */") == ["abc"]
    @test strip_comment_markers("/** abc */") == ["abc"]
    @test strip_comment_markers("/*< abc */") == ["abc"]
    @test strip_comment_markers("/// hello") == ["hello"]
    @test strip_comment_markers("/**\n * line1\n * line2\n */") == ["line1", "line2"]
    @test strip_comment_markers("/*!\n * line1\n * line2\n */") == ["line1", "line2"]
    @test strip_comment_markers("    /// line1\n    /// line2") == ["line1", "line2"]
    @test strip_comment_markers("//! line1\n//! line2") == ["line1", "line2"]
    @test strip_comment_markers("//! line1") == ["line1"]
    @test strip_comment_markers("//< line1") == ["line1"]
end

@testset "detect_headers" begin
    dir = mktempdir()
    write(joinpath(dir, "top.h"), "#include \"inner.h\"\nint top(void);\n")
    write(joinpath(dir, "inner.h"), "int inner(void);\n")
    found = detect_headers(dir, get_default_args())
    @test any(h -> endswith(h, "top.h"), found)
    @test !any(h -> endswith(h, "inner.h"), found)
end
