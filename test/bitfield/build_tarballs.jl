# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Libdl

name = "libbitfield"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    DirectorySource(@__DIR__),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build
touch LICENSE
"""

# Only need to build for host platform since we are not publishing
platforms = [HostPlatform()]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libbitfield"], :libbitfield)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
