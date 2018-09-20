using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))

@static if Sys.isapple()
    # download binaries from LLVM
    bin_prefix = "http://releases.llvm.org/6.0.0"
    url = "$bin_prefix/clang+llvm-6.0.0-x86_64-apple-darwin.tar.xz"
    tarball_hash = "0ef8e99e9c9b262a53ab8f2821e2391d041615dd3f3ff36fdf5370916b0f4268"
    # install
    mac_prefix = Prefix(joinpath(prefix, "clang+llvm-6.0.0-x86_64-apple-darwin"))
    products = [
        LibraryProduct(mac_prefix, String["libclang"], :libclang),
        ExecutableProduct(mac_prefix, "llvm-config", :llvm_config),
    ]
    install(url, tarball_hash; prefix=prefix, force=true, verbose=verbose)
    # write out a deps.jl file that will contain mappings for our products
    write_deps_file(joinpath(@__DIR__, "deps.jl"), products)
end

@static if Sys.islinux()
    if !haskey(ENV, "LLVM_CONFIG")
        @info "LLVM_CONFIG is not defined, looking for system llvm-config"
        try
            llvmcfg = readchomp(`which llvm-config`)
            isfile(llvmcfg) && (ENV["LLVM_CONFIG"] = llvmcfg;)
        catch err
            error("no system llvm-config: $err")
        end
    end
    LLVM_CONFIG = ENV["LLVM_CONFIG"]
    llvm_libdir = readchomp(`$(LLVM_CONFIG) --libdir`)
    if !ispath(llvm_libdir)
        error("llvm-config returned non-existent libdir path: '$(llvm_libdir)")
    end

    const libclang = joinpath(llvm_libdir, "libclang.so")

    open(joinpath(@__DIR__, "deps.jl"), "w") do f
        println(f, """
            import Libdl
            const libclang = "$libclang"
            const LLVM_CONFIG = "$LLVM_CONFIG"
            function check_deps()
                global libclang
                if !isfile(libclang)
                    error("\$(libclang) does not exist, Please re-run Pkg.build(\\"Clang\\"), and restart Julia.")
                end
                hdl = Libdl.dlopen_e(libclang)
                if hdl == C_NULL
                    error("\$(libclang) cannot be opened, Please re-run Pkg.build(\\"Clang\\"), and restart Julia.")
                end
            end
        """)
    end
    @info "build success!"
end

@static if Sys.iswindows()
    import Libdl

    const LLVM_WINDOWS_DEFAULT = joinpath(homedir(), "..", "..", "Program Files", "LLVM", "bin") |> normpath
    if !haskey(ENV, "LLVM_WINDOWS")
        @info "LLVM_WINDOWS is not defined, searching default directory"
        lib = Libdl.find_library(["libclang"], [LLVM_WINDOWS_DEFAULT])
        if lib == ""
            error("couldn't find libclang.dll in the default directory $LLVM_WINDOWS_DEFAULT.\n
                 Please download and install LLVM from http://releases.llvm.org/download.html and then run Pkg.build(\"Clang\").")
        else
            ENV["LLVM_WINDOWS"] = LLVM_WINDOWS_DEFAULT
        end
    end
    const libclang = Libdl.dlpath(joinpath(ENV["LLVM_WINDOWS"], "libclang.dll")) |> x->replace(x, "\\"=>"\\\\")
    open(joinpath(@__DIR__, "deps.jl"), "w") do f
        println(f, """
            import Libdl
            const libclang = "$libclang"
            function check_deps()
                global libclang
                if !isfile(libclang)
                    error("\$(libclang) does not exist, Please re-run Pkg.build(\\"Clang\\"), and restart Julia.")
                end
                hdl = Libdl.dlopen_e(libclang)
                if hdl == C_NULL
                    error("\$(libclang) cannot be opened, Please re-run Pkg.build(\\"Clang\\"), and restart Julia.")
                end
            end
        """)
    end
end
