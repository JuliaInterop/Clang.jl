using Clang
using Test

@testset "macro" begin
    ctx = DefaultContext()
    parse_header!(ctx, joinpath(@__DIR__, "c", "enum.h"))
    trans_unit = ctx.trans_units[1]
    root_cursor = getcursor(trans_unit)
    cursors = children(root_cursor)
    wrap!(ctx, cursors[1])
    io = IOBuffer()
    print_buffer(io, dump_to_buffer(ctx.common_buffer))
    @test String(take!(io)) == "\n@cenum(_foo{Int32},\n    BAR = 0,\n    BAZ = -9,\n)\n"
end
