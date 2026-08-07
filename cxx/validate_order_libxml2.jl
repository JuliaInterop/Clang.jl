include("/Users/qi/.julia/dev/Clang/.claude/worktrees/generators-clang-cpp-api-02c8e6/cxx/CxxOrder.jl")
using .CxxOrder, .CxxOrder.CxxFacts
INC="/Users/qi/.julia/artifacts/c99c0e2b61a41b4b2294b30e9f7f26e50c2e38eb/include/libxml2"
hdrs=[joinpath(INC,"libxml",f) for f in readdir(joinpath(INC,"libxml")) if endswith(f,".h")]
t0=time(); nodes = extract(hdrs; args=["-I$INC"]); t1=time()
o = order_nodes(nodes); t2=time()
println("nodes ", length(nodes), "   extract ", round(t1-t0,digits=1), "s   order ", round(t2-t1,digits=2), "s")
println("ordered ", length(o.order), "   hoisted ", o.hoisted,
        "   cuts ", length(o.cuts), " (tier1 ", count(c->c.tier==1,o.cuts), ", tier2 ", count(c->c.tier==2,o.cuts), ")")
bykey = Dict(n.key=>n for n in nodes)
println("sample cuts:")
for c in o.cuts[1:min(end,5)]; println("   ", rpad(string(bykey[c.node].id),22), "tier ", c.tier, " — ", c.why); end
@assert length(o.order) == length(nodes) "order dropped nodes"
@assert length(unique(o.order)) == length(o.order) "order has duplicates"
println("INVARIANTS OK: every node ordered exactly once")
