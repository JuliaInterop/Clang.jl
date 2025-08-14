using Clang

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
        fname = parse_header(index, header) do tu
            tu |> Clang.getTranslationUnitCursor |> children |>
                only |> file |> name |> normpath
        end
        @test fname == header |> normpath
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
        id_a = parse_header(index, a) do tu
            tu |> Clang.getTranslationUnitCursor |> children |> only |> file |> unique_id
        end
        id_b = parse_header(index, b) do tu
            tu |> Clang.getTranslationUnitCursor |> children |> only |> file |> unique_id
        end
        @test id_a === id_b
    end

end

end
