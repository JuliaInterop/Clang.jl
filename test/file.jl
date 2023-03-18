using Clang
using Test

@testset "File" begin

@testset "Null File" begin
    @test name(CLFile(C_NULL))  == ""
end

@testset "Cursor filename" begin
    mktempdir() do dir
        header = joinpath(dir,"test.h")
        open(header, "w") do io
            write(io, "void foo();")
        end
        index = Index()
        tu = parse_header(index, header)
        @test tu |> Clang.getTranslationUnitCursor |> children |> only |> file |> name == header
    end
end

@testset "Unique ID" begin
    @test_throws AssertionError unique_id(CLFile(C_NULL)) 
    mktempdir() do dir
        header = joinpath(dir,"test.h")
        open(header, "w") do io
            println(io, "void foo();")
        end
        a = joinpath(dir,"a.h")
        open(a, "w") do io
            println(io, "#include \"test.h\"")
        end

        b = joinpath(dir,"b.h")
        open(b, "w") do io
            println(io, "#include \"test.h\"")
        end

        index = Index()
        tu_a = parse_header(index, a)
        tu_b = parse_header(index, b)
        cu_a = tu_a |> Clang.getTranslationUnitCursor |> children |> only 
        cu_b = tu_b |> Clang.getTranslationUnitCursor |> children |> only 
        @test (cu_a |> file |> unique_id) === (cu_b |> file |> unique_id) 
    end

end

end