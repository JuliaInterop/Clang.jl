"""
    CxxEmit

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
module CxxEmit

using ..CxxOrder
using ..CxxMacros
using ..CxxFacts
import ..CxxFacts: Key, Node, TypeRef, RecordFacts, TypedefFacts, EnumFacts,
                   FunctionFacts, PointerRef, RecordRef, TypedefRef, EnumRef,
                   ArrayRef, BuiltinRef, FunctionRef, UnknownRef, FieldFacts
import ..CxxOrder: Cut, Ordering

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
    opts::Any                   # ::Options — declared below, so untyped here
    mutable::Set{Key}           # records `auto_mutability` promotes to `mutable struct`
end
Env(bykey, name, blobbed, skip, opts) = Env(bykey, name, blobbed, skip, opts, Set{Key}())

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
    use_julia_bool::Bool            = true
    is_function_strictly_typed::Bool = false
    opaque_as_mutable_struct::Bool  = true
    add_record_constructors::Union{Bool,Vector{String}} = false
    field_access_method_list::Vector{String} = String[]
    library_names::Dict{String,String} = Dict{String,String}()
    extract_c_comment_style::String = "disable"   # "disable" | "raw" | "doxygen"
    fold_single_line_comment::Bool  = false
    show_c_function_prototype::Bool = false
    add_fptr_methods::Bool          = false
    auto_mutability::Bool           = false
    auto_mutability_with_new::Bool  = true
    auto_mutability_includelist::Vector{String} = String[]
    auto_mutability_ignorelist::Vector{String}  = String[]
    "A `node -> Vector{String} -> Vector{String}` hook over the formatted docstring lines."
    callback_documentation::Any     = nothing
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
        use_julia_bool           = Bool(pick(c, "use_julia_bool", true)),
        is_function_strictly_typed = Bool(pick(c, "is_function_strictly_typed", false)),
        opaque_as_mutable_struct = Bool(pick(c, "opaque_as_mutable_struct", true)),
        add_record_constructors  = (v = pick(c, "add_record_constructors", false);
                                    v isa Bool ? v : String.(v)),
        field_access_method_list = String.(pick(c, "field_access_method_list", String[])),
        # `library_names` lives under [general] in every generator.toml, unlike the rest of the
        # codegen keys — matching the existing reader rather than tidying it.
        library_names            = Dict{String,String}(string(k) => string(v)
                                                       for (k, v) in pick(g, "library_names",
                                                                          Dict{String,Any}())),
        macro_mode               = string(pick(get(c, "macro", Dict{String,Any}()),
                                               "macro_mode", "basic")),
        extract_c_comment_style  = string(pick(c, "extract_c_comment_style", "disable")),
        fold_single_line_comment = Bool(pick(c, "fold_single_line_comment", false)),
        show_c_function_prototype = Bool(pick(c, "show_c_function_prototype", false)),
        # Not a TOML value — a Julia `Function` a caller poked into the options dict beside the
        # scalars. MPI.jl's driver does this (see `test/test_mpi.jl`), and it is one of the
        # signals that the TOML surface is under-expressive (GENERATORS-REWORK.md).
        callback_documentation   = pick(g, "callback_documentation", nothing),
        add_fptr_methods         = Bool(pick(g, "add_fptr_methods", false)),
        auto_mutability          = Bool(pick(g, "auto_mutability", false)),
        auto_mutability_with_new = Bool(pick(g, "auto_mutability_with_new", true)),
        # Both lists carry a silent legacy alias, kept because downstream configs still use it.
        auto_mutability_includelist =
            String.(pick(g, "auto_mutability_includelist",
                         pick(g, "auto_mutability_whitelist", String[]))),
        auto_mutability_ignorelist =
            String.(pick(g, "auto_mutability_ignorelist",
                         pick(g, "auto_mutability_blacklist", String[]))),
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
        # `_Bool` is one byte, so `Bool` and `UInt8` are ABI-identical; the choice is about
        # whether the wrapper reads as Julia or as C.
        t.name === :bool && return e.opts.use_julia_bool ? :Bool : :UInt8
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

"The record a type ultimately names, following pointers and typedefs; 0 if it names none."
function leaf_record(bykey::Dict{Key,Node}, t::TypeRef, depth::Int=0)
    depth > 8 && return Key(0)
    t isa PointerRef && return leaf_record(bykey, t.pointee, depth + 1)
    t isa ArrayRef && return leaf_record(bykey, t.elem, depth + 1)
    t isa RecordRef && return t.key
    if t isa TypedefRef
        n = get(bykey, t.key, nothing)
        n !== nothing && n.facts isa TypedefFacts &&
            return leaf_record(bykey, n.facts.underlying, depth + 1)
    end
    return Key(0)
end

is_integerish(t::TypeRef) = t isa BuiltinRef &&
    t.name in (:char, :schar, :uchar, :short, :ushort, :int, :uint, :long, :ulong,
               :longlong, :ulonglong, :int128, :uint128, :bool)

"""
Records `auto_mutability` should emit as `mutable struct`, by the existing pass's criterion.

