using Libdl

include("deps.jl")
println("hi")
push!(Libdl.DL_LOAD_PATH, readchomp(`$(LLVM_CONFIG) --libdir`))
println(Libdl.DL_LOAD_PATH)
println("xi")
Libdl.dlopen("libclang", Libdl.RTLD_DEEPBIND)
