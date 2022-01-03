using CMake
using Clang.Generators

function build_libbitfield()
    @info "Building libbitfield. This will break if CMake fails to find a C compiler"
    src_dir = joinpath(@__DIR__, "bitfield")
    build_dir = joinpath(@__DIR__, "build/bitfield")

    config_cmd = `$cmake -B $build_dir -S $src_dir -D CMAKE_INSTALL_PREFIX=$build_dir`
    build_cmd = `$cmake --build $build_dir --config Debug`
    install_cmd = `$cmake --install $build_dir --config Debug`

    run(config_cmd)
    run(build_cmd)
    run(install_cmd)

    @info "Building libbitfield wrapper"
    args = get_default_args()
    headers = joinpath(build_dir, "include", "bitfield.h")
    options = load_options(joinpath(src_dir, "generate.toml"))
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
        # No tests yet
    end
end