A record stays immutable exactly when some function takes it **by pointer** while also taking an
integer — the pointer+length shape, where the caller wants an array of them and an immutable
struct is what makes that work. Otherwise a mutable struct is friendlier, since `Ref` on it
gives a stable address to hand to C.

The libclang pass spells this over cursors and `node.adj` indices; with resolved `TypeRef`s the
same rule is a direct question about each parameter's leaf type.
"""
function mutable_set(nodes::Vector{Node}, o::Options)
    bykey = Dict(n.key => n for n in nodes)
    recs = Set{Key}(n.key for n in nodes if n.facts isa RecordFacts && n.facts.complete)
    # "Pinned" covers all three of the pass's reset conditions at once: a record never taken as
    # a parameter, or never taken by pointer, or never taken by pointer beside an integer, is
    # simply absent from this set.
    pinned = Set{Key}()
    for n in nodes
        f = n.facts
        f isa FunctionFacts || continue
        any(is_integerish(t) for (_, t) in f.params) || continue
        for (_, t) in f.params
            t isa PointerRef || continue
            k = leaf_record(bykey, t)
            k in recs && push!(pinned, k)
        end
    end
    out = Set{Key}()
    for n in nodes
        n.key in recs || continue
        nm = String(n.id)
        nm in o.auto_mutability_ignorelist && continue   # the ignorelist always wins
        (nm in o.auto_mutability_includelist || n.key ∉ pinned) && push!(out, n.key)
    end
    return out
end

"""
Emit a record. `cuts` are the field substitutions the ordering pass decided, applied here — the
single place a degraded field is realised, so the cut and the emitted type cannot disagree.
"""
function emit_record(e::Env, n::Node, cuts::Dict{Int,Cut}, out::Vector{Expr})
    f = n.facts::RecordFacts
    sym = e.name[n.key]
    o = e.opts
    if !f.complete
        # A mutable struct with no fields is a distinct nominal type, so `Ptr{Foo}` stays
        # meaningful; `const Foo = Cvoid` collapses every opaque handle to `Ptr{Cvoid}`.
        push!(out, o.opaque_as_mutable_struct ? :(mutable struct $sym end) :
                   :(const $sym = Cvoid))
        return
    end
    if n.key in e.blobbed
        unit, count = blob_storage(f)
        push!(out, :(struct $sym; data::NTuple{$count,$unit}; end))
        emit_accessors(e, n, out)
        wants_constructor(o, sym) && emit_constructor(e, n, out)
        return
    end
    body = Expr(:block)
    for (i, fld) in enumerate(f.fields)
        ty = haskey(cuts, i) ? jltype(e, cuts[i].replacement) : jltype(e, fld.type)
        push!(body.args, Expr(:(::), safe(Symbol(fld.name)), ty))
    end
    mut = n.key in e.mutable
    # A mutable struct has no implicit all-field constructor unless one is written, so
    # `auto_mutability_with_new` adds it back; without it the type cannot be built from Julia.
    if mut && o.auto_mutability_with_new && !isempty(f.fields)
        fsyms = [safe(Symbol(fl.name)) for fl in f.fields]
        push!(body.args, Expr(:(=), Expr(:call, sym, fsyms...),
                              Expr(:call, :new, fsyms...)))
    end
    push!(out, Expr(:struct, mut, sym, body))
    if String(sym) in o.field_access_method_list
        # A plain struct already has field access by value; this adds the POINTER accessors, so
        # a `Ptr{T}` into C-owned memory can be read and written field-wise without a copy.
        # Emitted AFTER the struct — the methods name `Ptr{$sym}` in their own signature.
        emit_accessors(e, n, out)
    end
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
    isempty(props) && return
    # Read-only accessors make a record inspectable but not usable. `getproperty` on a pointer
    # hands back a `Ptr` for a plain field and a `(ptr, shift, width)` triple for a bit-field,
    # so both the write side and the by-value read side dispatch on which it got.
    push!(out, :(function Base.setproperty!(x::Ptr{$sym}, f::Symbol, v)
                     r = getproperty(x, f)
                     r isa Ptr ? unsafe_store!(r, v) : _bitfield_store!(r..., v)
                 end))
    # By value: `toBitfield(m).a` has to work on the struct the ccall returned, not only on a
    # pointer into C-owned memory.
    push!(out, :(function Base.getproperty(x::$sym, f::Symbol)
                     f === :data && return getfield(x, :data)
                     r = Ref(x)
                     GC.@preserve r begin
                         p = Base.unsafe_convert(Ptr{$sym}, r)
                         q = getproperty(p, f)
                         return q isa Ptr ? unsafe_load(q) : _bitfield_load(q...)
                     end
                 end))
    push!(out, :(Base.propertynames(x::$sym, private::Bool=false) = ($(props...),)))
end

"""
The bit-field load/store pair, emitted once per file when any record needs it.

