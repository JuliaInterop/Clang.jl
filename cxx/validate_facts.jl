# Validates CxxFacts extraction against test/abi_baseline.toml.
#   julia --project=/path/to/ClangCompiler cxx/validate_facts.jl
# Cannot run in the same process as Clang.jl (GENERATORS-REWORK.md 3.4).
include("/Users/qi/.julia/dev/Clang/.claude/worktrees/generators-clang-cpp-api-02c8e6/cxx/CxxFacts.jl")
using .CxxFacts, TOML
R = "/Users/qi/.julia/dev/Clang/.claude/worktrees/generators-clang-cpp-api-02c8e6"
base = TOML.parsefile(joinpath(R, "test/abi_baseline.toml"))
NEEDS_SYS = Set(["nested-struct.h","nested-declaration.h","struct-in-union.h","test.h"])
failures = String[]
function run(base, R, NEEDS_SYS, failures)
  tot_ok = tot_bad = tot_missing = 0
  for f in sort(collect(keys(base)))
    isempty(base[f]["types"]) && continue
    args = f in NEEDS_SYS ? ["-isystem" * joinpath(R,"test/sys")] : String[]
    nodes = try
        extract([joinpath(R,"test/include",f)]; args=args)
    catch e
        push!(failures, "$f: EXTRACT FAILED: $(first(split(sprint(showerror,e),"\n")))"); continue
    end
    # a baseline type may be reached through a typedef, so follow those to the record
    bykey = Dict(n.key => n for n in nodes)
    resolve_rec(n) = n.facts isa CxxFacts.RecordFacts ? n :
        (n.facts isa CxxFacts.TypedefFacts && n.facts.underlying isa CxxFacts.RecordRef &&
         haskey(bykey, n.facts.underlying.key) ? bykey[n.facts.underlying.key] : nothing)
    byname = Dict{String,Any}()
    for n in nodes
        isempty(String(n.id)) && continue
        r = resolve_rec(n); r === nothing && continue
        get!(byname, String(n.id), r)
    end
    for (ty, ev) in base[f]["types"]
        n = get(byname, ty, nothing)
        if n === nothing; tot_missing += 1; push!(failures, "MISSING  $f  $ty  (extraction found: " * join(sort([String(x.id) for x in nodes if !isempty(String(x.id))]), ", ") * ")"); continue; end
        got = n.facts.size == -1 ? 0 : n.facts.size   # -1 = incomplete -> emitted as a 0-byte opaque
        want = ev["sizeof"]
        if got == want
            tot_ok += 1
        else
            tot_bad += 1; push!(failures, "$f  $ty: clang says $got, baseline $want")
        end
        if haskey(ev, "offsets")
            goff = [fl.bitoffset ÷ 8 for fl in n.facts.fields]
            woff = ev["offsets"]
            if length(goff) == length(woff) && goff != woff
                tot_bad += 1; push!(failures, "$f  $ty offsets: $goff vs $woff")
            end
        end
    end
end
  return tot_ok, tot_bad, tot_missing
end
tot_ok, tot_bad, tot_missing = run(base, R, NEEDS_SYS, failures)
println("size matches: $tot_ok    mismatches: $tot_bad    not found by extraction: $tot_missing")
for f in failures[1:min(end,14)]; println("  ", f); end
