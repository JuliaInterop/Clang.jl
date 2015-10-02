if haskey(ENV, "TRAVIS")
    push!(Libdl.DL_LOAD_PATH, "/usr/lib/llvm-3.3/lib")
    const libwci = joinpath(dirname(@__FILE__),
                            "usr", "lib" , "libwrapclang.so")
else
    const libwci = Libdl.find_library(["libwrapclang",],
                                      [joinpath(dirname(@__FILE__),
                                                "usr", "lib")])
    @assert(libwci != "", "Failed to find required library libwrapclang. Try re-running the package script using Pkg.build(\"Clang\")")
end
