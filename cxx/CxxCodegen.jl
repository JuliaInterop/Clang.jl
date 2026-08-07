"""
    CxxCodegen

Emit Julia from extracted facts — the third stage of extract → order → codegen.

Nothing here touches clang. Every number it needs (field offsets in bits, record size and
alignment, bit-field widths) was measured during extraction, which is what makes this stage
frontend-independent.

Two rules decide the shape of a record:

  * A record whose natural Julia layout would match clang's is emitted as a **plain struct with
    named, typed fields**. This is the readable form and it is what most C structs get.
  * Anything clang lays out differently from Julia's natural rules — a bit-field, a `packed`
    attribute, an unnamed member — falls back to the opaque-bytes form plus generated
    accessors, exactly as the current generator does. Blobbing is a fallback, never the
    default (`GENERATORS-REWORK.md` §3.6).
"""
module CxxCodegen

include(joinpath(@__DIR__, "CxxOrder.jl"))
include(joinpath(@__DIR__, "CxxMacros.jl"))
using .CxxOrder
using .CxxMacros
using .CxxOrder.CxxFacts
import .CxxOrder.CxxFacts: Key, Node, TypeRef, RecordFacts, TypedefFacts, EnumFacts,
                           FunctionFacts, PointerRef, RecordRef, TypedefRef, EnumRef,
                           ArrayRef, BuiltinRef, FunctionRef, UnknownRef, FieldFacts
import .CxxOrder: Cut, Ordering

export generate, Options

const JL = Dict(:void=>:Cvoid, :bool=>:Bool, :char=>:Cchar, :schar=>:Int8, :uchar=>:Cuchar,
                :short=>:Cshort, :ushort=>:Cushort, :int=>:Cint, :uint=>:Cuint,
                :long=>:Clong, :ulong=>:Culong, :longlong=>:Clonglong,
                :ulonglong=>:Culonglong, :float=>:Float32, :double=>:Float64,
                :longdouble=>:Float64, :int128=>:Int128, :uint128=>:UInt128,
                :wchar=>:Cwchar_t, :char16=>:UInt16, :char32=>:UInt32, :unknown=>:Cvoid)

"""
Well-known system typedefs that Julia already names. Mapping them directly means a header
using `uint32_t` neither emits a definition for it nor leaves the name dangling — the role
`ids_extra`/`@add_def` plays in the libclang pipeline.
"""
const SYSTEM_TYPEDEFS = Dict{Symbol,Symbol}(
    :uint8_t=>:UInt8, :uint16_t=>:UInt16, :uint32_t=>:UInt32, :uint64_t=>:UInt64,
    :int8_t=>:Int8, :int16_t=>:Int16, :int32_t=>:Int32, :int64_t=>:Int64,
    :__uint8_t=>:UInt8, :__uint16_t=>:UInt16, :__uint32_t=>:UInt32, :__uint64_t=>:UInt64,
    :__int8_t=>:Int8, :__int16_t=>:Int16, :__int32_t=>:Int32, :__int64_t=>:Int64,
    :size_t=>:Csize_t, :ssize_t=>:Cssize_t, :ptrdiff_t=>:Cptrdiff_t,
    :intptr_t=>:Cptrdiff_t, :uintptr_t=>:Csize_t, :wchar_t=>:Cwchar_t, :time_t=>:Clong)

struct Env
    bykey::Dict{Key,Node}
    name::Dict{Key,Symbol}      # key -> the Julia name actually emitted
    blobbed::Set{Key}
    skip::Set{Key}              # mapped to a Julia builtin; emit nothing for these
end

"""
The subset of the TOML option surface this emitter honours.

Named after the existing keys so a `generator.toml` maps across unchanged. Everything absent
here is still unimplemented — see `GENERATORS-REWORK.md` §0.1.
"""
Base.@kwdef struct Options
    library_name::String            = "libfoo"
    module_name::String             = ""
    prologue_file_path::String      = ""
    epilogue_file_path::String      = ""
    jll_pkg_name::String            = ""
    jll_pkg_extra::Vector{String}   = String[]
    export_symbol_prefixes::Vector{String} = String[]
    output_ignorelist::Vector{String}      = String[]
    generate_isystem_symbols::Bool  = true
    skip_static_functions::Bool     = false
    use_julia_native_enum_type::Bool = false
    print_using_CEnum::Bool         = true
    use_ccall_macro::Bool           = false
    macro_mode::String              = "basic"    # "basic" | "disable"
    add_comment_for_skipped_macro::Bool = true
    wrap_variadic_function::Bool    = false
