using Clang
using Clang.LibClang
using Test

@testset "macro" begin
    trans_unit = parse_header(
        joinpath(@__DIR__, "c", "macro.h");
        flags=CXTranslationUnit_DetailedPreprocessingRecord,
    )
    ctx = DefaultContext()
    push!(ctx.trans_units, trans_unit)
    root_cursor = getcursor(trans_unit)
    cursors = children(root_cursor)

    # pure definition
    puredef = search(cursors, x->name(x)=="JULIA_CLANG_MACRO_TEST")[1]
    wrap!(ctx, puredef)
    expr = :(const JULIA_CLANG_MACRO_TEST = nothing)
    @test ctx.common_buffer[:JULIA_CLANG_MACRO_TEST].items[1] == expr

    # constant definition
    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_1")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_1 = 0)
    @test ctx.common_buffer[:CONSTANT_LITERALS_1].items[1] == expr

    issue206 = search(cursors, x->name(x)=="ISSUE_206")[1]
    wrap!(ctx, issue206)
    expr = :(const ISSUE_206 = "!\$&'()*+,;=")
    @test ctx.common_buffer[:ISSUE_206].items[1] == expr

    bracket = search(cursors, x->name(x)=="CONSTANT_LITERALS_BRACKET")[1]
    wrap!(ctx, bracket)
    expr = :(const CONSTANT_LITERALS_BRACKET = Cuint(0x10))
    @test ctx.common_buffer[:CONSTANT_LITERALS_BRACKET].items[1] == expr


    # # test tokenize for macro instantiation
    # func = search(cursors, x -> kind(x) == CXCursor_FunctionDecl)[1]
    # body = children(func)[1]
    # op = children(body)[3]
    # subop = children(op)[2]
    # @test mapreduce(x -> x.text, *, tokenize(subop)) == "FOO(foo,1,x)"
    # wrap!(ctx, func)
    # @test !isempty(ctx.api_buffer)

    # # Issue #270 Support '==' in macros
    # equals_macro = search(cursors, x -> name(x) == "EQUALS_A_B")[1]
    # wrap!(ctx, equals_macro)
    # @test ctx.common_buffer[:EQUALS_A_B].items[1] == :(const EQUALS_A_B = A == B)

    # # Issue #103
    # datatype_macros = search(cursors, x -> name(x) == "DATATYPE")[1]
    # wrap!(ctx, datatype_macros)
    # @test ctx.common_buffer[:DATATYPE].items[1] == :(const DATATYPE = int)
end


@testset "macro | literals" begin
    trans_unit = parse_header(
        joinpath(@__DIR__, "c", "macro.h");
        flags=CXTranslationUnit_DetailedPreprocessingRecord,
    )
    ctx = DefaultContext()
    push!(ctx.trans_units, trans_unit)
    root_cursor = getcursor(trans_unit)
    cursors = children(root_cursor)

    # constant definition
    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_1")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_1 = 0)
    @test ctx.common_buffer[:CONSTANT_LITERALS_1].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_2")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_2 = 1.0)
    @test ctx.common_buffer[:CONSTANT_LITERALS_2].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_3")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_3 = 0x10)
    @test ctx.common_buffer[:CONSTANT_LITERALS_3].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_4")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_4 = Cuint(0x10))
    @test ctx.common_buffer[:CONSTANT_LITERALS_4].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_5")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_5 = 0o123)
    @test ctx.common_buffer[:CONSTANT_LITERALS_5].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_6")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_6 = Cchar('x'))
    @test ctx.common_buffer[:CONSTANT_LITERALS_6].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_7")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_7 = "abcdefg")
    @test ctx.common_buffer[:CONSTANT_LITERALS_7].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_8")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_8 = Culonglong(1))
    @test ctx.common_buffer[:CONSTANT_LITERALS_8].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_9")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_9 = Culonglong(1))
    @test ctx.common_buffer[:CONSTANT_LITERALS_9].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_10")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_10 = Culonglong(1))
    @test ctx.common_buffer[:CONSTANT_LITERALS_10].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_11")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_11 = Culonglong(1))
    @test ctx.common_buffer[:CONSTANT_LITERALS_11].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_12")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_12 = Culonglong(1))
    @test ctx.common_buffer[:CONSTANT_LITERALS_12].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_13")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_13 = Culonglong(1))
    @test ctx.common_buffer[:CONSTANT_LITERALS_13].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_14")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_14 = Culonglong(1))
    @test ctx.common_buffer[:CONSTANT_LITERALS_14].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_15")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_15 = Culonglong(1))
    @test ctx.common_buffer[:CONSTANT_LITERALS_15].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_16")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_16 = Clonglong(2))
    @test ctx.common_buffer[:CONSTANT_LITERALS_16].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_17")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_17 = Clonglong(2))
    @test ctx.common_buffer[:CONSTANT_LITERALS_17].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_18")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_18 = Culong(3))
    @test ctx.common_buffer[:CONSTANT_LITERALS_18].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_19")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_19 = Culong(3))
    @test ctx.common_buffer[:CONSTANT_LITERALS_19].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_20")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_20 = Culong(3))
    @test ctx.common_buffer[:CONSTANT_LITERALS_20].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_21")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_21 = Culong(3))
    @test ctx.common_buffer[:CONSTANT_LITERALS_21].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_22")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_22 = Culong(3))
    @test ctx.common_buffer[:CONSTANT_LITERALS_22].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_23")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_23 = Culong(3))
    @test ctx.common_buffer[:CONSTANT_LITERALS_23].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_24")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_24 = Culong(3))
    @test ctx.common_buffer[:CONSTANT_LITERALS_24].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_25")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_25 = Cuint(4))
    @test ctx.common_buffer[:CONSTANT_LITERALS_25].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_26")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_26 = Cuint(4))
    @test ctx.common_buffer[:CONSTANT_LITERALS_26].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_27")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_27 = Clong(5))
    @test ctx.common_buffer[:CONSTANT_LITERALS_27].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_28")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_28 = Clong(5))
    @test ctx.common_buffer[:CONSTANT_LITERALS_28].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_29")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_29 = Float32(6))
    @test ctx.common_buffer[:CONSTANT_LITERALS_29].items[1] == expr

    consts = search(cursors, x->name(x)=="CONSTANT_LITERALS_30")[1]
    wrap!(ctx, consts)
    expr = :(const CONSTANT_LITERALS_30 = Float32(6))
    @test ctx.common_buffer[:CONSTANT_LITERALS_30].items[1] == expr
end
