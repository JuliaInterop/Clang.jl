using Clang
using Clang: parse_c_headers, wrap!, ExprUnit, dump_to_buffer, print_buffer
using DataStructures: OrderedDict
using Test

include("strip_line_numbers.jl")

@testset "typedef_pointer" begin
    transUnit = parse_header(joinpath(@__DIR__, "c", "typedef_pointer.h"))
    GC.@preserve transUnit begin
        # get root cursor
        top = getcursor(transUnit)
        cursors = children(top)

        FOO = cursors[2]
        @test clang2julia(underlying_type(FOO)) == :FOO

        FOOP = cursors[3]
        @test clang2julia(underlying_type(FOOP)) == :(Ptr{FOO})

        buffer = OrderedDict{Symbol,ExprUnit}()
        wrap!(FOOP, buffer)
        dumpBuffer = dump_to_buffer(buffer)
        io = IOBuffer()
        print_buffer(io, dumpBuffer)
        str = String(take!(io))
        @test str == "\nconst FOOP = Ptr{FOO}\n"
    end
end
