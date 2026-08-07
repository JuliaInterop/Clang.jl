# Ground-truth ABI check.
#
# `test/abi_baseline.jl` compares the new backend against the OLD generator's recorded output.
# That is a regression bar, not a correctness bar: it can only certify that we reproduce
# whatever the libclang pipeline produced, bugs included, and it says nothing at all about a
# corpus the old generator cannot process — libxml2 being the case in point.
#
# This compares against clang instead. Every `RecordFacts` carries the `ASTRecordLayout` clang
# computed for that declaration, so for each emitted type we can ask Julia for `sizeof`,
# `datatype_alignment` and `fieldoffset` and check them against the compiler's own numbers.
# That is the actual contract a binding generator has to meet, and it scales to any corpus
# without a recorded baseline.
#
#   julia --project=cxx cxx/validate_abi.jl fixtures libxml2 glib pango

include(joinpath(@__DIR__, "CxxCodegen.jl"))
using .CxxCodegen
using .CxxCodegen.CxxOrder.CxxFacts
import .CxxCodegen.CxxOrder.CxxFacts: Node, Key, RecordFacts, EnumFacts, TypedefFacts,
                                      ArrayRef, BuiltinRef, PointerRef, TypedefRef, RecordRef

const R = dirname(@__DIR__)
const ART = joinpath(homedir(), ".julia", "artifacts")

"Undo `CxxCodegen.safe`: the binding `var\"end\"` creates is named `end`, not `var\"end\"`."
function unescape(s::Symbol)
    t = String(s)
    startswith(t, "var\"") && endswith(t, "\"") ? Symbol(t[5:end-1]) : s
end

# ------------------------------------------------------------------------------------------
# Why a record might legitimately differ — computed from facts, so the report triages itself.
# ------------------------------------------------------------------------------------------
"Does this record end in a flexible array member? clang counts it as zero bytes."
has_fam(f::RecordFacts) = !isempty(f.fields) && (t = f.fields[end].type;
                                                 t isa ArrayRef && t.len < 0)

function mentions_longdouble(e, t, depth=0)
    depth > 8 && return false
    t isa BuiltinRef && return t.name === :longdouble
    t isa ArrayRef && return mentions_longdouble(e, t.elem, depth + 1)
    if t isa TypedefRef
        n = get(e, t.key, nothing)
        n !== nothing && n.facts isa TypedefFacts &&
            return mentions_longdouble(e, n.facts.underlying, depth + 1)
    end
    return false
end

# ------------------------------------------------------------------------------------------
struct Finding
    corpus::String
    name::String
    kind::String        # size | align | offset | absent
    detail::String
    hint::String
end

function compare(m::Module, nodes::Vector{Node}, env, names::Dict{Key,Symbol},
                 blobbed::Set{Key}, skip::Set{Key}, corpus::String)
    bykey = Dict(n.key => n for n in nodes)
    found = Finding[]
    n_rec = n_enum = n_off = 0
    for n in nodes
        n.key in skip && continue
        sym = unescape(names[n.key])
        f = n.facts
        if f isa RecordFacts
            f.complete || continue
            isdefined(m, sym) || (push!(found, Finding(corpus, String(sym), "absent", "", ""));
                                  continue)
            T = getfield(m, sym)
            T isa DataType && isconcretetype(T) || continue
            hint = join(filter(!isempty, [has_fam(f) ? "flexible-array-member" : "",
                                          f.packed ? "packed" : "",
                                          n.key in blobbed ? "blobbed" : "",
                                          any(fl -> mentions_longdouble(bykey, fl.type), f.fields) ?
                                              "long-double" : ""]), ",")
            n_rec += 1
            sizeof(T) == f.size ||
                push!(found, Finding(corpus, String(sym), "size",
                                     "julia $(sizeof(T)) vs clang $(f.size)", hint))
            Base.datatype_alignment(T) == f.align ||
                push!(found, Finding(corpus, String(sym), "align",
                                     "julia $(Base.datatype_alignment(T)) vs clang $(f.align)", hint))
            if n.key ∉ blobbed && fieldcount(T) == length(f.fields)
                for (i, fl) in enumerate(f.fields)
                    n_off += 1
                    want = fl.bitoffset ÷ 8
                    Int(fieldoffset(T, i)) == want ||
                        push!(found, Finding(corpus, "$sym.$(fl.name)", "offset",
                                             "julia $(fieldoffset(T,i)) vs clang $want", hint))
                end
            end
        elseif f isa EnumFacts
            isdefined(m, sym) || continue
            T = getfield(m, sym)
            T isa DataType && isconcretetype(T) || continue
            # An enum's ABI is the width clang chose for it, which C leaves to the
            # implementation — so this must come from `getIntegerType`, never assumed to be int.
            want = try sizeof(Core.eval(m, CxxCodegen.jltype(env, f.integer_type))) catch; continue end
            n_enum += 1
            sizeof(T) == want ||
                push!(found, Finding(corpus, String(sym), "size",
                                     "julia $(sizeof(T)) vs clang $want", "enum"))
        end
    end
    return found, (; records=n_rec, offsets=n_off, enums=n_enum)
end

