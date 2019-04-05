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

@testset "struct_nested" begin
    # parse file
    trans_unit = parse_header(joinpath(@__DIR__, "c", "struct_nested.h"))
    ctx = DefaultContext()
    push!(ctx.trans_units, trans_unit)
    # get root cursor
    root_cursor = getcursor(trans_unit)
    cursors = children(root_cursor)
    # case 1
    wrap!(ctx, cursors[1])
    expr = :(struct ANONYMOUS1_union_in_struct
                x::Cstring
            end)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:ANONYMOUS1_union_in_struct].items[1] == expr
    expr = :(struct nested_struct
                union_in_struct::ANONYMOUS1_union_in_struct
                struct_in_struct::ANONYMOUS2_struct_in_struct
            end)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:nested_struct].items[1] == expr
    # case 2
    ctx.anonymous_counter = 0
    wrap!(ctx, cursors[3])
    expr = :(struct ANONYMOUS2_nest2
                x::Cint
            end)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:ANONYMOUS2_nest2].items[1] == expr
    expr = :(struct ANONYMOUS1_nest1
                nest2::ANONYMOUS2_nest2
                nest3::ANONYMOUS2_nest2
                s::UInt8
            end)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:ANONYMOUS1_nest1].items[1] == expr
    expr = :(struct nested_struct2
                nest1::ANONYMOUS1_nest1
            end)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:nested_struct2].items[1] == expr
end
