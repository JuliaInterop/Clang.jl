using Documenter, Clang

makedocs(
    modules = [Clang],
    clean = false,
    sitename = "Clang.jl",
    linkcheck = !("skiplinks" in ARGS),
    pages = [
        "Introduction" => "index.md",
    ],
)
# "Limitations" => "limitations.md",
deploydocs(
    repo = "github.com/ihnorton/Clang.jl.git",
    target = "build",
)
