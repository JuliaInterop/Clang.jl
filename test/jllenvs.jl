@testset "get_environment_info" begin
    # testing these do not throw
    Clang.JLLEnvs.get_environment_info("aarch64-apple-darwin20", v"11.0.0-iains")
    Clang.JLLEnvs.get_environment_info("aarch64-linux-gnu")
    Clang.JLLEnvs.get_environment_info("aarch64-linux-musl")
    Clang.JLLEnvs.get_environment_info("armv7l-linux-gnueabihf")
    Clang.JLLEnvs.get_environment_info("armv7l-linux-musleabihf")
    Clang.JLLEnvs.get_environment_info("i686-linux-gnu")
    Clang.JLLEnvs.get_environment_info("i686-linux-musl")
    Clang.JLLEnvs.get_environment_info("i686-w64-mingw32")
    Clang.JLLEnvs.get_environment_info("powerpc64le-linux-gnu")
    Clang.JLLEnvs.get_environment_info("x86_64-apple-darwin14")
    Clang.JLLEnvs.get_environment_info("x86_64-linux-gnu")
    Clang.JLLEnvs.get_environment_info("x86_64-linux-musl")
    Clang.JLLEnvs.get_environment_info("x86_64-unknown-freebsd13.2")
    Clang.JLLEnvs.get_environment_info("x86_64-w64-mingw32")
end

@testset "darwin __triplet backwards compatibility" begin
    @test Clang.JLLEnvs.__triplet(parse(Clang.JLLEnvs.Platform, "aarch64-apple-darwin")) == "aarch64-apple-darwin20"
    @test Clang.JLLEnvs.__triplet(parse(Clang.JLLEnvs.Platform, "aarch64-apple-darwin20")) == "aarch64-apple-darwin20"
end
