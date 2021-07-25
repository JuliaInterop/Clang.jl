using Clang
using Documenter

makedocs(;
    modules=[Clang],
    repo="https://github.com/JuliaInterop/Clang.jl/blob/{commit}{path}#L{line}",
    sitename="Clang.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaInterop.github.io/Clang.jl",
        assets=String[],
    ),
    pages=[
        "Introduction" => "index.md",
        "Generator Tutorial" => "generator.md",
        "LibClang Tutorial" => "tutorial.md",
        "API Reference" => "api.md",
    ],
)

deploydocs(; repo="github.com/JuliaInterop/Clang.jl.git")
