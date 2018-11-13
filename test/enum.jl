using Clang
using Test

@testset "macro" begin
    trans_unit = parse_header(joinpath(@__DIR__, "c", "enum.h"))
    root_cursor = getcursor(trans_unit)
    cursors = children(root_cursor)
    ctx = DefaultContext()
    ctx.trans_units["enum.h"] = trans_unit
    wrap!(ctx, cursors[1])
    io = IOBuffer()
    print_buffer(io, dump_to_buffer(ctx.common_buffer))
    @test String(take!(io)) == "\n@cenum(_foo{Int32},\n    BAR = 0,\n    BAZ = -9,\n)\n"
end
