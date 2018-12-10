using Documenter, Clang

makedocs(
    modules = [Clang],
    clean = false,
    sitename = "Clang.jl",
    linkcheck = !("skiplinks" in ARGS),
    pages = [
        "Introduction" => "index.md",
        "Usage Guide" => "guide.md",
        #"LibClang" => "libclang.md",
        #"API Index" => "api.md",
    ],
)

deploydocs(
    repo = "github.com/ihnorton/Clang.jl.git",
    target = "build",
)
