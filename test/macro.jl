using Clang
using Clang.LibClang
using Test

@testset "macro" begin
    trans_unit = parse_header(joinpath(@__DIR__, "c", "macro.h"),
                              flags = CXTranslationUnit_DetailedPreprocessingRecord)
    ctx = DefaultContext()
    push!(ctx.trans_units, trans_unit)
    root_cursor = getcursor(trans_unit)
    cursors = children(root_cursor)
    g_uri_xxx = search(cursors, x->name(x)=="G_URI_RESERVED_CHARS_SUBCOMPONENT_DELIMITERS")[1]
    wrap!(ctx, g_uri_xxx)
    expr = :(const G_URI_RESERVED_CHARS_SUBCOMPONENT_DELIMITERS = "!\$&'()*+,;=")
    @test ctx.common_buffer[:G_URI_RESERVED_CHARS_SUBCOMPONENT_DELIMITERS].items[1] == expr

    # test tokenize for macro instantiation
    func = search(cursors, x->kind(x)==CXCursor_FunctionDecl)[1]
    body = children(func)[1]
    op = children(body)[3]
    subop = children(op)[2]
    @test mapreduce(x->x.text, *, tokenize(subop)) == "FOO(foo,1,x)"
    wrap!(ctx, func)
    @test !isempty(ctx.api_buffer)

    # Issue #270 Support '==' in macros
    equals_macro = search(cursors, x->name(x)=="EQUALS_A_B")[1]
    wrap!(ctx, equals_macro)
    @test ctx.common_buffer[:EQUALS_A_B].items[1] == :(const EQUALS_A_B = A == B)
end
