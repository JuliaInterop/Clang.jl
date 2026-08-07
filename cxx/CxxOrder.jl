"""
    CxxOrder

Emission ordering for the extracted node set — `ORDERING-DESIGN.md` §3.2 and §3.2a.

Julia has no forward declarations, so a single-file wrapper needs every definition-time type
position to be already bound: struct field types, `const` right-hand sides, `ccall` type
arguments and method signatures. This produces that order, and where a genuine cycle makes one
impossible, it breaks the cycle **and records the field it degraded in the same step**.

That atomicity is the point. In the libclang pipeline the edge is deleted in
`RemoveCircularReference` while whether to erase the field is decided later in codegen by an
index comparison, so the two can disagree — which is exactly how a naive fix to the libxml2
cycle bug produced `bar::foo` before `const foo = …` and an unloadable file.

Two other properties this keeps, both measured:

  * **Minimal perturbation.** C already forbids a non-pointer struct member of an incomplete
    type, so C source order is a valid topological order for every non-pointer edge. The walk
    runs in source order and moves a declaration only when an edge forces it.
  * **Self-edges need no repair.** `struct B; x::Ptr{B}; end` is legal Julia, so a node
    referring to itself imposes no constraint.
"""
module CxxOrder

include(joinpath(@__DIR__, "CxxFacts.jl"))
using .CxxFacts
import .CxxFacts: Key, Node, TypeRef, RecordFacts, TypedefFacts, EnumFacts, FunctionFacts,
                  PointerRef, RecordRef, TypedefRef, EnumRef, ArrayRef, BuiltinRef, FieldFacts

export order_nodes, Ordering, Cut

"""
A broken dependency, recorded where it was made.

`replacement` is what the field's type becomes; `tier` is 1 for canonical substitution (the
typedef's own pointer type, no placeholder needed) and 2 for an opaque placeholder, which also
needs a repair method emitted after both records exist.
"""
struct Cut
    node::Key
    field::Int
    replacement::TypeRef
    tier::Int
    why::String
end

struct Ordering
    order::Vector{Key}        # emission order
    cuts::Vector{Cut}
    hoisted::Int              # declarations that had to move from their source position
end

const UNSEEN, ONSTACK, DONE = 0, 1, 2

"""
Definition-time edges of a node, as `(key, pointer_mediated, field_index)`.

`field_index` is 0 for anything that is not a record field — nothing else can be degraded, so
nothing else is a candidate for a cut.
"""
function order_edges(n::Node)
    out = Tuple{Key,Bool,Int}[]
    f = n.facts
    if f isa RecordFacts
        for (i, fld) in enumerate(f.fields)
            for (k, viaptr) in CxxFacts.deps(fld.type)
                push!(out, (k, viaptr, i))
            end
        end
    else
        for (k, viaptr) in CxxFacts.deps(n)
            push!(out, (k, viaptr, 0))
        end
    end
    return out
end

"Replace every `TypedefRef(k)` inside `t` with the typedef's own underlying type."
function desugar_typedef(bykey::Dict{Key,Node}, t::TypeRef, k::Key)
    if t isa TypedefRef && t.key == k
        n = get(bykey, k, nothing)
        return (n !== nothing && n.facts isa TypedefFacts) ? n.facts.underlying : t
    elseif t isa PointerRef
        return PointerRef(desugar_typedef(bykey, t.pointee, k))
    elseif t isa ArrayRef
        return ArrayRef(desugar_typedef(bykey, t.elem, k), t.len)
    end
    return t
end