A bit-field accessor cannot be a plain `unsafe_load`: the value shares a storage word with its
neighbours, so reading is shift-and-mask and writing is read-modify-write. Signed bit-fields
additionally need sign extension — `int d : 3` holding -4 is the bit pattern `0b100`, which
loads as 4 without it.
"""
const BITFIELD_HELPERS = """
function _bitfield_load(p::Ptr{T}, off::Int, width::Int) where {T}
    mask = (T(1) << width) - T(1)
    v = (unsafe_load(p) >> off) & mask
    if T <: Signed && width > 0 && (v & (T(1) << (width - 1))) != 0
        v |= ~mask                      # sign-extend
    end
    return v
end

function _bitfield_store!(p::Ptr{T}, off::Int, width::Int, v) where {T}
    mask = (T(1) << width) - T(1)
    old = unsafe_load(p)
    unsafe_store!(p, (old & ~(mask << off)) | (((v % T) & mask) << off))
end
"""

"Does any record in this set carry a bit-field?"
needs_bitfield_helpers(nodes::Vector{Node}) =
    any(n -> n.facts isa RecordFacts && any(fl -> fl.bitwidth >= 0, n.facts.fields), nodes)

"Is this record on the `add_record_constructors` list (or is the option simply `true`)?"
wants_constructor(o::Options, sym::Symbol) =
    o.add_record_constructors isa Bool ? o.add_record_constructors :
    String(sym) in o.add_record_constructors

"""
A by-field constructor for a record stored as opaque bytes.

A plain struct gets Julia's default constructor for free; a blob does not — its only field is
the byte tuple. This writes the fields through the pointer accessors, which is the one path that
already knows each field's real offset.
"""
function emit_constructor(e::Env, n::Node, out::Vector{Expr})
    f = n.facts::RecordFacts
    sym = e.name[n.key]
    # Bit-fields ARE included: `ptr.d = d` reaches the bit-field-aware `setproperty!`, and a
    # constructor that silently dropped them would build a half-initialised record.
    named = [fl for fl in f.fields if !isempty(String(fl.name))]
    isempty(named) && return
    syms = [safe(Symbol(fl.name)) for fl in named]
    body = Expr(:block, :(ref = Ref{$sym}()),
                :(ptr = Base.unsafe_convert(Ptr{$sym}, ref)))
    for s in syms
        push!(body.args, :(ptr.$s = $s))
    end
    push!(body.args, :(ref[]))
    push!(out, Expr(:function,
                    Expr(:call, sym,
                         (Expr(:(::), s, jltype(e, fl.type)) for (s, fl) in zip(syms, named))...),
                    body))
end

"""
The library a function should be `ccall`ed through.

