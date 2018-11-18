using Clang
using Test

@testset "wrap_c" begin
    ctx = DefaultContext()
    parse_header!(ctx, joinpath(@__DIR__, "c", "cbasic.h"))
    root_cursor = getcursor(ctx.trans_units[1])
    func1 = search(root_cursor, "func1")[1]
    ctx.libname = "test"

    wrap!(ctx, func1)

    exc = :(
        function func1(a::Cint,b::Cdouble,c,d)
            ccall((:func1,test),Cint,(Cint,Cdouble,Ptr{Cdouble},Ptr{Cvoid}),a,b,c,d)
        end)

    Base.remove_linenums!(exc)

    @test ctx.api_buffer[1] == exc
end
