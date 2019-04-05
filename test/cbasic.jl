using Clang
using Clang.LibClang
using Test

@testset "c basic" begin
    # parse file
    trans_unit = parse_header(joinpath(@__DIR__, "c", "cbasic.h"),
                              flags = CXTranslationUnit_DetailedPreprocessingRecord |
                                      CXTranslationUnit_SkipFunctionBodies)
    ctx = DefaultContext()
    push!(ctx.trans_units, trans_unit)
    # get root cursor
    root_cursor = getcursor(trans_unit)
    # search the first macro defination "#define CONST 1"
    cursorCONST = search(root_cursor, x->kind(x)==CXCursor_MacroDefinition && name(x) == "CONST")
    toksCONST = tokenize(cursorCONST[1])
    @test kind(toksCONST[1]) == CXToken_Identifier
    @test kind(toksCONST[2]) == CXToken_Literal
    @test toksCONST[2].text == "1"
    # search the second macro defination "#define CONSTADD CONST + 2"
    cursorCONSTADD = search(root_cursor, x->kind(x)==CXCursor_MacroDefinition && name(x) == "CONSTADD")
    toksCONSTADD = tokenize(cursorCONSTADD[1])
    @test toksCONSTADD[1].text == "CONSTADD"
    @test toksCONSTADD[2].text == "CONST"
    @test toksCONSTADD[3].text == "+"
    @test toksCONSTADD[4].text == "2"

    # function arguments
    func1 = search(root_cursor, "func1")[1]
    @test argnum(func1) == 4
    func1_args = function_args(func1) # TODO should return a structure or namedtuple
    @test map(spelling, func1_args) == ["a","b","c","d"]
    @test endswith(filename(func1), joinpath("c", "cbasic.h"))
    @test spelling(trans_unit) == filename(func1)

    # function constant array arguments should be converted to common Ptr
    func_arg = search(root_cursor, "func_constarr_arg")[1]
    wrap!(ctx, func_arg)
    expr = :(function func_constarr_arg(x)
                 ccall((:func_constarr_arg, libxxx), Cint, (Ptr{Cdouble},), x)
             end)
    Base.remove_linenums!(expr)
    @test ctx.api_buffer[1] == expr
end