`library_names` maps a filename-suffix regex to a library, so one run can wrap several
libraries whose headers were parsed together — which is why a `Node` carries its file.
"""
function library_for(o::Options, n::Node)
    name = o.library_name
    if !isempty(o.library_names)
        for (pat, lib) in o.library_names
            if endswith(normpath(n.file), Regex(pat))
                name = lib
                break
            end
        end
    end
    # PARSED as Julia, not turned straight into a Symbol. `libfoo` is an identifier the caller
    # will bind, but a caller may equally give a quoted path — `"\"/abs/path/libfoo\""` — to
    # `ccall` a library by location with nothing to bind. `test/test_bitfield.jl` does exactly
    # that, and `Symbol` on it yields an identifier whose name contains quote marks.
    return try
        Meta.parse(name)
    catch
        Symbol(name)
    end
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
        lib = library_for(o, n)
        # `foo(a::Cint)` instead of `foo(a)`: the ccall converts either way, but the typed form
        # rejects a wrong argument at the call site rather than inside the C library.
        sig = o.is_function_strictly_typed ?
              [Expr(:(::), a, t) for (a, t) in zip(args, tys)] : args
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
                            Expr(:function, Expr(:call, sym, sig..., :(va_list...)),
                                 Expr(:block, Meta.quot(inner)))))
            return
        end
        pairs = [Expr(:(::), a, t) for (a, t) in zip(args, tys)]
        # `target === nothing` means the usual `(:name, lib)` pair; anything else is an
        # expression naming an already-resolved address.
        function mkbody(target)
            if o.use_ccall_macro
                callee = target === nothing ? Expr(:., lib, QuoteNode(sym)) : Expr(:$, target)
                return Expr(:macrocall, Symbol("@ccall"), nothing,
                            Expr(:(::), Expr(:call, callee, pairs...), ret))
            end
            callee = target === nothing ? :(($(QuoteNode(sym)), $lib)) : target
            return :(ccall($callee, $ret, ($(tys...),), $(args...)))
        end
        push!(out, Expr(:function, Expr(:call, sym, sig...), Expr(:block, mkbody(nothing))))
        # An extra method taking the resolved symbol address, for callers that dlopen the
        # library themselves rather than naming it at compile time.
        o.add_fptr_methods && push!(out,
            Expr(:function, Expr(:call, sym, sig..., :fptr), Expr(:block, mkbody(:fptr))))
    end
end

# ------------------------------------------------------------------------------------------
# Doc comments
# ------------------------------------------------------------------------------------------
"""
Strip C comment markers, leaving the text.

clang hands back the comment exactly as written, markers and all, and may concatenate several
consecutive comments into one block — so this has to cope with `//`, `///`, `/**`, a leading `*`
on continuation lines, and a trailing `*/`, in any combination.
"""
function strip_comment_markers(s::AbstractString)
    out = String[]
    for line in split(s, '\n')
        t = strip(line)
        # The single optional space after each marker is the separator, not indentation:
        # `/// One line.` is "One line.", never " One line.".
        t = replace(t, r"^/\*+!?<?\s?" => "")   # /*  /**  /*!  /**<
        t = replace(t, r"\*+/\s*$" => "")       # */
        t = replace(t, r"^/{2,}!?<?\s?" => "")  # //  ///  //!  ///<
        t = replace(t, r"^\*\s?" => "")         #  * continuation
        push!(out, rstrip(t))
    end
    while !isempty(out) && isempty(first(out)); popfirst!(out); end
    while !isempty(out) && isempty(last(out)); pop!(out); end
    return out
end

"Doxygen commands that map onto a Markdown section heading."
const DOXYGEN_SECTIONS = Dict("brief" => "", "details" => "", "return" => "### Returns",
                              "returns" => "### Returns", "note" => "!!! note",
                              "warning" => "!!! warning", "see" => "### See also",
                              "sa" => "### See also", "bug" => "!!! warning \"Bug\"",
                              "deprecated" => "!!! warning \"Deprecated\"",
                              "todo" => "!!! info \"TODO\"", "since" => "### Since")

"""
Render a doc comment as Markdown lines.

