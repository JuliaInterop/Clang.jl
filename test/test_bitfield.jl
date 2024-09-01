import CMake_jll: cmake
using p7zip_jll, Tar
using Clang.Generators

function build_libbitfield_native()
    @info "Building libbitfield binary with native tools. This will break if CMake fails to find a C compiler"
    success = true
    try
        src_dir = joinpath(@__DIR__, "bitfield")
        build_dir = joinpath(@__DIR__, "build")

        config_cmd = `$(cmake()) -B $build_dir -S $src_dir`
        if Sys.WORD_SIZE == 32
            if Sys.iswindows()
                config_cmd = `$config_cmd -A win32`
            elseif Sys.islinux()
                config_cmd = `$config_cmd -D CMAKE_C_FLAGS=-march=native -D CMAKE_CXX_FLAGS=-march=native`
            end
        end
        build_cmd = `$(cmake()) --build $build_dir --config Debug`
        install_cmd = `$(cmake()) --install $build_dir --config Debug --prefix $build_dir`

        run(config_cmd)
        run(build_cmd)
        run(install_cmd)
    catch e
        @warn "Building libbitfield with native tools failed" exception=(e, catch_backtrace())
        success = false
    end
    return success
end


function build_libbitfield_binarybuilder()
    @info "Building libbitfield binary with BinaryBuilder."
    success = true
    try
        cd(@__DIR__) do
            # Delete any old products and rebuild
            rm("products"; force=true, recursive=true)
            run(`$(Base.julia_cmd()) --project bitfield/build_tarballs.jl`)

            # Note that we filter out the extra log file that's generated
            tarball_path = only(filter(!contains("-logs.v"), readdir("products")))
            dest = "build"
            rm(dest; recursive = true)
            Tar.extract(`$(p7zip_jll.p7zip()) x products/$tarball_path -so`, dest)
        end
    catch e
        @warn "Building libbitfield with BinaryBuilder failed" exception=(e, catch_backtrace())
        success = false
    end
    return success
end

function build_libbitfield()
    success = true
    try
        # Compile binary
        if !build_libbitfield_binarybuilder() && !build_libbitfield_native()
            error("Could not build libbitfield binary")
        end

        # Test the binary
        generate_wrappers(false)
    catch e
        @warn "Building libbitfield failed: $e"
        success = false
    end
    return success
end

function generate_wrappers(auto_deref::Bool)
    @info "Building libbitfield wrapper"
    args = get_default_args()
    headers = joinpath(@__DIR__, "build", "include", "bitfield.h")
    options = load_options(joinpath(@__DIR__, "bitfield", "generate.toml"))
    options["codegen"]["auto_field_dereference"] = auto_deref
    options["codegen"]["field_access_method_list"] = ["BitField"]

    lib_path = joinpath(@__DIR__, "build", "lib", Sys.iswindows() ? "bitfield.dll" : "libbitfield")
    options["general"]["library_name"] = "\"$(escape_string(lib_path))\""
    options["general"]["output_file_path"] = joinpath(@__DIR__, "LibBitField.jl")
    ctx = create_context(headers, args, options)
    build!(ctx)

    # Call a function to ensure build is successful
    anonmod = Module()
    Base.include(anonmod, "LibBitField.jl")
    m = Base.@invokelatest anonmod.LibBitField.Mirror(10, 1.5, 1e6, -4, 7, 3)
    Base.@invokelatest anonmod.LibBitField.toBitfield(Ref(m))

    return anonmod
end

@testset "Bitfield" begin
    if build_libbitfield()
        # Test the wrappers with and without auto-dereferencing. In the case of
        # bitfields they should have identical behaviour.
        for auto_deref in [false, true]
            anonmod = generate_wrappers(auto_deref)
            lib = anonmod.LibBitField

            bf = Ref(lib.BitField(Int8(10), 1.5, Int32(1e6), Int32(-4), Int32(7), UInt32(3)))
            m = Ref(lib.Mirror(10, 1.5, 1e6, -4, 7, 3))

            GC.@preserve bf m begin
                pbf = Ptr{lib.BitField}(pointer_from_objref(bf))
                pm = Ptr{lib.Mirror}(pointer_from_objref(m))
                @test lib.toMirror(bf) == m[]
                @test lib.toBitfield(m).a == bf[].a
                @test lib.toBitfield(m).b == bf[].b
                @test lib.toBitfield(m).c == bf[].c
                @test lib.toBitfield(m).d == bf[].d
                @test lib.toBitfield(m).e == bf[].e
                @test lib.toBitfield(m).f == bf[].f
            end
        end
    end
end
