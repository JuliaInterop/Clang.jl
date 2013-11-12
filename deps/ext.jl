const libwci = find_library(["libwrapclang",],[Pkg.dir("Clang", "deps", "usr", "lib"),])
@assert(libwci != "", "Failed to find required library libwrapclang. Try re-running the package script using Pkg.build(\"Clang\")")
