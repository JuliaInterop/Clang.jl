using Clang
using Clang.LibClang
using Documenter

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
    ],
    warnonly=:missing_docs
)

deploydocs(; repo="github.com/JuliaInterop/Clang.jl.git")