"""
Can `t` reach declaration `v`, and does every route cross a pointer?

`deps` is deliberately shallow — it reports an edge *to* a typedef node, never through it,
because the ordering graph needs the typedef itself as a vertex. But pointer-mediation is a
property of the canonical spine, and a field typed `xmlSchemaTypePtr` is pointer-mediated even
though its top-level `TypedefRef` says nothing about that. This walks through typedef nodes to
answer it, which is what tier 2 must ask before declaring a cycle unbreakable.
"""
function reaches_via_pointer(bykey::Dict{Key,Node}, t::TypeRef, v::Key,
                             viaptr::Bool=false, seen::Set{Key}=Set{Key}())
    if t isa PointerRef
        return reaches_via_pointer(bykey, t.pointee, v, true, seen)
    elseif t isa ArrayRef
        return reaches_via_pointer(bykey, t.elem, v, viaptr, seen)
    elseif t isa RecordRef || t isa EnumRef
        return t.key == v && viaptr
    elseif t isa TypedefRef
        t.key == v && return viaptr
        t.key in seen && return false
        push!(seen, t.key)
        n = get(bykey, t.key, nothing)
        (n !== nothing && n.facts isa TypedefFacts) || return false
        return reaches_via_pointer(bykey, n.facts.underlying, v, viaptr, seen)
    end
    return false
end

"Does `t` still mention `k` after desugaring? (i.e. did the substitution actually help?)"
mentions(t::TypeRef, k::Key) = any(p -> first(p) == k, CxxFacts.deps(t))

"""
Break the back-edge `u -> v`, returning the index of the field cut, or 0 if `u` has none.

Tier 1 — canonical substitution. If `u` reaches `v` through a **typedef**, replace that typedef
inside the field's type with the typedef's own underlying type. The typedef node leaves the
field's dependencies and the cycle dissolves with no placeholder and no repair. This covers
both shapes measured in the fixtures: a bare `foo bar` (method-ambiguity.h, becoming
`Ptr{foo_struct}`) and a `B *x` written through a typedef (cycle-detection.h, becoming
`Ptr{B}` — which is exactly what the current generator emits).

Tier 2 — opaque placeholder. Only when no typedef sits on the path: degrade a pointer-mediated
field to `Ptr{Cvoid}`, which needs a typed accessor emitted afterwards.
"""
function break_edge!(cuts::Vector{Cut}, bykey::Dict{Key,Node}, u::Key, v::Key,
                     suppressed::Set{Tuple{Key,Int}}, hard::Set{Tuple{Key,Int}})
    n = bykey[u]
    n.facts isa RecordFacts || return 0
    # Tier 1
    for (i, fld) in enumerate(n.facts.fields)
        (u, i) in suppressed && continue
        mentions(fld.type, v) || continue
        for (k, _) in CxxFacts.deps(fld.type)
            tn = get(bykey, k, nothing)
            (tn !== nothing && tn.facts isa TypedefFacts) || continue
            sub = desugar_typedef(bykey, fld.type, k)
            mentions(sub, k) && continue          # substitution did not remove the reference
            push!(cuts, Cut(u, i, sub, 1,
                  "field `$(fld.name)`: substituted typedef `$(tn.id)` with its underlying type"))
            return i
        end
    end
    # Tier 2. Pointer-mediation must be judged on the CANONICAL spine, not on whether the
    # field's top-level type is syntactically a PointerRef -- `deps` already carries that flag
    # through typedefs and arrays. Testing the top level only is precisely the libclang bug
    # that makes RemoveCircularReference abort on libxml2 (ORDERING-DESIGN.md §2.0); it is easy
    # to reproduce by accident.
    for (i, fld) in enumerate(n.facts.fields)
        # NOT `suppressed`: a tier-1 substitution replaces `foo bar` with `Ptr{Foo} bar`, which
        # can introduce the very edge that must now be cut. Only a field already degraded to
        # Ptr{Cvoid} is off limits, since there is nothing left to erase.
        (u, i) in hard && continue
        reaches_via_pointer(bykey, fld.type, v) || continue
        push!(cuts, Cut(u, i, PointerRef(BuiltinRef(:void)), 2,
              "field `$(fld.name)` degraded to Ptr{Cvoid}; needs a typed accessor"))
        return i
    end
    return 0
end

