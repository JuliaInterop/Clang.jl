using Clang
using Clang: parse_c_headers, wrap!
using Test

include("strip_line_numbers.jl")

@testset "wrap_c" begin
    wc = init(;  headers = [joinpath(@__DIR__, "c", "cbasic.h")])
    hdr_tunits = parse_c_headers(wc)

    # test func1
    tunit = hdr_tunits[joinpath(@__DIR__, "c", "cbasic.h")]
    GC.@preserve tunit begin
        top = getcursor(tunit)
        func1 = search(top, "func1")[1]
        buffer = Any[]

        wrap!(func1, buffer, libname="test", isstrict=true)

        exc = :(
            function func1(a::Cint,b::Cdouble,c,d)
                ccall((:func1,test),Cint,(Cint,Cdouble,Ptr{Cdouble},Ptr{Cvoid}),a,b,c,d)
            end)

        strip_line_numbers!(exc)

        @test buffer[1] == exc
    end
end
