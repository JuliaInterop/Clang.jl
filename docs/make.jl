using Documenter, Clang

makedocs(
    modules = [Clang],
    clean = false,
    sitename = "Clang.jl",
    linkcheck = !("skiplinks" in ARGS),
    pages = [
        "Introduction" => "index.md",
        "Tutorial" => "tutorial.md",
        "API Reference" => "api.md",
    ],
)

deploydocs(
    repo = "github.com/JuliaInterop/Clang.jl.git",
    target = "build",
)