"""
    order_nodes(nodes) -> Ordering

Order `nodes` for emission. Throws when a cycle cannot be broken, naming the path — replacing
the libclang pipeline's fixed 100000-iteration budget with a diagnosable error.
"""
function order_nodes(nodes::Vector{Node})
    bykey = Dict{Key,Node}(n.key => n for n in nodes)
    pos = Dict{Key,Int}(n.key => i for (i, n) in enumerate(nodes))
    state = Dict{Key,Int}(n.key => UNSEEN for n in nodes)
    cuts = Cut[]
    suppressed = Set{Tuple{Key,Int}}()
    hard = Set{Tuple{Key,Int}}()   # fields already degraded to Ptr{Cvoid}
    # A cut REPLACES a field's type; it does not delete the field. Substituting
    # `xmlSchemaTypePtr` yields `Ptr{xmlSchemaType}`, which still depends on `xmlSchemaType` --
    # so the field's remaining dependencies must keep constraining the order. Suppressing the
    # whole field instead let libxml2 emit a reference to a type ordered later.
    applied = Dict{Tuple{Key,Int},TypeRef}()

    edges = Dict{Key,Vector{Tuple{Key,Bool,Int}}}(n.key => order_edges(n) for n in nodes)
    function live(u)
        out = Tuple{Key,Bool,Int}[]
        for (k, p, fi) in edges[u]
            haskey(applied, (u, fi)) && continue      # replaced: recomputed below
            (haskey(bykey, k) && k != u) || continue
            push!(out, (k, p, fi))
        end
        for ((n_, fi), t) in applied
            n_ == u || continue
            for (k, p) in CxxFacts.deps(t)
                (haskey(bykey, k) && k != u) || continue
                push!(out, (k, p, fi))
            end
        end
        return out
    end

    order = Key[]
    for root in nodes
        state[root.key] == DONE && continue
        stack = Key[root.key]; iter = Int[1]; state[root.key] = ONSTACK
        while !isempty(stack)
            u = last(stack); adj = live(u)
            if last(iter) <= length(adj)
                (v, _, _) = adj[last(iter)]; iter[end] += 1
                state[v] == DONE && continue
                if state[v] == ONSTACK
                    # A back edge. Cut THIS edge rather than an arbitrary one on the path:
                    # it is a local decision, it guarantees progress, and it keeps every DONE
                    # mark valid -- DONE is monotone under edge removal. The libclang pass
                    # instead discards all marks and restarts, up to 100000 times.
                    j = findfirst(==(v), stack)
                    path = stack[j:end]
                    # Prefer cutting the back edge itself -- a local decision that keeps every
                    # DONE mark valid. But the edge can originate at a node with no field to
                    # degrade (a typedef, as in cycle-detection.h where the cycle is
                    # `typedef B` -> `struct B` -> `typedef B`), so fall back to any record on
                    # the cycle path.
                    cut_at, fi = u, break_edge!(cuts, bykey, u, v, suppressed, hard)
                    if fi == 0
                        for (idx, p) in enumerate(path)
                            nxt = idx < length(path) ? path[idx + 1] : v
                            f2 = break_edge!(cuts, bykey, p, nxt, suppressed, hard)
                            if f2 != 0
                                cut_at, fi = p, f2
                                break
                            end
                        end
                    end
                    fi == 0 && error("unbreakable cycle: " *
                                     join((string(bykey[p].id) for p in path), " -> ") *
                                     " -> " * string(bykey[v].id))
                    push!(suppressed, (cut_at, fi))
                    last(cuts).tier == 2 && push!(hard, (cut_at, fi))
                    applied[(cut_at, fi)] = last(cuts).replacement
                    if cut_at == u
                        iter[end] = 1            # re-scan u with the edge gone
                    else
                        # the cut is further up the path: unwind to it and resume there
                        while last(stack) != cut_at
                            state[pop!(stack)] = UNSEEN; pop!(iter)
                        end
                        iter[end] = 1
                    end
                    continue
                end
                push!(stack, v); push!(iter, 1); state[v] = ONSTACK
            else
                state[u] = DONE; push!(order, u); pop!(stack); pop!(iter)
            end
        end
    end

    hoisted = count(i -> order[i] != nodes[i].key, eachindex(order))
    return Ordering(order, cuts, hoisted)
end

end # module
