# Cross-target generation, end to end: the documented multi-platform workflow is
#
#     for triple in JLL_ENV_TRIPLES
#         args = get_default_args(triple); ...
#
# and this verifies the part nothing else can: that the facts come from the TARGET, not the
# host. Two different failures hide here, and they need different discriminators:
#
#   * ABI: `long`, pointers and `wchar_t` are sized by clang's TargetInfo, so `--target` alone
#     gets them right even when everything else is wrong.
#   * Header provenance: a typedef like `uint_fast32_t` is whatever the INCLUDED stdint.h says —
#     8 bytes in linux-gnu's, 4 in darwin's. Before `parser_for` recovered the shard triple,
#     `create_parser`'s host defaults won the include search and a linux-gnu run silently read
#     the darwin host's headers: right ABI, wrong typedefs. That is the regression this file
#     exists to catch.
#
# Each triple runs only where its GCC shard is already materialised — resolving one downloads
# a multi-hundred-MB artifact, which is the same reason test/jllenvs.jl probes only the host —
# and skips LOUDLY otherwise: a corpus that quietly disappears is how a suite stops testing
# what it claims.

using Test
using Clang
using Clang.Generators
using Clang.Generators.CxxFacts: extract, RecordFacts
import Pkg

"Is `triple`'s GCC shard on disk already? Never downloads."
function shard_materialised(triple::String)
    J = Clang.JLLEnvs
    ver = startswith(triple, "aarch64-apple-darwin") ? v"11.0.0-iains" : J.GCC_MIN_VER
    info = J.get_environment_info(triple, ver)
    return isdir(Pkg.Artifacts.artifact_path(Base.SHA1(info.id)))
end

# (triple, long, ptr, wchar, uint_fast32) — the last column is the header-provenance witness.
const CROSS_EXPECT = [
    ("x86_64-linux-gnu",   8, 8, 4, 8),
    ("x86_64-w64-mingw32", 4, 8, 2, 4),
    ("i686-linux-musl",    4, 4, 4, 4),
]

@testset "cross-target extraction" begin
    dir = mktempdir()
    h = joinpath(dir, "cross.h")
    write(h, """
    #include <stdint.h>
    #include <stddef.h>
    struct X { long l; void *p; wchar_t w; uint_fast32_t f; };
    """)
    for (triple, l, ptr, w, f32) in CROSS_EXPECT
        if !shard_materialised(triple)
            @info "GCC shard not materialised; skipping cross-target check" triple
            @test_skip false
            continue
        end
        @testset "$triple" begin
            # A clean parse is part of the contract: a failed cross include would fall back to
            # recovery decls and could still produce plausible sizes.
            logs, nodes = Test.collect_test_logs() do
                extract([h]; args=get_default_args(triple))
            end
            @test !any(r -> r.level == Base.CoreLogging.Warn, logs)
            x = nothing
            for n in nodes
                n.facts isa RecordFacts && String(n.id) == "X" && (x = n)
            end
            @test x !== nothing
            x === nothing && continue
            sz = [fl.size for fl in x.facts.fields]
            @test sz == [l, ptr, w, f32]
        end
    end
end
