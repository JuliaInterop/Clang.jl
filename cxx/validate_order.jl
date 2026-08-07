include("/Users/qi/.julia/dev/Clang/.claude/worktrees/generators-clang-cpp-api-02c8e6/cxx/CxxOrder.jl")
using .CxxOrder
using .CxxOrder.CxxFacts
R = "/Users/qi/.julia/dev/Clang/.claude/worktrees/generators-clang-cpp-api-02c8e6"
NEEDS_SYS = Set(["nested-struct.h","nested-declaration.h","struct-in-union.h","test.h"])

function run_one(label, headers, args)
    nodes = extract(headers; args=args)
    o = order_nodes(nodes)
    t1 = count(c -> c.tier == 1, o.cuts); t2 = count(c -> c.tier == 2, o.cuts)
    println(rpad(label, 30), "nodes ", lpad(length(nodes),5),
            "   ordered ", lpad(length(o.order),5),
            "   hoisted ", lpad(o.hoisted,4),
            "   cuts ", lpad(length(o.cuts),3), " (tier1 ", t1, ", tier2 ", t2, ")")
    return o, nodes
end

println("──── fixtures with real cycles ────")
for f in ["cycle-detection.h","method-ambiguity.h","struct-mutual-ref.h","dependency.h","union-in-struct.h"]
    args = f in NEEDS_SYS ? ["-isystem"*joinpath(R,"test/sys")] : String[]
    try
        o, nodes = run_one(f, [joinpath(R,"test/include",f)], args)
        bykey = Dict(n.key=>n for n in nodes)
        for c in o.cuts
            println("      cut: ", bykey[c.node].id, ".field[", c.field, "]  tier ", c.tier, " — ", c.why)
        end
    catch e
        println(rpad(f,30), "FAILED: ", first(split(sprint(showerror,e),"\n")))
    end
end

