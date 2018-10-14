using Clang
using Clang.LibClang
using Test

@testset "typedef_anon" begin
    # parse file
    transUnit = parse_header(joinpath(@__DIR__, "c", "typedef_anon.h"))
    GC.@preserve transUnit begin
        # get root cursor
        top = getcursor(transUnit)
        cursors = children(top)
        # case 1
        anonymousTypedefEnum = cursors[1]
        @test name(anonymousTypedefEnum) == ""
        nextCursor = cursors[2]
        @test name(nextCursor) == "Fruit"
        @test kind(nextCursor) == CXCursor_TypedefDecl
        @test name(children(nextCursor)[1]) == ""
        @test is_typedef_anon(anonymousTypedefEnum, nextCursor) == true
        # case 2
        commonEnum = cursors[3]
        @test name(commonEnum) == "Banana"
        nextCursor = cursors[4]
        @test kind(nextCursor) == CXCursor_TypedefDecl
        @test name(children(nextCursor)[1]) != ""
        @test is_typedef_anon(commonEnum, nextCursor) == false
        # case 3
        anonymousTypedefStruct = cursors[5]
        @test name(anonymousTypedefStruct) == ""
        nextCursor = cursors[6]
        @test name(nextCursor) == "Foo"
        @test kind(nextCursor) == CXCursor_TypedefDecl
        @test name(children(nextCursor)[1]) == ""
        @test is_typedef_anon(anonymousTypedefStruct, nextCursor) == true
        # case 4
        attributeStruct = cursors[7]
        @test name(attributeStruct) == ""
        nextCursor = cursors[8]
        @test name(nextCursor) == "char2"
        @test kind(nextCursor) == CXCursor_TypedefDecl
        @test name(children(nextCursor)[1]) == ""
        @test is_typedef_anon(attributeStruct, nextCursor) == true
    end
end