end

"Read the `[general]`/`[codegen]` tables of a parsed `generator.toml` into `Options`."
function Options(toml::AbstractDict)
    g = get(toml, "general", Dict{String,Any}())
    c = get(toml, "codegen", Dict{String,Any}())
    pick(d, k, dflt) = haskey(d, k) ? d[k] : dflt
    return Options(
        library_name             = string(pick(g, "library_name", "libfoo")),
        module_name              = string(pick(g, "module_name", "")),
        prologue_file_path       = string(pick(g, "prologue_file_path", "")),
        epilogue_file_path       = string(pick(g, "epilogue_file_path", "")),
        jll_pkg_name             = string(pick(g, "jll_pkg_name", "")),
        jll_pkg_extra            = String.(pick(g, "jll_pkg_extra", String[])),
        export_symbol_prefixes   = String.(pick(g, "export_symbol_prefixes", String[])),
        output_ignorelist        = String.(pick(g, "output_ignorelist", String[])),
        generate_isystem_symbols = Bool(pick(g, "generate_isystem_symbols", true)),
        skip_static_functions    = Bool(pick(g, "skip_static_functions", false)),
        use_julia_native_enum_type = Bool(pick(g, "use_julia_native_enum_type", false)),
        print_using_CEnum        = Bool(pick(g, "print_using_CEnum", true)),
        use_ccall_macro          = Bool(pick(c, "use_ccall_macro", false)),
        wrap_variadic_function   = Bool(pick(c, "wrap_variadic_function", false)),
        macro_mode               = string(pick(get(c, "macro", Dict{String,Any}()),
                                               "macro_mode", "basic")),
        add_comment_for_skipped_macro =
            Bool(pick(get(c, "macro", Dict{String,Any}()),
                      "add_comment_for_skipped_macro", true)))
end

"`output_ignorelist` entries are regexes that must match the WHOLE name, as today."
excluded(o::Options, nm::Symbol) =
    any(r -> (m = match(Regex(r), String(nm)); m !== nothing && m.match == String(nm)),
        o.output_ignorelist)

"""
Julia keywords that are legal C identifiers.

`struct _xmlParserInput` in libxml2 has a field named `end`. Emitted bare, Julia parses it as
the block terminator and silently re-reads the rest of the file as something else — the failure
surfaced 9000 lines later as `TypeError: expected Ptr{UInt8}, got Nothing`, nowhere near the
cause. Every emitted identifier goes through `safe`.
"""
const RESERVED = Set(Symbol.([
    "baremodule","begin","break","catch","const","continue","do","else","elseif","end","export",
    "false","finally","for","function","global","if","import","in","isa","let","local","macro",
    "module","quote","return","struct","true","try","using","where","while","abstract","mutable",
    "primitive","type","outer","var"]))

"Escape an identifier that would otherwise be a Julia keyword, preserving the C spelling."
function safe(nm::Symbol)
    s = String(nm)
    isempty(s) && return nm
    (nm in RESERVED || !Base.isidentifier(s)) && return Symbol("var\"", s, "\"")
    return nm
end

"""
The binding name `safe` actually creates: `var"end"` parses to the identifier `end`.

Anything asking "does this file define X?" — the macro guards, the ABI verifier — must ask
under the binding name, not the escaped spelling.
"""
function unescape_name(s::Symbol)
    t = String(s)
    startswith(t, "var\"") && endswith(t, "\"") ? Symbol(t[5:(end - 1)]) : s
end

"Translate a `TypeRef` into a Julia type expression."
function jltype(e::Env, t::TypeRef)
    if t isa BuiltinRef
        return get(JL, t.name, :Cvoid)
    elseif t isa PointerRef
        p = t.pointee
        # A pointer to a function, or to something we could not name, is an untyped pointer.
        (p isa FunctionRef || p isa UnknownRef) && return :(Ptr{Cvoid})
        inner = jltype(e, p)
        return :(Ptr{$inner})
    elseif t isa ArrayRef
        el = jltype(e, t.elem)
        t.len < 0 && return :(Ptr{$el})     # incomplete array decays
        return :(NTuple{$(t.len), $el})
    elseif t isa RecordRef || t isa EnumRef || t isa TypedefRef
        return get(e.name, t.key, :Cvoid)
    elseif t isa FunctionRef
        return :(Ptr{Cvoid})
    end
    return :Cvoid
