using Test
using Clang
using Clang.Generators

# Macro translation, tested against the bar that matters: the generated file must LOAD, and its
# constants must hold the values a C compiler gives.
#
# The pre-existing macro testset asserts only `@test_logs (:info, "Done!") build!(ctx)`, which
# cannot see either failure. `test/include/macro.h` generated a `const` referring to the
# undefined `CPL_STATIC_CAST` for a long time without the suite noticing.

"""
    generate_and_load(header; options=Dict(), name=:GeneratedMacros) -> Module

Run the generator over `header` and `include` the result into a fresh module. Throws if the
generated code does not load, which is the point.
"""
function generate_and_load(header; options=Dict{String,Any}(), name=:GeneratedMacros)
    dir = mktempdir()
    out = joinpath(dir, "Generated.jl")
    general = get!(Dict{String,Any}, options, "general")
    general["output_file_path"] = out
    general["library_name"] = "libnotused"
    ctx = create_context([header], get_default_args(), options)
    build!(ctx)
    m = Module(name)
    # The generated prologue emits `using CEnum`, and function wrappers name the library
    # binding; neither is exercised here, but both must resolve for the file to load.
    Core.eval(m, :(using CEnum: CEnum, @cenum))
    Core.eval(m, :(const libnotused = "libnotused"))
    Base.include(m, out)
    return m
end

@testset "Macros: generated output loads" begin
    # test/include/macro.h aggregates six historical macro regressions. Two of its macros call
    # the undefined `CPL_STATIC_CAST`; emitting them produced a file that raised UndefVarError
    # on load. The generator now declines to emit a macro naming something it will not define.
    m = generate_and_load(joinpath(@__DIR__, "include", "macro.h"))
    @test m isa Module
    @test !isdefined(m, :GINTBIG_MAX)      # skipped, not emitted-and-broken
    @test !isdefined(m, :GUINTBIG_MAX)
    # the macros that DO translate are still there and still right
    @test getfield(m, :S) == "abcdef"
    @test getfield(m, :EL) == "DCAP_NONSPATIAL"
end

@testset "Macros: integer literal typing" begin
    # Issue #515. C11 6.4.4.1p5: a literal's type is the first in the suffix's list that can
    # represent the value, so 0x80000001L is `long` on LP64 and `unsigned long` where long is
    # 32-bit. Whatever type is chosen, the VALUE must survive.
    m = generate_and_load(joinpath(@__DIR__, "include", "large-integer-literals.h"))
    @test getfield(m, :TEST) == 0x80000001
    @test getfield(m, :TEST_2) == 2147483649
    @test getfield(m, :TEST_SIGNED) == 1
    @test getfield(m, :TEST_SIGNED_2) == 2147483646
end

@testset "Macros: casts (known broken)" begin
    # Issues #510 and #382. Both currently emit a `const` that throws at LOAD time:
    #   ((INT) 4+1)              -> (INT(4))(1)                  MethodError
    #   ((MPI_Datatype)0x8...)   -> MPI_Datatype(0x8c000000)     InexactError
    # The values below are what a C compiler gives, verified with cc:
    #   (int)4+1                 == 5
    #   (int)0x8c000000          == -1946157056
    # These are @test_broken deliberately: they record the open defect and will report an
    # "Unexpected Pass" the moment the AST-based translator lands (see MACRO-HANDLING.md).
    dir = mktempdir()
    header = joinpath(dir, "casts.h")
    write(header, """
    typedef int INT;
    typedef int MPI_Datatype;
    #define FIVE          ((INT) 4+1)
    #define MPI_FLOAT_INT ((MPI_Datatype)0x8c000000)
    """)
    loaded = try
        generate_and_load(header; name=:GeneratedCasts)
    catch
        nothing
    end
    @test_broken loaded !== nothing
    if loaded !== nothing
        @test_broken getfield(loaded, :FIVE) == 5
        @test_broken getfield(loaded, :MPI_FLOAT_INT) == -1946157056
    end
end
