using Clang
using Clang.LibClang
using Documenter
import Changelog


Changelog.generate(
    Changelog.Documenter(),
    joinpath(@__DIR__, "src/changelog.md"),
    joinpath(@__DIR__, "src/generated_changelog.md"),
    repo="JuliaInterop/Clang.jl"
)

makedocs(;
    modules=[Clang, Clang.LibClang],
    repo=Remotes.GitHub("JuliaInterop", "Clang.jl"),
    sitename="Clang.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaInterop.github.io/Clang.jl",
        assets=String[],
        size_threshold=700000
    ),
    pages=[
        "Introduction" => "index.md",
        "Generator Tutorial" => "generator.md",
        "LibClang Tutorial" => "tutorial.md",
        "LibClang Wrapper API Reference" => "libclang.md",
        "Clang API Reference" => "api.md",
        "Changelog" => "generated_changelog.md"
    ],
    warnonly=:missing_docs
)

deploydocs(; repo="github.com/JuliaInterop/Clang.jl.git")
