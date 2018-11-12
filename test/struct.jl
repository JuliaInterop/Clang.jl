using Clang
using Test

@testset "struct_enum_field" begin
    # parse file
    trans_unit = parse_header(joinpath(@__DIR__, "c", "struct_enum_field.h"))
    GC.@preserve trans_unit begin
        # get root cursor
        root_cursor = getcursor(trans_unit)
        cursors = children(root_cursor)
        # enum
        enum_cursor = cursors[1]
        @test name(enum_cursor) == "Fruit"
        # struct
        struct_cursor = cursors[2]
        @test name(struct_cursor) == "Foo"
        # field
        struct_fields = children(struct_cursor)
        enum_field_cursor = struct_fields[1]
        int_field_cursor = struct_fields[2]
        array_field_cursor = struct_fields[3]
        @test clang2julia(enum_field_cursor) == :Fruit
        @test clang2julia(int_field_cursor) == :Cint
        @test clang2julia(array_field_cursor) == :(NTuple{3, Ptr{Cvoid}})
    end
end
