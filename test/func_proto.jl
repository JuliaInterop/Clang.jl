using Clang
using Clang.LibClang
using Test

@testset "func_proto" begin
    trans_unit = parse_header(joinpath(@__DIR__, "c", "func_proto.h"))
    ctx = DefaultContext()
    ctx.options["is_function_strictly_typed"] = false
    push!(ctx.trans_units, trans_unit)

    # get root cursor
    root_cursor = getcursor(trans_unit)
    cursors = children(root_cursor)

    # func proto in a struct
    wrap!(ctx, cursors[1])
    expr = :(struct foo
                funcptr::Ptr{Cvoid}
                x::Cchar
            end)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:foo].items[1] == expr

    # func proto in a union
    wrap!(ctx, cursors[3])
    expr = :(struct foounion
                funcptr::Ptr{Cvoid}
            end)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:foounion].items[1] == expr

    # func proto in a func signature
    wrap!(ctx, cursors[5])
    expr = :(function baz(x, funcsig, z)
                ccall((:baz, libxxx), Cvoid, (Cstring, Ptr{Cvoid}, Cint), x, funcsig, z)
             end)
    Base.remove_linenums!(expr)
    @test ctx.api_buffer[1] == expr
end
