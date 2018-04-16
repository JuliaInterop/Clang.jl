using Libdl

include("deps.jl")

push!(Libdl.DL_LOAD_PATH, readchomp(`$(LLVM_CONFIG) --libdir`))

Libdl.dlopen("libclang", Libdl.RTLD_DEEPBIND)