end

"An anonymous record reached only as a field type still needs a name to be referred to by."
function assign_names(nodes::Vector{Node})
    name = Dict{Key,Symbol}()
    skip = Set{Key}()
    used = Set{Symbol}()
    n_anon = 0
    for n in nodes
        # A system typedef Julia already names resolves to that name and is never emitted.
        if n.system && n.facts isa TypedefFacts && haskey(SYSTEM_TYPEDEFS, n.id)
            name[n.key] = SYSTEM_TYPEDEFS[n.id]; push!(skip, n.key); continue
        end
        id = n.id
        if isempty(String(id))
            n_anon += 1
            id = Symbol("__anon_", n_anon)     # deterministic: discovery order, not a gensym
        end
        while id in used
            id = Symbol(String(id), "_")
        end
        id = safe(id)
        push!(used, id)
        name[n.key] = id
    end
    return name, skip
end

"""
Records whose layout Julia will not reproduce naturally, computed to a fixpoint.

A record containing a blobbed member must itself be blobbed: `NTuple{N,UInt8}` has alignment 1,
so a struct holding one loses the alignment clang gave it and comes out the wrong size. This is
the bug that made `C_STRUCT` 19 bytes instead of 24.
"""
function blob_set(nodes::Vector{Node})
    bykey = Dict(n.key => n for n in nodes)
    blob = Set{Key}(n.key for n in nodes if n.facts isa RecordFacts && n.facts.complete &&
                                            needs_blob(n.facts))
    changed = true
    while changed
        changed = false
        for n in nodes
            (n.facts isa RecordFacts && n.facts.complete && n.key ∉ blob) || continue
            for fld in n.facts.fields
                for (k, viaptr) in CxxFacts.deps(fld.type)
                    viaptr && continue                       # a pointer to a blob is fine
                    tgt = k
                    # follow a typedef to the record it names
                    tn = get(bykey, k, nothing)
                    if tn !== nothing && tn.facts isa TypedefFacts
                        for (k2, p2) in CxxFacts.deps(tn.facts.underlying)
                            p2 || (tgt = k2)
                        end
                    end
                    if tgt in blob
                        push!(blob, n.key); changed = true; break
                    end
                end
                n.key in blob && break
            end
        end
    end
    return blob
end

"""
The element type and count for a blobbed record's storage tuple.

`NTuple{N,UInt8}` reproduces clang's *size* but always has alignment 1, and Julia gives a struct
the maximum alignment of its fields — so every blobbed record came out under-aligned. The
libclang generator has the same bug and cannot see it: it never calls `getAlignOf`
(CLAUDE.md, "Layout"), so there is nothing to compare against.

Storing the same bytes as a tuple of a wider unsigned carries the alignment across, because
Julia's `UInt16`/`UInt32`/`UInt64`/`UInt128` have alignment equal to their size on every platform
this package supports. C guarantees a record's size is a multiple of its alignment, so the
division is exact; the `divrem` check is there to degrade rather than emit a wrong size if some
frontend ever reports otherwise.
"""
function blob_storage(f::RecordFacts)
    size = max(f.size, 1)
    for (unit, bytes) in ((:UInt128, 16), (:UInt64, 8), (:UInt32, 4), (:UInt16, 2))
        if f.align >= bytes && size % bytes == 0
            return unit, size ÷ bytes
        end
    end
    return :UInt8, size
end

"""
Does this record need the opaque-bytes fallback rather than a plain struct?

The `unnameable` clause is a safety net, not a feature. `jltype` maps an `UnknownRef` to `Cvoid`
because there is nothing better to say — but a `Cvoid` field occupies ZERO bytes in Julia, so a
single unrecognised field type silently shifts every field after it and shrinks the record.
Falling back to the blob form keeps `size` and every offset exactly right no matter what the
frontend failed to name, which turns a silent ABI corruption into a merely less readable struct.
"""
needs_blob(f::RecordFacts) =
    f.kind === :union || f.packed ||
    any(fl -> fl.bitwidth >= 0 || isempty(String(fl.name)) || unnameable(fl.type), f.fields)

"Does this type contain a position we could not name, at a place that occupies storage?"
unnameable(t::TypeRef, depth::Int=0) =
    depth <= 8 && (t isa UnknownRef ||
                   (t isa ArrayRef && unnameable(t.elem, depth + 1)))

