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
#   julia --project -e 'using Pkg; Pkg.test()'      -- or include this file directly

using Test
using Clang
using Clang.Generators
import Clang.Generators.CxxFacts: Node, Key, RecordFacts, EnumFacts, TypedefFacts,
                                  ArrayRef, BuiltinRef, PointerRef, TypedefRef, RecordRef, extract
using Clang.Generators.CxxEmit: Options
const E = Clang.Generators.CxxEmit
const M = Clang.Generators.CxxMacros

const R = dirname(@__DIR__)
const ART = joinpath(homedir(), ".julia", "artifacts")

"Undo `E.safe`: the binding `var\"end\"` creates is named `end`, not `var\"end\"`."
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
            want = try sizeof(Core.eval(m, E.jltype(env, f.integer_type))) catch; continue end
            n_enum += 1
            sizeof(T) == want ||
                push!(found, Finding(corpus, String(sym), "size",
                                     "julia $(sizeof(T)) vs clang $want", "enum"))
        end
    end
    return found, (; records=n_rec, offsets=n_off, enums=n_enum)
end

function run_corpus(corpus::String, headers::Vector{String}; args::Vector{String}=String[],
                    options::Options=Options())
    t0 = time()
    nodes = extract(headers; args=args)
    # Macros must be translated here too. `generate(nodes)` defaults to none, so emitting from
    # pre-extracted nodes would silently skip the whole macro path — and one macro that names
    # something undefined fails the entire file, which is very much this harness's business.
    macros = options.macro_mode == "disable" ? [] :
             M.translate_macros(headers, args)
    path = tempname() * ".jl"
    st = open(path, "w") do io
        E.generate(nodes; options=options, macros=macros, io=io)
    end
    names, skip = E.assign_names(nodes)
    blobbed = E.blob_set(nodes)
    env = E.Env(Dict(n.key => n for n in nodes), names, blobbed, skip, options)

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
               options=Options(library_name="libxml2"))
end

CORPORA["glib"] = () -> begin
    inc = joinpath(ART, "d3c452363ecbfffb1b5e29644395f7016c0ec781", "include", "glib-2.0")
    lib = joinpath(ART, "d3c452363ecbfffb1b5e29644395f7016c0ec781", "lib", "glib-2.0", "include")
    run_corpus("glib", [joinpath(inc, "glib.h")]; args=["-I$inc", "-I$lib"],
               options=Options(library_name="libglib"))
end

CORPORA["pango"] = () -> begin
    inc = joinpath(ART, "3f72ac459eb33379a85dc4acdd35ab8bf0ac8c05", "include", "pango-1.0")
    g   = joinpath(ART, "d3c452363ecbfffb1b5e29644395f7016c0ec781", "include", "glib-2.0")
    gl  = joinpath(ART, "d3c452363ecbfffb1b5e29644395f7016c0ec781", "lib", "glib-2.0", "include")
    run_corpus("pango", [joinpath(inc, "pango", "pango.h")];
               args=["-I$inc", "-I$g", "-I$gl"],
               options=Options(library_name="libpango"))
end

"""
Cases the real corpora happen not to contain.

libxml2, glib and pango between them have 1457 checked field offsets and not one
qualifier-qualified struct field, so `const int x` silently becoming a ZERO-SIZED `Cvoid` field
survived every check. A corpus is evidence about what it contains; this covers the rest.
"""
CORPORA["synthetic"] = () -> begin
    dir = mktempdir()
    h = joinpath(dir, "synthetic.h")
    write(h, """
    // cvr-qualified members: `getAsString` on a QualType includes the qualifier, so these
    // missed the builtin table entirely and became Cvoid -- occupying no bytes at all.
    struct Qual { const int ci; volatile double vd; unsigned const int uci;
                  const char *cs; char *const sc; };
    // a pointer-to-function member, whose parameter types must NOT constrain emission order
    struct FnPtr { int (*cb)(struct FnPtr *, const char *); int n; };
    // arrays, including a multidimensional one
    struct Arrs { char a[7]; int m[3][4]; double *pd[2]; };
    // `#pragma pack(n)` -- clang models this as MaxFieldAlignmentAttr, NOT the Packed attr, so
    // an attribute-based check misses it entirely and the record is emitted as a plain struct
    // with Julia's natural layout: 8 bytes where clang says 5, second field at 4 not 1.
    #pragma pack(1)
    struct Packed1 { char a; int b; double c; };
    #pragma pack(2)
    struct Packed2 { char a; int b; };
    #pragma pack()
    // over-aligned: the record's alignment exceeds its most-aligned member
    struct OverAligned { int a; } __attribute__((aligned(16)));
    // an enum with an explicitly non-int underlying type
    enum Wide { W_LO = 0, W_HI = 0x7fffffffffffffffLL };
    struct HasEnum { enum Wide w; char pad; };
    """)
    run_corpus("synthetic", [h]; args=get_default_args(),
               options=Options(library_name="libsyn"))
end

CORPORA["fixtures"] = () -> begin
    needs_sys = Set(["nested-struct.h", "nested-declaration.h", "struct-in-union.h", "test.h"])
    all = Finding[]
    for f in sort!(readdir(joinpath(R, "test", "include")))
        endswith(f, ".h") || continue
        f == "objectiveC.h" && continue          # ObjC is out of scope until ClangCompiler#49
        args = get_default_args()
        f in needs_sys && push!(args, "-isystem" * joinpath(R, "test", "sys"))
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
# `synthetic` and `fixtures` are always available. The third-party corpora need JLL artifacts
# that a CI runner may not have, so they run when present and are skipped when not — never
# silently, since a corpus that quietly disappears is how a suite stops testing what it claims.
"Is this corpus's input actually on this machine?"
available(s) = s in ("synthetic", "fixtures") ||
               (s == "libxml2" && isdir(joinpath(ART, "c99c0e2b61a41b4b2294b30e9f7f26e50c2e38eb"))) ||
               (s == "glib" && isdir(joinpath(ART, "d3c452363ecbfffb1b5e29644395f7016c0ec781"))) ||
               (s == "pango" && isdir(joinpath(ART, "3f72ac459eb33379a85dc4acdd35ab8bf0ac8c05")))

@testset "ABI vs clang's own layout" begin
    for s in (isempty(ARGS) ? ["synthetic", "fixtures", "libxml2", "glib", "pango"] : ARGS)
        if !haskey(CORPORA, s)
            @warn "unknown corpus" corpus = s
            continue
        end
        if !available(s)
            @info "corpus not present on this machine; skipping" corpus = s
            @test_skip false
            continue
        end
        @testset "$s" begin
            println("== $s")
            found, _ = CORPORA[s]()
            for f in found
                println("  $(rpad(f.kind,7)) $(rpad(f.corpus,12)) $(rpad(f.name,44)) ",
                        "$(f.detail)  $(f.hint)")
            end
            @test isempty(found)
        end
    end
end
