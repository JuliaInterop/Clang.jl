using CMake
using Clang.Generators

function build_libbitfield()
    @info "Building libbitfield. This will break if CMake fails to find a C compiler"
    src_dir = joinpath(@__DIR__, "bitfield")
    build_dir = joinpath(@__DIR__, "build", "bitfield")

    config_cmd = `$cmake -B $build_dir -S $src_dir`
    if Sys.WORD_SIZE == 32
        Sys.iswindows() && push!(config_cmd.exec, "-A", "win32")
        # Not actually working, so fail fast
        Sys.islinux() && error("Can not build libbitfield on 32-bit linux")
        Sys.islinux() && push!(config_cmd.exec, "-D", "CMAKE_C_FLAGS=-m32", "-D", "CMAKE_CXX_FLAGS=-m32")
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
        # Not constructible
        @test_broken bf = LibBitField.BitField()
        mirror = LibBitField.Mirror(10)
        bf = LibBitField.toBitfield(Ref(mirror))
        @test bf.a == 10
    end
end