"""
Emit a record. `cuts` are the field substitutions the ordering pass decided, applied here — the
single place a degraded field is realised, so the cut and the emitted type cannot disagree.
"""
function emit_record(e::Env, n::Node, cuts::Dict{Int,Cut}, out::Vector{Expr})
    f = n.facts::RecordFacts
    sym = e.name[n.key]
    if !f.complete
        push!(out, :(mutable struct $sym end))
        return
    end
    if n.key in e.blobbed
        unit, count = blob_storage(f)
        push!(out, :(struct $sym; data::NTuple{$count,$unit}; end))
        emit_accessors(e, n, out)
        return
    end
    body = Expr(:block)
    for (i, fld) in enumerate(f.fields)
        ty = haskey(cuts, i) ? jltype(e, cuts[i].replacement) : jltype(e, fld.type)
        push!(body.args, Expr(:(::), safe(Symbol(fld.name)), ty))
    end
    push!(out, Expr(:struct, false, sym, body))
    # A tier-2 cut erased the field's real type, so give the pointer form back typed.
    for (i, c) in cuts
        c.tier == 2 || continue
        fld = f.fields[i]
        real = jltype(e, fld.type)
        push!(out, :(function Base.getproperty(x::$sym, f::Symbol)
                         f === $(QuoteNode(Symbol(fld.name))) &&
                             return reinterpret($real, getfield(x, f))
                         return getfield(x, f)
                     end))
    end
end

"Byte/bit accessors over the opaque-bytes form."
function emit_accessors(e::Env, n::Node, out::Vector{Expr})
    f = n.facts::RecordFacts
    sym = e.name[n.key]
    body = Expr(:block)
    props = Symbol[]
    for fld in f.fields
        nm = String(fld.name); isempty(nm) && continue
        s = safe(Symbol(nm)); push!(props, s)
        ty = jltype(e, fld.type)
        if fld.bitwidth >= 0
            d, r = divrem(fld.bitoffset, 8)
            push!(body.args, :(f === $(QuoteNode(s)) &&
                               return (Ptr{$ty}(x + $d), $r, $(fld.bitwidth))))
        else
            push!(body.args, :(f === $(QuoteNode(s)) &&
                               return Ptr{$ty}(x + $(fld.bitoffset ÷ 8))))
        end
    end
    push!(body.args, :(return getfield(x, f)))
    push!(out, Expr(:function, :(Base.getproperty(x::Ptr{$sym}, f::Symbol)), body))
    isempty(props) ||
        push!(out, :(Base.propertynames(x::$sym, private::Bool=false) = ($(props...),)))
end

"Collect every symbol a type expression mentions."
function symbols_in!(out::Set{Symbol}, @nospecialize(ex))
    ex isa Symbol && (push!(out, ex); return out)
    ex isa Expr && for a in ex.args; symbols_in!(out, a); end
    return out
end

"""
Parameter names for a wrapper, renamed only where they would shadow their own signature.

glib declares `void g_date_to_struct_tm(GDate*, struct tm*)`, and clang gives the second
parameter the name `tm` — the same name as the struct. Emitted verbatim that is
`ccall(..., (Ptr{GDate}, Ptr{tm}), date, tm)`, where `Ptr{tm}` now resolves to the *argument*
rather than the type, and Julia rejects the whole file with "could not evaluate ccall argument
type". The C name is the readable one, so it is kept unless it actually collides.
"""
function argnames(f::FunctionFacts, tys::Vector, ret)
    used = Set{Symbol}()
    for t in tys; symbols_in!(used, t); end
    symbols_in!(used, ret)
    taken = Set{Symbol}()
    out = Symbol[]
    for (i, (p, _)) in enumerate(f.params)
        a = safe(Symbol(isempty(String(p)) ? "arg$i" : String(p)))
        while a in used || a in taken
            a = Symbol(a, "_")
        end
        push!(taken, a); push!(out, a)
    end
    return out
end

