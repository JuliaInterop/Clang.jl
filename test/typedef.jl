using Clang
using Clang.LibClang
using Test

@testset "typedef" begin
    trans_unit = parse_header(joinpath(@__DIR__, "c", "typedef.h"))
    ctx = DefaultContext()
    push!(ctx.trans_units, trans_unit)

    # get root cursor
    root_cursor = getcursor(trans_unit)
    cursors = children(root_cursor)
    # case 1
    volatile_array = cursors[1]
    volatile_type = underlying_type(volatile_array)
    @test kind(volatile_type) != CXType_Unexposed
    @test spelling(volatile_array) == "foo"
    # case 2
    char_array = cursors[2]
    char_array_type = underlying_type(char_array)
    @test kind(char_array_type) != CXType_Unexposed
    @test spelling(char_array) == "arrayType"
    # case 3
    struct_alias = cursors[4]
    struct_alias_type = underlying_type(struct_alias)
    @test kind(struct_alias_type) != CXType_Unexposed
    @test spelling(struct_alias) == "alias"
    # case 4
    node = cursors[5]
    node_type = type(node)
    @test canonical(node) == cursors[5]
    @test canonical(node_type) |> typedecl == cursors[7]
    wrap!(ctx, cursors[5])
    expr = :(struct Node
                data::Cint
                nextptr::Ptr{Node}
            end)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:Node].items[1] == expr

    node_typedef = cursors[6]
    node_typedef_type = underlying_type(node_typedef)
    @test kind(node_typedef_type) != CXType_Unexposed
    @test spelling(node_typedef) == "Node"
    # issue #213
    wrap!(ctx, cursors[9])
    expr = :(const bar = _bar)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:bar].items[1] == expr
    # issue #214
    wrap!(ctx, cursors[10])
    expr = :(const secretunion = Cvoid)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:secretunion].items[1] == expr
    wrap!(ctx, cursors[11])
    expr = :(const SECRET = secretunion)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:SECRET].items[1] == expr
end

@testset "typedef_anon" begin
    # parse file
    trans_unit = parse_header(joinpath(@__DIR__, "c", "typedef_anon.h"))
    ctx = DefaultContext()
    push!(ctx.trans_units, trans_unit)

    # get root cursor
    root_cursor = getcursor(trans_unit)
    cursors = children(root_cursor)
    # case 1
    anonymous_typedef_enum = cursors[1]
    @test name(anonymous_typedef_enum) == ""
    next_cursor = cursors[2]
    @test name(next_cursor) == "Fruit"
    @test kind(next_cursor) == CXCursor_TypedefDecl
    @test name(children(next_cursor)[1]) == ""
    @test is_typedef_anon(anonymous_typedef_enum, next_cursor) == true
    # case 2
    common_enum = cursors[3]
    @test name(common_enum) == "Banana"
    next_cursor = cursors[4]
    @test kind(next_cursor) == CXCursor_TypedefDecl
    @test name(children(next_cursor)[1]) != ""
    @test is_typedef_anon(common_enum, next_cursor) == false
    # case 3
    anonymous_typedef_struct = cursors[5]
    @test name(anonymous_typedef_struct) == ""
    next_cursor = cursors[6]
    @test name(next_cursor) == "Foo"
    @test kind(next_cursor) == CXCursor_TypedefDecl
    @test name(children(next_cursor)[1]) == ""
    @test is_typedef_anon(anonymous_typedef_struct, next_cursor) == true
    # case 4
    attribute_struct = cursors[7]
    @test name(attribute_struct) == ""
    next_cursor = cursors[8]
    @test name(next_cursor) == "char2"
    @test kind(next_cursor) == CXCursor_TypedefDecl
    @test name(children(next_cursor)[1]) == ""
    @test is_typedef_anon(attribute_struct, next_cursor) == true
    # case 5
    anonymous_typedef_union = cursors[9]
    @test name(anonymous_typedef_union) == ""
    next_cursor = cursors[10]
    @test name(next_cursor) == "handle"
    @test kind(next_cursor) == CXCursor_TypedefDecl
    @test name(children(next_cursor)[1]) == ""
    @test is_typedef_anon(anonymous_typedef_union, next_cursor) == true

    ctx.children = cursors
    ctx.children_index = 9
    wrap!(ctx, anonymous_typedef_union)
    expr = :(struct handle
                 ptr::Ptr{Cvoid}
             end)
    Base.remove_linenums!(expr)
    @test ctx.common_buffer[:handle].items[1] == expr
end

@testset "typedef_pointer" begin
    trans_unit = parse_header(joinpath(@__DIR__, "c", "typedef_pointer.h"))
    ctx = DefaultContext()
    push!(ctx.trans_units, trans_unit)

    # get root cursor
    root_cursor = getcursor(trans_unit)
    cursors = children(root_cursor)
    # case 1
    int_pointer = cursors[1]
    int_pointer_type = underlying_type(int_pointer)
    @test kind(int_pointer_type) != CXType_Unexposed
    @test spelling(int_pointer) == "intptr"
    # case 2
    function_pointer = cursors[2]
    function_pointer_type = underlying_type(function_pointer)
    @test kind(function_pointer_type) != CXType_Unexposed
    @test spelling(function_pointer) == "funcptr"
    # case 3
    FOO = cursors[4]
    @test clang2julia(underlying_type(FOO)) == :FOO

    FOOP = cursors[5]
    @test clang2julia(underlying_type(FOOP)) == :(Ptr{FOO})

    wrap!(ctx, cursors[6])
    expr = :(
        function test1(a::Cdouble,b::Cdouble,c::FOOP)
            ccall((:test1,libxxx),FOOP,(Cdouble,Cdouble,FOOP),a,b,c)
        end)
    Base.remove_linenums!(expr)
    @test ctx.api_buffer[1] == expr
end
