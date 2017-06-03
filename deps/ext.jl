include("deps.jl")

push!(Libdl.DL_LOAD_PATH, readchomp(`$(LLVM_CONFIG) --libdir`))

Libdl.dlopen("libclang", Libdl.RTLD_DEEPBIND)

const libwci = joinpath(dirname(@__FILE__), "usr", "lib", "libwrapclang." * Libdl.dlext)
@assert(libwci != "", "Failed to find required library libwrapclang. Try re-running the package script using Pkg.build(\"Clang\")")