function emit_node(e::Env, n::Node, cuts::Dict{Int,Cut}, out::Vector{Expr}, o::Options)
    f = n.facts
    sym = e.name[n.key]
    if f isa RecordFacts
        emit_record(e, n, cuts, out)
    elseif f isa EnumFacts
        ity = jltype(e, f.integer_type)
        blk = Expr(:block)
        for (nm, v) in f.constants
            push!(blk.args, Expr(:(=), safe(Symbol(nm)), v))
        end
        mac = o.use_julia_native_enum_type ? Symbol("@enum") : Symbol("@cenum")
        push!(out, Expr(:macrocall, mac, nothing, Expr(:(::), sym, ity), blk))
    elseif f isa TypedefFacts
        push!(out, :(const $sym = $(jltype(e, f.underlying))))
    elseif f isa FunctionFacts
        (f.internal && o.skip_static_functions) && return   # `static` has no external symbol
        tys  = [jltype(e, t) for (_, t) in f.params]
        ret  = jltype(e, f.ret)
        args = argnames(f, tys, ret)
        lib = Symbol(o.library_name)
        if f.variadic
            # Only `@ccall` can express varargs, and the call site's types are not known until
            # the call site exists — hence a `@generated` wrapper that splices them in. The
            # `to_c_type_pairs` helper it needs is emitted by `generate` under the same option.
            # Off by default, matching the existing generator, which emits nothing at all here.
            o.wrap_variadic_function || return
            fixed = [Expr(:(::), a, t) for (a, t) in zip(args, tys)]
            inner = Expr(:macrocall, Symbol("@ccall"), nothing,
                         Expr(:(::), Expr(:call, Expr(:., lib, QuoteNode(sym)), fixed...,
                                          Expr(:parameters,
                                               Expr(:$, :(to_c_type_pairs(va_list)...)))), ret))
            push!(out, Expr(:macrocall, Symbol("@generated"), nothing,
                            Expr(:function, Expr(:call, sym, args..., :(va_list...)),
                                 Expr(:block, Meta.quot(inner)))))
            return
        end
        call = Expr(:call, sym, args...)
        body = if o.use_ccall_macro
            pairs = [Expr(:(::), a, t) for (a, t) in zip(args, tys)]
            Expr(:macrocall, Symbol("@ccall"), nothing,
                 Expr(:(::), Expr(:call, Expr(:., lib, QuoteNode(sym)), pairs...), ret))
        else
            :(ccall(($(QuoteNode(sym)), $lib), $ret, ($(tys...),), $(args...)))
        end
        push!(out, Expr(:function, call, Expr(:block, body)))
    end
end

# ------------------------------------------------------------------------------------------
# Macros
# ------------------------------------------------------------------------------------------
"Rewrite every C name in `ex` to the name codegen actually emitted for it."
function rename_symbols(@nospecialize(ex), map::Dict{Symbol,Symbol})
    ex isa Symbol && return get(map, ex, ex)
    ex isa Expr || return ex
    return Expr(ex.head, (a isa QuoteNode || a isa LineNumberNode ? a :
                          rename_symbols(a, map) for a in ex.args)...)
end

"""
Emit translated macros as `const` definitions.

Two guards, both of which the libclang generator learned the hard way (`test/macros.jl`):

  * **A name it will not define is never emitted.** `test/include/macro.h` defined
    `GINTBIG_MAX` in terms of `CPL_STATIC_CAST`, which nothing declares; the generated file
    raised `UndefVarError` at load and the suite did not notice for a long time, because the
    only assertion was that the build logged "Done!".
  * **A macro never shadows a declaration.** `#define FOO 1` beside `struct FOO` would emit
    `const FOO = 1` after `struct FOO`, and Julia rejects redefining the binding.

Names are first rewritten through codegen's own map, so a macro naming `uint32_t` becomes
`UInt32` and one naming a field escaped to `var"end"` follows it, rather than being dropped as
unresolvable.
"""
function emit_macros(io::IO, macros, emitted::Set{Symbol}, renames::Dict{Symbol,Symbol},
                     o::Options)
    n_emitted = 0
    for r in macros
        if r isa CxxMacros.MacroSkipped
            o.add_comment_for_skipped_macro &&
                println(io, "# Skipping MacroDefinition: ", r.name, "  (", r.reason, ")\n")
            continue
        end
        nm = safe(r.name)
        if r.name in emitted
            o.add_comment_for_skipped_macro &&
                println(io, "# Skipping MacroDefinition: ", r.name,
                        "  (a declaration of the same name is already emitted)\n")
            continue
        end
        ex = rename_symbols(r.expr, renames)
        unresolved = Set(s for s in symbols_in!(Set{Symbol}(), ex)
                         if !(s in emitted || isdefined(Base, s) || isdefined(Core, s)))
        if !isempty(unresolved)
            o.add_comment_for_skipped_macro &&
                println(io, "# Skipping MacroDefinition: ", r.name, "  (names nothing we define: ",
                        join(sort!(String.(collect(unresolved))), ", "), ")\n")
            continue
        end
        println(io, string(:(const $nm = $ex))); println(io)
        push!(emitted, r.name)
        n_emitted += 1
    end
    return n_emitted
