using Clang
using Test

@testset "struct_enum_field" begin
    # parse file
    transUnit = parse_header(joinpath(@__DIR__, "c", "struct_enum_field.h"))
    GC.@preserve transUnit begin
        # get root cursor
        top = getcursor(transUnit)
        cursors = children(top)
        # enum
        enumCursor = cursors[1]
        @test name(enumCursor) == "Fruit"
        # struct
        structCursor = cursors[2]
        @test name(structCursor) == "Foo"
        # field
        structFields = children(structCursor)
        enumFieldCursor = structFields[1]
        intFieldCursor = structFields[2]
        arrayFieldCursor = structFields[3]
        @test clang2julia(enumFieldCursor) == :Fruit
        @test clang2julia(intFieldCursor) == :Cint
        @test clang2julia(arrayFieldCursor) == :(NTuple{3, Ptr{Cvoid}})
    end
end