`"raw"` strips the markers and stops. `"doxygen"` additionally turns the commands that carry
structure into Markdown: `\\param` becomes a bullet list, `\\return` and `\\note` become
sections. This is a smaller renderer than `src/generator/documentation.jl`, so a `"doxygen"`
docstring will not be character-identical to the old pass — it carries the same information in
the same order.
"""
function format_doc(raw::AbstractString, style::AbstractString)
    isempty(strip(raw)) && return String[]
    lines = strip_comment_markers(raw)
    style == "doxygen" || return lines
    out = String[]
    params = String[]
    admonition = false          # inside a `!!!` block, whose body must stay indented
    for line in lines
        m = match(r"^[\\@](\w+)\s*(.*)$", line)
        if m !== nothing && (m[1] == "param" || m[1] == "tparam")
            admonition = false
            p = match(r"^(\[[^\]]*\]\s*)?(\S+)\s*(.*)$", m[2])
            p === nothing || push!(params, "* `$(p[2])`:$(isempty(p[3]) ? "" : " " * p[3])")
            continue
        elseif m !== nothing && haskey(DOXYGEN_SECTIONS, m[1])
            head = DOXYGEN_SECTIONS[m[1]]
            # A Documenter admonition's body is the INDENTED block under it. Emitted flush
            # left, `!!! warning "Bug"` renders as an empty admonition followed by an unrelated
            # paragraph — which is how it first came out.
            admonition = startswith(head, "!!!")
            isempty(head) || (push!(out, ""); push!(out, head))
            isempty(m[2]) || push!(out, admonition ? "    " * m[2] : m[2])
            continue
        elseif m !== nothing
            admonition = false      # an unrecognised command ends the block
        end
        push!(out, admonition && !isempty(line) ? "    " * line : line)
    end
    if !isempty(params)
        push!(out, ""); push!(out, "### Parameters"); append!(out, params)
    end
    # Doxygen convention puts a blank line between every command; once the commands become
    # headings those blanks stack up two and three deep.
    out = [l for (i, l) in enumerate(out) if !isempty(l) || (i > 1 && !isempty(out[i - 1]))]
    while !isempty(out) && isempty(first(out)); popfirst!(out); end
    while !isempty(out) && isempty(last(out)); pop!(out); end
    return out
end

"`\$` and `\\` are interpolation and escape inside a Julia string; so is `\"` before `\"\"`."
const DOC_ESCAPE = r"""(\$|\\|"(?=""))"""
escape_doc(line) = replace(line, DOC_ESCAPE => s"\\\1")

"""
The C declaration, reconstructed from facts, for `show_c_function_prototype`.

Spelled from the same `TypeRef`s codegen uses, so it describes what was actually wrapped rather
than re-reading the header — which is the point of showing it at all.
"""
function c_prototype(e::Env, n::Node)
    f = n.facts::FunctionFacts
    ps = [string(c_spelling(e, t), isempty(String(p)) ? "" : " " * String(p)) for (p, t) in f.params]
    f.variadic && push!(ps, "...")
    isempty(ps) && push!(ps, "void")
    return string(c_spelling(e, f.ret), " ", n.id, "(", join(ps, ", "), ");")
end

const C_BUILTIN = Dict(:void=>"void", :bool=>"_Bool", :char=>"char", :schar=>"signed char",
                       :uchar=>"unsigned char", :short=>"short", :ushort=>"unsigned short",
                       :int=>"int", :uint=>"unsigned int", :long=>"long",
                       :ulong=>"unsigned long", :longlong=>"long long",
                       :ulonglong=>"unsigned long long", :float=>"float", :double=>"double",
                       :longdouble=>"long double", :int128=>"__int128",
                       :uint128=>"unsigned __int128", :wchar=>"wchar_t",
                       :char16=>"char16_t", :char32=>"char32_t")

function c_spelling(e::Env, t::TypeRef, depth::Int=0)
    depth > 8 && return "..."
    t isa BuiltinRef && return get(C_BUILTIN, t.name, "int")
    t isa PointerRef && return c_spelling(e, t.pointee, depth + 1) * " *"
    t isa ArrayRef && return c_spelling(e, t.elem, depth + 1) * (t.len < 0 ? "[]" : "[$(t.len)]")
    t isa FunctionRef && return c_spelling(e, t.ret, depth + 1) * " (*)(...)"
    t isa UnknownRef && return t.spelling
    if t isa RecordRef || t isa EnumRef || t isa TypedefRef
        n = get(e.bykey, t.key, nothing)
        n === nothing && return "void"
        n.facts isa RecordFacts && return string(n.facts.kind, " ", n.id)
        n.facts isa EnumFacts && return "enum $(n.id)"
        return String(n.id)
    end
    return "void"
end

"""
The full docstring for a node: comment, then the C prototype, then the user's callback.

The callback runs **last** and sees everything, so it can rewrite or replace the whole thing.
It also runs when no comment was extracted, so a callback can supply documentation the header
never had — which is what MPI.jl's driver uses it for.
"""
function docfor(e::Env, n::Node, o::Options)
    lines = o.extract_c_comment_style == "disable" ? String[] :
            format_doc(n.doc, o.extract_c_comment_style)
    if o.show_c_function_prototype && n.facts isa FunctionFacts
        isempty(lines) || push!(lines, "")
        append!(lines, ["### Prototype", "```c", c_prototype(e, n), "```"])
    end
    o.callback_documentation === nothing && return lines
    return collect(String, o.callback_documentation(n, lines))
end

"Write a docstring immediately before the definition it documents."
function print_doc(io::IO, lines::Vector{String}, o::Options)
    isempty(lines) && return
    lines = escape_doc.(lines)
    if length(lines) == 1 && o.fold_single_line_comment
        println(io, "\"\"\"", only(lines), "\"\"\"")
        return
    end
    println(io, "\"\"\"")
    for l in lines; println(io, l); end
    println(io, "\"\"\"")
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
    generate(headers; args=String[], options=Options(), io=stdout, api_io=nothing)
    generate(nodes;   options=Options(), io=stdout, api_io=nothing)

Run extract → order → codegen and write a loadable Julia module body.

The second method takes already-extracted nodes. Extraction is the expensive stage and it holds
the only clang handles, so a caller that needs the facts as well — the ABI verifier compares
each emitted type against the `ASTRecordLayout` the facts carry — parses once and emits from the
same node vector rather than parsing twice and hoping the two agree.

Passing `api_io` splits the output the way `output_api_file_path` /
`output_common_file_path` do: function wrappers there, everything else to `io`.
"""
function generate(headers::Vector{String}; args::Vector{String}=String[],
                  options::Options=Options(), kw...)
    # Macros need the preprocessor, which `extract` discards, so they are translated in their
    # own parse. Only this method has the headers to do it with; `generate(nodes)` takes the
    # result.
    macros = options.macro_mode == "disable" ? [] :
             CxxMacros.translate_macros(headers, args)
    nodes = extract(headers; args=args,
                    comments=options.extract_c_comment_style != "disable")
    return generate(nodes; options, macros, kw...)
end

function generate(nodes::Vector{Node}; options::Options=Options(), io::IO=stdout,
                  macros=[], api_io::Union{Nothing,IO}=nothing)
    o = options
    ord = order_nodes(nodes)
    nm, skip = assign_names(nodes)
    e = Env(Dict(n.key => n for n in nodes), nm, blob_set(nodes), skip, o,
            o.auto_mutability ? mutable_set(nodes, o) : Set{Key}())
    bycut = Dict{Key,Dict{Int,Cut}}()
    for c in ord.cuts
        get!(Dict{Int,Cut}, bycut, c.node)[c.field] = c
    end

    # Split mode: function wrappers to `api_io`, everything else (macros included) to `io`.
    # As in the existing `FunctionPrinter`/`CommonPrinter` pair, neither file gets a module
    # wrapper, `using CEnum`, prologue or epilogue — a caller who splits the output is
    # assembling the module themselves and would otherwise get two of each.
    split = api_io !== nothing
    if !split

    isempty(o.module_name) || (println(io, "module ", o.module_name); println(io))
    if !isempty(o.jll_pkg_name)
        println(io, "using ", o.jll_pkg_name); println(io, "export ", o.jll_pkg_name); println(io)
    end
    for j in o.jll_pkg_extra
        println(io, "using ", j); println(io, "export ", j); println(io)
    end
    (!o.use_julia_native_enum_type && o.print_using_CEnum) &&
        (println(io, "using CEnum: CEnum, @cenum"); println(io))
    needs_bitfield_helpers(nodes) && (println(io, BITFIELD_HELPERS); println(io))
    o.wrap_variadic_function && println(io, """
        to_c_type(t::Type) = t
        to_c_type_pairs(va_list) = map(enumerate(to_c_type.(va_list))) do (ind, type)
            :(va_list[\$ind]::\$type)
        end
        """)
    isempty(o.prologue_file_path) || (println(io, read(o.prologue_file_path, String)); println(io))

    end # if !split

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
        dest = (split && n.facts isa FunctionFacts) ? api_io : io
        for (i, ex) in enumerate(out)
            # The docstring goes on the node's FIRST expression — the definition itself. The
            # accessors and constructors that follow are machinery, not separate API.
            i == 1 && print_doc(dest, docfor(e, n, o), o)
            println(dest, string(ex)); println(dest)
            emitted += 1
        end
    end

    # Macros last. Nothing declared can refer to a macro — clang expands them before anything
    # reaches the AST — so this is the only position that needs no ordering analysis, and it is
    # the one position where every name a macro might reference is already bound.
    n_macros = emit_macros(io, macros, bound, renames, o)

    if split
        return (; nodes=length(nodes), emitted, cuts=length(ord.cuts), hoisted=ord.hoisted,
                  macros=n_macros, macros_seen=length(macros))
    end

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