end

"""
    generate(headers; args=String[], options=Options(), io=stdout)
    generate(nodes;   options=Options(), io=stdout)

Run extract → order → codegen and write a loadable Julia module body.

The second method takes already-extracted nodes. Extraction is the expensive stage and it holds
the only clang handles, so a caller that needs the facts as well — the ABI verifier compares
each emitted type against the `ASTRecordLayout` the facts carry — parses once and emits from the
same node vector rather than parsing twice and hoping the two agree.
"""
function generate(headers::Vector{String}; args::Vector{String}=String[],
                  options::Options=Options(), kw...)
    # Macros need the preprocessor, which `extract` discards, so they are translated in their
    # own parse. Only this method has the headers to do it with; `generate(nodes)` takes the
    # result.
    macros = options.macro_mode == "disable" ? [] :
             CxxMacros.translate_macros(headers, args)
    return generate(extract(headers; args=args); options, macros, kw...)
end

function generate(nodes::Vector{Node}; options::Options=Options(), io::IO=stdout,
                  macros=[])
    o = options
    ord = order_nodes(nodes)
    nm, skip = assign_names(nodes)
    e = Env(Dict(n.key => n for n in nodes), nm, blob_set(nodes), skip)
    bycut = Dict{Key,Dict{Int,Cut}}()
    for c in ord.cuts
        get!(Dict{Int,Cut}, bycut, c.node)[c.field] = c
    end

    isempty(o.module_name) || (println(io, "module ", o.module_name); println(io))
    if !isempty(o.jll_pkg_name)
        println(io, "using ", o.jll_pkg_name); println(io, "export ", o.jll_pkg_name); println(io)
    end
    for j in o.jll_pkg_extra
        println(io, "using ", j); println(io, "export ", j); println(io)
    end
    (!o.use_julia_native_enum_type && o.print_using_CEnum) &&
        (println(io, "using CEnum: CEnum, @cenum"); println(io))
    o.wrap_variadic_function && println(io, """
        to_c_type(t::Type) = t
        to_c_type_pairs(va_list) = map(enumerate(to_c_type.(va_list))) do (ind, type)
            :(va_list[\$ind]::\$type)
        end
        """)
    isempty(o.prologue_file_path) || (println(io, read(o.prologue_file_path, String)); println(io))

    emitted = 0
    bound = Set{Symbol}()          # names this file actually defines, for the macro guards
    renames = Dict{Symbol,Symbol}()
    for k in ord.order
        n = e.bykey[k]
        isempty(String(n.id)) || (renames[n.id] = e.name[k])
        k in e.skip && continue                          # a system typedef Julia already names
        (n.system && !o.generate_isystem_symbols) && continue
        excluded(o, e.name[k]) && continue
        out = Expr[]
        emit_node(e, n, get(bycut, k, Dict{Int,Cut}()), out, o)
        isempty(out) || push!(bound, unescape_name(e.name[k]))
        n.facts isa EnumFacts && for (cn, _) in n.facts.constants; push!(bound, cn); end
        for ex in out
            println(io, string(ex)); println(io)
            emitted += 1
        end
    end

    # Macros last. Nothing declared can refer to a macro — clang expands them before anything
    # reaches the AST — so this is the only position that needs no ordering analysis, and it is
    # the one position where every name a macro might reference is already bound.
    n_macros = emit_macros(io, macros, bound, renames, o)

    isempty(o.epilogue_file_path) || (println(io, read(o.epilogue_file_path, String)); println(io))
    if !isempty(o.export_symbol_prefixes)
        println(io, "const PREFIXES = ", repr(o.export_symbol_prefixes))
        println(io, "for name in names(@__MODULE__; all=true), prefix in PREFIXES")
        println(io, "    if startswith(string(name), prefix)")
        println(io, "        @eval export \$name")
        println(io, "    end")
        println(io, "end")
        println(io)
    end
    isempty(o.module_name) || println(io, "end # module")
    return (; nodes=length(nodes), emitted, cuts=length(ord.cuts), hoisted=ord.hoisted,
              macros=n_macros, macros_seen=length(macros))
end

end # module
