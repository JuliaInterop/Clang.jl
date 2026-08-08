using Test
using Clang
using Clang.Generators
using CMake_jll

# The cross-compilation shard machinery is ClangCompiler's `JLLEnvs`, an internal module of that
# package. Clang.jl does not re-export it as its own API; it exposes a small trampoline instead,
# so downstream generator scripts depend on names this package promises. These tests exercise
# the trampoline — testing `ClangCompiler.JLLEnvs` directly would pass while the public surface
# was broken.

@testset "supported targets" begin
    @test !isempty(JLL_ENV_TRIPLES)
    @test eltype(JLL_ENV_TRIPLES) === String
    # The triples a multi-platform generator script is expected to loop over.
    for t in ("aarch64-apple-darwin20", "x86_64-linux-gnu", "x86_64-w64-mingw32")
        @test t in JLL_ENV_TRIPLES
    end
end

@testset "get_default_args" begin
    # The HOST triple only. `get_default_args` calls `artifact_path`, which materialises the
    # shard — looping over all 14 would download a GCC bootstrap per triple on a cold runner.
    # Shard-table coverage for the rest is the `get_environment_info` testset below, which
    # reads Artifacts.toml and downloads nothing.
    args = get_default_args()
    @test any(startswith("-isystem"), args)
    @test count(startswith("--target="), args) == 1
    # A triple that silently produced neither would generate against the host's headers.
    @test !any(startswith("-nostdinc"), args)   # the C path must not strip system includes
end

@testset "every supported triple resolves a shard" begin
    # Reads the shard table; no artifact is materialised, so this stays cheap on CI.
    # Through `Clang.JLLEnvs` rather than a trampoline: the `version` argument defaults to
    # GCC_MIN_VER and that is WRONG for targets whose only shard is newer, so this is not a
    # contract Clang.jl promises. darwin20 is exactly that case and is passed its own version.
    J = Clang.JLLEnvs
    for t in JLL_ENV_TRIPLES
        v = startswith(t, "aarch64-apple-darwin") ? v"11.0.0-iains" : J.GCC_MIN_VER
        @test J.get_environment_info(t, v) !== nothing
    end
end

@testset "get_pkg_include_dir" begin
    # The point of this over `jll.artifact_dir`: it resolves the artifact for a REQUESTED
    # target, which is what per-platform generation needs.
    d = get_pkg_include_dir(CMake_jll, "x86_64-linux-gnu")
    @test d isa String
    # NOT asserted to exist: a JLL may ship an artifact with no `include/`, and CMake_jll's
    # linux build is one. The contract is "where the headers would be", not "they are there".
    @test isempty(d) || endswith(d, "include")
    # An unsupported triple fails at the boundary with a message naming the valid set, rather
    # than as `Unknown OS` from inside a platform parse.
    @test_throws ArgumentError get_pkg_include_dir(CMake_jll, "not-a-real-triple")
end

@testset "darwin __triplet backwards compatibility" begin
    # `aarch64-apple-darwin` must still resolve to the darwin20 shard. Reached through
    # ClangCompiler directly because it is a property of the shard table, not of our surface.
    J = Clang.JLLEnvs
    @test J.__triplet(parse(J.Platform, "aarch64-apple-darwin")) == "aarch64-apple-darwin20"
    @test J.__triplet(parse(J.Platform, "aarch64-apple-darwin20")) == "aarch64-apple-darwin20"
end
