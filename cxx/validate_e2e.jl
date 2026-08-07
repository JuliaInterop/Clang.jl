include("/Users/qi/.julia/dev/Clang/.claude/worktrees/generators-clang-cpp-api-02c8e6/cxx/CxxCodegen.jl")
using .CxxCodegen, TOML
R = "/Users/qi/.julia/dev/Clang/.claude/worktrees/generators-clang-cpp-api-02c8e6"
base = TOML.parsefile(joinpath(R,"test/abi_baseline.toml"))
NEEDS_SYS = Set(["nested-struct.h","nested-declaration.h","struct-in-union.h","test.h"])

function measure(m::Module)
    out = Dict{String,Any}()
    for nm in names(m; all=true)
        startswith(string(nm),"#") && continue
        isdefined(m,nm) || continue
        v = try getfield(m,nm) catch; continue end
        v isa DataType || continue
        (isconcretetype(v) && isstructtype(v) && parentmodule(v)===m) || continue
        try
            out[string(nm)] = (Int(sizeof(v)),
                               fieldcount(v)>0 ? [Int(fieldoffset(v,i)) for i=1:fieldcount(v)] : Int[])
        catch; end
    end
    out
end

function one(f)
    args = f in NEEDS_SYS ? ["-isystem"*joinpath(R,"test/sys")] : String[]
    path = tempname()*".jl"
    open(path,"w") do io; CxxCodegen.generate([joinpath(R,"test/include",f)]; args=args, io=io); end
    m = Module(Symbol("E_", replace(f, r"[^A-Za-z0-9]"=>"_")))
    Core.eval(m, :(using CEnum: CEnum, @cenum)); Core.eval(m, :(const libclangjl = "lib"))
    Base.include(m, path)
    return Base.invokelatest(measure, m)
end

gen_ok=gen_fail=load_fail=0; match=0; mism=String[]; missing=String[]
for f in sort(collect(keys(base)))
    isempty(base[f]["types"]) && continue
    got = try
        r = one(f); global gen_ok += 1; r
    catch e
        msg = first(split(sprint(showerror,e),"\n"))
        if occursin("LoadError", msg) || occursin("UndefVar", msg)
            global load_fail += 1
        else
            global gen_fail += 1
        end
        push!(mism, "$f: $(msg[1:min(end,80)])"); continue
    end
    for (ty, ev) in base[f]["types"]
        ty == "__JL_foo_struct" && continue          # placeholder the new policy removes
        if !haskey(got, ty); push!(missing, "$f/$ty"); continue; end
        sz, off = got[ty]
        want_sz = ev["sizeof"]; want_off = get(ev,"offsets",Int[])
        # sizeof is the ABI invariant. Field offsets are only comparable when the two
        # representations agree -- a blob has one field where a plain struct has n.
        same_shape = length(off) == length(want_off)
        if sz == want_sz && (!same_shape || off == want_off)
            global match += 1
        else
            push!(mism, "$f/$ty: size $sz vs $want_sz, offsets $off vs $want_off")
        end
    end
end
println("fixtures generated+loaded: $gen_ok   gen failures: $gen_fail   load failures: $load_fail")
println("types matching baseline:   $match   mismatched: $(length(mism))   absent: $(length(missing))")
for x in mism[1:min(end,10)]; println("   ! ", x); end
for x in missing[1:min(end,6)]; println("   ? absent ", x); end
