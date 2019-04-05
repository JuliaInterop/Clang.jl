using Clang
using Clang.LibClang
using Test

@testset "nested_union" begin
    trans_unit = parse_header(joinpath(@__DIR__, "c", "union.h"))
    ctx = DefaultContext()
    push!(ctx.trans_units, trans_unit)

    # get root cursor
    root_cursor = getcursor(trans_unit)
    cursors = children(root_cursor)
    # case 1
    wrap!(ctx, cursors[1])
    expr = :(struct ANONYMOUS1_bar
                str::Cstring
                x::Cint
                y::Cfloat
                z::Cdouble
            end)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:ANONYMOUS1_bar].items[1] == expr
    expr = :(struct nested_union
                bar::ANONYMOUS1_bar
            end)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:nested_union].items[1] == expr
end
