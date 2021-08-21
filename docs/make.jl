using Clang
using Clang.LibClang
using Documenter

makedocs(;
    modules=[Clang, Clang.LibClang],
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
        "LibClang Wrapper API Reference" => "libclang.md",
        "Clang API Reference" => "api.md",
    ],
)

deploydocs(; repo="github.com/JuliaInterop/Clang.jl.git")