function run_corpus(corpus::String, headers::Vector{String}; args::Vector{String}=String[],
                    options::CxxCodegen.Options=CxxCodegen.Options())
    t0 = time()
    nodes = extract(headers; args=args)
    # Macros must be translated here too. `generate(nodes)` defaults to none, so emitting from
    # pre-extracted nodes would silently skip the whole macro path — and one macro that names
    # something undefined fails the entire file, which is very much this harness's business.
    macros = options.macro_mode == "disable" ? [] :
             CxxCodegen.CxxMacros.translate_macros(headers, args)
    path = tempname() * ".jl"
    st = open(path, "w") do io
        CxxCodegen.generate(nodes; options=options, macros=macros, io=io)
    end
    names, skip = CxxCodegen.assign_names(nodes)
    blobbed = CxxCodegen.blob_set(nodes)
    env = CxxCodegen.Env(Dict(n.key => n for n in nodes), names, blobbed, skip)

    m = Module(Symbol("ABI_", replace(corpus, r"[^A-Za-z0-9]" => "_")))
    Core.eval(m, :(using CEnum: CEnum, @cenum))
    Core.eval(m, :(const $(Symbol(options.library_name)) = $(options.library_name)))
    try
        Base.include(m, path)
    catch err
        # A load failure must be a FINDING, not just a printed line: measuring nothing is not
        # the same as measuring everything and agreeing, and a summary that cannot tell the two
        # apart is worse than no summary.
        msg = first(split(sprint(showerror, err), "\n"))
        println("  LOAD FAILED: ", msg, "   (kept at $path)")
        return [Finding(corpus, "<module>", "load", msg, "")], nothing
    end
    found, counts = Base.invokelatest(compare, m, nodes, env, names, blobbed, skip, corpus)
    println("  nodes=$(st.nodes) emitted=$(st.emitted) cuts=$(st.cuts) hoisted=$(st.hoisted) ",
            "macros=$(st.macros)/$(st.macros_seen)  ",
            "checked: $(counts.records) records / $(counts.offsets) field offsets  ",
            "[$(round(time()-t0, digits=1))s]")
    return found, counts
end

# ------------------------------------------------------------------------------------------
const CORPORA = Dict{String,Function}()

CORPORA["libxml2"] = () -> begin
    inc = joinpath(ART, "c99c0e2b61a41b4b2294b30e9f7f26e50c2e38eb", "include", "libxml2")
    hs = sort!([joinpath(inc, "libxml", f) for f in readdir(joinpath(inc, "libxml"))
                if endswith(f, ".h")])
    run_corpus("libxml2", hs; args=["-I$inc"],
               options=CxxCodegen.Options(library_name="libxml2"))
end

CORPORA["glib"] = () -> begin
    inc = joinpath(ART, "d3c452363ecbfffb1b5e29644395f7016c0ec781", "include", "glib-2.0")
    lib = joinpath(ART, "d3c452363ecbfffb1b5e29644395f7016c0ec781", "lib", "glib-2.0", "include")
    run_corpus("glib", [joinpath(inc, "glib.h")]; args=["-I$inc", "-I$lib"],
               options=CxxCodegen.Options(library_name="libglib"))
end

CORPORA["pango"] = () -> begin
    inc = joinpath(ART, "3f72ac459eb33379a85dc4acdd35ab8bf0ac8c05", "include", "pango-1.0")
    g   = joinpath(ART, "d3c452363ecbfffb1b5e29644395f7016c0ec781", "include", "glib-2.0")
    gl  = joinpath(ART, "d3c452363ecbfffb1b5e29644395f7016c0ec781", "lib", "glib-2.0", "include")
    run_corpus("pango", [joinpath(inc, "pango", "pango.h")];
               args=["-I$inc", "-I$g", "-I$gl"],
               options=CxxCodegen.Options(library_name="libpango"))
end

CORPORA["fixtures"] = () -> begin
    needs_sys = Set(["nested-struct.h", "nested-declaration.h", "struct-in-union.h", "test.h"])
    all = Finding[]
    for f in sort!(readdir(joinpath(R, "test", "include")))
        endswith(f, ".h") || continue
        f == "objectiveC.h" && continue          # ObjC is out of scope until ClangCompiler#49
        args = f in needs_sys ? ["-isystem" * joinpath(R, "test", "sys")] : String[]
        print("  ", rpad(f, 32))
        try
            fd, _ = run_corpus(f, [joinpath(R, "test", "include", f)]; args=args)
            append!(all, fd)
        catch err
            println("  GENERATE FAILED: ", first(split(sprint(showerror, err), "\n")))
        end
    end
    return all, nothing
end

# ------------------------------------------------------------------------------------------
sel = isempty(ARGS) ? ["fixtures", "libxml2"] : ARGS
allfound = Finding[]
for s in sel
    haskey(CORPORA, s) || (println("unknown corpus: $s"); continue)
    println("== $s")
    fd, _ = CORPORA[s]()
    append!(allfound, fd)
end

println()
if isempty(allfound)
    println("ABI: all emitted types match clang's layout.")
else
    bykind = Dict{String,Int}()
    for f in allfound; bykind[f.kind] = get(bykind, f.kind, 0) + 1; end
    println("ABI mismatches: ", join(("$k=$v" for (k, v) in sort(collect(bykind))), "  "))
    byhint = Dict{String,Int}()
    for f in allfound; byhint[f.hint] = get(byhint, f.hint, 0) + 1; end
    println("by hint: ", join(("$(isempty(k) ? "(none)" : k)=$v" for (k, v) in sort(collect(byhint); by=x->-x[2])), "  "))
    println()
    for f in allfound[1:min(end, 40)]
        println("  $(rpad(f.kind,7)) $(rpad(f.corpus,12)) $(rpad(f.name,44)) $(f.detail)  $(f.hint)")
    end
    length(allfound) > 40 && println("  ... and $(length(allfound)-40) more")
end
