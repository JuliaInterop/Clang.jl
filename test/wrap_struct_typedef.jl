using Clang
using Clang: parse_c_headers, print_buffer, dump_to_buffer, ExprUnit, wrap!
using DataStructures: OrderedDict
using Test

@testset "c struct" begin
    # parse file
    transUnit = parse_header(joinpath(@__DIR__, "c", "c_struct_typedef.h"))
    GC.@preserve transUnit begin
        # get root cursor
        top = getcursor(transUnit)

        buffer = OrderedDict{Symbol,ExprUnit}()
        for child in children(top)
            wrap!(child, buffer)
        end
        dumpBuffer = dump_to_buffer(buffer)
        io = IOBuffer()
        print_buffer(io, dumpBuffer)
        str = String(take!(io))
        @test str == "\nstruct Str\n    x::Cint\nend\n"
    end
end
