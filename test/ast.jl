using Clang
using Clang.LibClang.Clang_jll
using Test

@testset "Load AST" begin
    mktempdir() do dir
        header = joinpath(dir,"test.h")
        pch    = joinpath(dir,"test.pch")
        open(header, "w") do io
            write(io, "void foo();")
        end
        run(`$(clang()) -x c $header -emit-ast -o $pch`);
        index = Index()
        tu = load_ast(index, pch)
        @test tu |> getTranslationUnitCursor |> children |> only |> spelling == "foo"
    end
end
