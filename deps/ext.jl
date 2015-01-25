if haskey(ENV, "TRAVIS")
    push!(DL_LOAD_PATH, "/usr/lib/llvm-3.3/lib")
    const libwci = joinpath(Pkg.dir("Clang","deps","usr","lib"), "libwrapclang.so")
else
    const libwci = find_library(["libwrapclang",],[Pkg.dir("Clang", "deps", "usr", "lib"),])
    @assert(libwci != "", "Failed to find required library libwrapclang. Try re-running the package script using Pkg.build(\"Clang\")")
end

println("libwci: ", libwci)
println("DLLP: ", DL_LOAD_PATH)
run(`bash -c "ls /usr/lib/llvm-3.3/lib/libclang*"`)
