# Emission ordering, and the cuts a genuine cycle forces.
#
# Julia has no forward declarations, so every definition-time type position — struct fields,
# `const` right-hand sides, `ccall` type arguments — must already be bound. Where a real cycle
# makes that impossible the ordering pass breaks it AND records the field it degraded in the
# same step; the two cannot disagree, which is what the libclang pipeline could not guarantee
# (`ORDERING-DESIGN.md`).

using Test
using Clang
using Clang.Generators
using Clang.Generators.CxxFacts: extract
using Clang.Generators.CxxOrder: order_nodes

const ORD_R = dirname(@__DIR__)
const ORD_SYS = Set(["nested-struct.h", "nested-declaration.h", "struct-in-union.h", "test.h"])

"Order one fixture, reporting what it took."
function order_fixture(f)
    # The real toolchain flags, not a bare parse: several fixtures include <stdint.h>, which
    # needs the cross-compilation sysroot to resolve `__builtin_va_list`.
    args = get_default_args()
    f in ORD_SYS && push!(args, "-isystem" * joinpath(ORD_R, "test", "sys"))
    nodes = extract([joinpath(ORD_R, "test", "include", f)]; args=args)
    ord = order_nodes(nodes)
    bykey = Dict(n.key => n for n in nodes)
    println(rpad(f, 28), "nodes ", lpad(length(nodes), 4),
            "  ordered ", lpad(length(ord.order), 4),
            "  hoisted ", lpad(ord.hoisted, 3),
            "  cuts ", lpad(length(ord.cuts), 2),
            " (tier1 ", count(c -> c.tier == 1, ord.cuts),
            ", tier2 ", count(c -> c.tier == 2, ord.cuts), ")")
    for c in ord.cuts
        println("      cut: ", bykey[c.node].id, ".field[", c.field, "]  tier ", c.tier,
                " — ", c.why)
    end
    return ord, nodes
end

@testset "ordering" begin
    @testset "every node is ordered exactly once" begin
        for f in ["cycle-detection.h", "method-ambiguity.h", "struct-mutual-ref.h",
                  "dependency.h", "union-in-struct.h", "a.h", "alignment.h"]
            @testset "$f" begin
                ord, nodes = order_fixture(f)
                @test length(ord.order) == length(nodes)
                @test length(Set(ord.order)) == length(ord.order)
            end
        end
    end

    @testset "cycles are cut, and cut minimally" begin
        # A typedef on the cycle means tier 1 — substitute the typedef's own underlying type,
        # no placeholder and no repair method. Both fixtures with real cycles take that path.
        for f in ["cycle-detection.h", "method-ambiguity.h"]
            @testset "$f" begin
                ord, _ = order_fixture(f)
                @test length(ord.cuts) == 1
                @test only(ord.cuts).tier == 1
            end
        end
        # A mutual reference through pointers needs no cut at all: `struct B; x::Ptr{B}; end`
        # is legal Julia, so a self- or pointer-mediated edge imposes no constraint.
        for f in ["struct-mutual-ref.h", "dependency.h", "union-in-struct.h"]
            @testset "$f" begin
                ord, _ = order_fixture(f)
                @test isempty(ord.cuts)
            end
        end
    end

    @testset "source order is perturbed only where an edge forces it" begin
        # C already forbids a non-pointer member of an incomplete type, so C source order is a
        # valid topological order for every non-pointer edge. Nothing should move in a header
        # with no cycles and no forward references.
        ord, _ = order_fixture("a.h")
        @test ord.hoisted == 0
    end
end
