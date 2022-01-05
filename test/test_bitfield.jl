using CMake
using Clang.Generators

function build_libbitfield()
    @info "Building libbitfield. This will break if CMake fails to find a C compiler"
    src_dir = joinpath(@__DIR__, "bitfield")
    build_dir = joinpath(@__DIR__, "build", "bitfield")

    config_cmd = `$cmake -B $build_dir -S $src_dir`
    if Sys.WORD_SIZE == 32
        if Sys.iswindows()
            config_cmd = `$config_cmd -A win32`
        elseif Sys.islinux()
            config_cmd = `$config_cmd -D CMAKE_C_FLAGS=-march=native -D CMAKE_CXX_FLAGS=-march=native`
        end
    end
    build_cmd = `$cmake --build $build_dir --config Debug`
    install_cmd = `$cmake --install $build_dir --config Debug --prefix $build_dir`

    run(config_cmd)
    run(build_cmd)
    run(install_cmd)

    @info "Building libbitfield wrapper"
    args = get_default_args()
    headers = joinpath(build_dir, "include", "bitfield.h")
    options = load_options(joinpath(src_dir, "generate.toml"))
    lib_path = joinpath(build_dir, "bin", Sys.iswindows() ? "bitfield.dll" : "libbitfield")
    options["general"]["library_name"] = "\"$(escape_string(lib_path))\""
    options["general"]["output_file_path"] = joinpath(@__DIR__, "LibBitField.jl")
    ctx = create_context(headers, args, options)
    build!(ctx)
end



@testset "Bitfield" begin
    failed_to_build_bitfield = false
    try
        build_libbitfield()
    catch e
        failed_to_build_bitfield = true
        @info "Failed to build library libbitfield, skipping bitfield tests"
    end
    if !failed_to_build_bitfield
        include("LibBitField.jl")
        bf = Ref(LibBitField.BitField(NTuple{24,UInt8}(repeat([0], 24))))
        m = Ref(LibBitField.Mirror(10, 1.5, 1e6, -4, 7, 3))
        GC.@preserve bf m begin
            pbf = Ptr{LibBitField.BitField}(pointer_from_objref(bf))
            pm = Ptr{LibBitField.Mirror}(pointer_from_objref(m))
            pbf.a = 10
            pbf.b = 1.5
            pbf.c = 1e6
            pbf.d = -4
            pbf.e = 7
            pbf.f = 3
            @test LibBitField.toMirror(bf) == m[]
            @test LibBitField.toBitfield(m).a == bf[].a
            @test LibBitField.toBitfield(m).b == bf[].b
            @test LibBitField.toBitfield(m).c == bf[].c
            @test LibBitField.toBitfield(m).d == bf[].d
            @test LibBitField.toBitfield(m).e == bf[].e
            @test LibBitField.toBitfield(m).f == bf[].f
        end
    end
end
