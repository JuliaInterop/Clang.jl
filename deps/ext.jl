import Libdl

include("deps.jl")

llvm_libdir = readchomp(`$(LLVM_CONFIG) --libdir`)
if !ispath(llvm_libdir)
    error("llvm-config returned non-existent libdir path: '$(llvm_libdir)")
end

const libclang = joinpath(llvm_libdir, "libclang." * Libdl.dlext)

if Libdl.dlopen_e(libclang, Libdl.RTLD_DEEPBIND) == C_NULL
    error("Failed to open libclang library: $(libclang)")
end
