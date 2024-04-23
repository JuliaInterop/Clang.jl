@testset "get_default_args for all triples" begin
    # just testing this does not crash on any default triple
    Clang.get_default_args.(Clang.JLLEnvs.JLL_ENV_TRIPLES)
end

@testset "darwin __triplet backwards compatibility" begin
    @test Clang.JLLEnvs.__triplet(parse(Clang.JLLEnvs.Platform, "aarch64-apple-darwin")) == "aarch64-apple-darwin20"
    @test Clang.JLLEnvs.__triplet(parse(Clang.JLLEnvs.Platform, "aarch64-apple-darwin20")) == "aarch64-apple-darwin20"
end
