
if haskey(ENV, "TRAVIS")
    push!(Libdl.DL_LOAD_PATH, "/usr/lib/llvm-3.3/lib")
    const libwci = joinpath(dirname(@__FILE__),
                            "usr", "lib" , "libwrapclang.so")
else
  if VERSION > v"0.4-"
    const libwci = Base.Libdl.find_library(["libwrapclang",],[Pkg.dir("Clang", "deps", "usr", "lib"),])
  else
    const libwci = find_library(["libwrapclang",],[Pkg.dir("Clang", "deps", "usr", "lib"),])
  end
    @assert(libwci != "", "Failed to find required library libwrapclang. Try re-running the package script using Pkg.build(\"Clang\")")
end
