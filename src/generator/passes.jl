"""
    AbstractPass
Supertype for all passes.
"""
abstract type AbstractPass end

"""
    CollectTopLevelNode <: AbstractPass
In this pass, all tags and identifiers in all translation units are collected for
CTU analysis.

See also [`collect_top_level_nodes!`](@ref).
"""
mutable struct CollectTopLevelNode <: AbstractPass
    trans_units::Vector{TranslationUnit}
    dependent_headers::Vector{String}
    system_dirs::Vector{String}
    show_info::Bool
end
CollectTopLevelNode(tus, dhs, sys; info=false) = CollectTopLevelNode(tus, dhs, sys, info)

function (x::CollectTopLevelNode)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    is_local_only = get(general_options, "is_local_header_only", true)
    show_info = get(log_options, "CollectTopLevelNode_log", x.show_info)

    empty!(dag.nodes)
    empty!(dag.sys)
    for tu in x.trans_units
        tu_cursor = getTranslationUnitCursor(tu)
        header_name = spelling(tu_cursor) |> normpath
        @info "Processing header: $header_name"
        for cursor in children(tu_cursor)
            file_name = get_filename(cursor) |> normpath
            if is_local_only && header_name != file_name && file_name ∉ x.dependent_headers
                if any(sysdir->startswith(file_name, sysdir), x.system_dirs)
                    collect_top_level_nodes!(dag.sys, cursor, general_options)
                end
                continue
            end
            collect_top_level_nodes!(dag.nodes, cursor, general_options)
        end
    end

    return dag
end

"""
    CollectDependentSystemNode <: AbstractPass
In this pass, those dependent tags/identifiers are to the `dag.nodes`.

See also [`collect_system_nodes!`](@ref).
"""
mutable struct CollectDependentSystemNode <: AbstractPass
    dependents::Dict{ExprNode,Int}
    show_info::Bool
end
CollectDependentSystemNode(; info=true) = CollectDependentSystemNode(Dict{ExprNode,Int}(), info)

# FIXME: refactor and improve the support for system nodes
function (x::CollectDependentSystemNode)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "CollectDependentSystemNode_log", x.show_info)

    empty!(x.dependents)
    for node in dag.nodes
        collect_dependent_system_nodes!(dag, node, x.dependents)
    end
    isempty(x.dependents) && return dag

    new_deps = copy(x.dependents)
    old_deps = copy(x.dependents)
    while true
        for (node, i) in new_deps
            collect_dependent_system_nodes!(dag, node, x.dependents)
        end

        new_deps = setdiff(x.dependents, old_deps)

        isempty(new_deps) && break

        old_deps = copy(x.dependents)
    end

    show_info && @warn "[CollectDependentSystemNode]: found symbols in the system headers: $([n.id for (n,v) in x.dependents])"
    prepend!(dag.nodes, collect(v[1] for v in sort(collect(x.dependents), by=x->x[2])))

    return dag
end

"""
    IndexDefinition <: AbstractPass
In this pass, the indices of struct/union/enum tags and those of function/typedef/macro
identifiers are cached in the DAG for future use. Note that, the "Definition" in the type
name means a little bit more.

The `adj` list of each node is also cleared in this pass.
"""
mutable struct IndexDefinition <: AbstractPass
    show_info::Bool
end
IndexDefinition(; info=false) = IndexDefinition(info)

function (x::IndexDefinition)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "IndexDefinition_log", x.show_info)

    empty!(dag.tags)
    empty!(dag.ids)
    for (i, node) in enumerate(dag.nodes)
        !isempty(node.adj) && empty!(node.adj)

        if is_tag_def(node)
            if haskey(dag.tags, node.id)
                n = dag.nodes[dag.tags[node.id]]
                @assert is_same(n.cursor, node.cursor) "duplicated definitions should be exactly the same!"
                show_info && @info "[IndexDefinition]: marked an indexed tag $(node.id) at nodes[$i]"
                ty = dup_type(node.type)
                dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            else
                show_info && @info "[IndexDefinition]: indexing tag $(node.id) at nodes[$i]"
                dag.tags[node.id] = i
            end
        end

        if is_identifier(node)
            if haskey(dag.ids, node.id)
                show_info &&
                    @info "[IndexDefinition]: found duplicated identifier $(node.id) at nodes[$i]"
                ty = dup_type(node.type)
                dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            else
                show_info && @info "[IndexDefinition]: indexing identifier $(node.id) at nodes[$i]"
                dag.ids[node.id] = i
            end
        end
    end

    return dag
end

"""
    CollectNestedRecord <: AbstractPass
In this pass, nested record nodes are collected and pushed into the DAG.
"""
mutable struct CollectNestedRecord <: AbstractPass
    show_info::Bool
end
CollectNestedRecord(; info=false) = CollectNestedRecord(info)

function (x::CollectNestedRecord)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "CollectNestedRecord_log", x.show_info)
    use_deterministic_sym = get(general_options, "use_deterministic_symbol", false)

    new_tags = Dict{Symbol,Int}()
    for (id, i) in dag.tags
        node = dag.nodes[i]
        !is_record(node) && continue
        is_dup_tagtype(node) && continue
        collect_nested_record!(dag, node, new_tags, use_deterministic_sym)
    end

    merge!(dag.tags, new_tags)

    return dag
end

"""
    FindOpaques <: AbstractPass
Those opaque structs/unions/enums are marked in this pass.
"""
mutable struct FindOpaques <: AbstractPass
    show_info::Bool
end
FindOpaques(; info=false) = FindOpaques(info)

function (x::FindOpaques)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "FindOpaques_log", x.show_info)

    for (i, node) in enumerate(dag.nodes)
        is_forward_decl(node) || continue
        if !haskey(dag.tags, node.id)
            ty = opaque_type(node.type)
            dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            dag.tags[node.id] = i
            show_info &&
                @info "[FindOpaques]: marked an opaque tag-type $(node.id)"
        end
    end

    return dag
end

"""
    LinkTypedefToAnonymousTagType <: AbstractPass
In this pass, the id info of anonymous tag-type nodes is added to those typedef nodes that
directly/indirectly have a reference to these nodes. The id info is injected in the upstream
passes.
"""
mutable struct LinkTypedefToAnonymousTagType <: AbstractPass
    cache::Dict{Int,Vector{Int}}
    is_system::Bool
    show_info::Bool
end
LinkTypedefToAnonymousTagType(;is_system=false, info=false) = LinkTypedefToAnonymousTagType(Dict(), is_system, info)

function (x::LinkTypedefToAnonymousTagType)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "LinkTypedefToAnonymousTagType_log", x.show_info)

    empty!(x.cache)
    nodes = x.is_system ? dag.sys : dag.nodes
    # loop through all the nodes to cache the indices of all the typedefs that refer to
    # an anonymous tag-type
    for i in 1:(length(nodes) - 1)
        cur = nodes[i]
        is_anonymous(cur) || continue
        x.cache[i] = Int[]
        # since an anonymous tag-type may have mutiple typedefs, we need another loop
        for j in (i + 1):length(nodes)
            n = nodes[j]
            is_typedef(n) || break  # keep searching until we hit a non-typedef node
            refback = children(n.cursor)
            if !isempty(refback) && first(refback) == cur.cursor
                push!(x.cache[i], j)
            end
        end
    end
    # loop through all anonymous tag-types and apply node editing
    for (k, v) in x.cache
        isempty(v) && continue  # skip non-typedef anonymous tag-types e.g. enum
        anonymous = nodes[k]
        for i in v
            node = nodes[i]
            ty = TypedefToAnonymous(anonymous.id)
            nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            show_info &&
                @info "[LinkTypedefToAnonymousTagType_log]: store $(anonymous.cursor)'s id to typedef node $(node.id)"
        end
    end
    return dag
end

"""
    ResolveDependency <: AbstractPass
In this pass, the `adj` list of each node in the DAG is populated by its parent definition
nodes. Make sure you run the [`IndexDefinition`](@ref) pass before this pass.

Note that, in the case of circular forward decls, circular dependencies may be introduced
in the DAG, this should be handled in the downstream passes.

See also [`resolve_dependency!`](@ref)
"""
mutable struct ResolveDependency <: AbstractPass
    show_info::Bool
end
ResolveDependency(; info=false) = ResolveDependency(info)

function (x::ResolveDependency)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "ResolveDependency_log", x.show_info)

    for node in dag.nodes
        resolve_dependency!(dag, node)
        unique!(node.adj)  # FIXME: check this
        if show_info
            deps = Dict(n => dag.nodes[n] for n in node.adj)
            @info "[ResolveDependency]: resolved dependency for $(node.cursor)" deps
        end
    end
    return dag
end

@enum DFSMarkStatus begin
    UNMARKED = 0x00
    TEMPORARY = 0x01
    PERMANENT = 0x02
end

"""
    RemoveCircularReference <: AbstractPass
In this pass, circular dependencies that are introduced by mutually referenced structs are
removed, so we can do a topological sort on the DAG.

Make sure you run the [`ResolveDependency`](@ref) pass before this pass.
"""
mutable struct RemoveCircularReference <: AbstractPass
    show_info::Bool
end
RemoveCircularReference(; info=false) = RemoveCircularReference(info)

function detect_cycle!(nodes, marks, cycle, i)
    node = nodes[i]
    mark = marks[i]
    # skip if this node has already been visited
    mark == PERMANENT && return cycle

    # hit a backward edge, record the index
    if mark == TEMPORARY
        push!(cycle, i)
        return cycle
    end

    marks[i] = TEMPORARY
    for n in node.adj
        detect_cycle!(nodes, marks, cycle, n)
        if !isempty(cycle)
            push!(cycle, i)
            return cycle
        end
    end
    marks[i] = PERMANENT
    return cycle
end

function is_non_pointer_ref(child, parent)
    is_non_pointer_dep = false
    for fc in fields(getCursorType(child.cursor))
        fty = getCursorType(fc)
        is_jl_pointer(tojulia(fty)) && continue
        c = getTypeDeclaration(fty)
        if c == parent.cursor
            is_non_pointer_dep = true
        end
    end
    return is_non_pointer_dep
end

function (x::RemoveCircularReference)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "RemoveCircularReference_log", x.show_info)

    marks = fill(UNMARKED, size(dag.nodes))
    while any(x -> x != PERMANENT, marks)
        fill!(marks, UNMARKED)
        for (i, node) in enumerate(dag.nodes)
            marks[i] == UNMARKED || continue
            cycle = Int[]
            detect_cycle!(dag.nodes, marks, cycle, i)
            isempty(cycle) && continue

            # firstly remove cycle reference caused by mutually referenced structs
            typedef_only = true
            for i in 1:(length(cycle) - 1)
                np, nc = cycle[i], cycle[i + 1]
                parent, child = dag.nodes[np], dag.nodes[nc]
                if child.type isa AbstractStructNodeType
                    # only pointer references can be safely removed
                    if !is_non_pointer_ref(child, parent)
                        typedef_only = false
                        idx = findfirst(x -> x == np, child.adj)
                        deleteat!(child.adj, idx)
                        id = child.id
                        ty = StructMutualRef()
                        dag.nodes[nc] = ExprNode(id, ty, child.cursor, child.exprs, child.adj)
                        show_info &&
                            @info "[RemoveCircularReference]: removed $(child.id)'s dependency $(parent.id)"
                    end
                end
                # exit earlier
                (i + 1) == first(cycle) && break
            end

            # there are cases where the circular reference can only be de-referenced at a
            # typedef, so we do the for-loop another round for that.
            if typedef_only
                for i in 1:(length(cycle) - 1)
                    np, nc = cycle[i], cycle[i + 1]
                    parent, child = dag.nodes[np], dag.nodes[nc]
                    is_typedef_elaborated(child) || continue
                    jlty = tojulia(getTypedefDeclUnderlyingType(child.cursor))
                    # make sure the underlying type is a pointer
                    is_jl_pointer(jlty) || continue
                    empty!(child.adj)
                    id = child.id
                    ty = TypedefMutualRef()
                    dag.nodes[nc] = ExprNode(id, ty, child.cursor, child.exprs, child.adj)
                    show_info &&
                        @info "[RemoveCircularReference]: removed $(child.id)'s dependency $(parent.id)"
                    # exit earlier
                    (i + 1) == first(cycle) && break
                end
            end

            # whenever a cycle is found, we reset all of the marks and restart again
            # FIXME: optimize this
            break
        end
    end
    return dag
end

"""
    TopologicalSort <: AbstractPass
Make sure you run the [`RemoveCircularReference`](@ref) pass before this pass.
"""
mutable struct TopologicalSort <: AbstractPass
    show_info::Bool
end
TopologicalSort(; info=false) = TopologicalSort(info)

function dfs_visit!(list, nodes, marks, i)
    node = nodes[i]
    mark = marks[i]
    mark == PERMANENT && return nothing
    @assert mark != TEMPORARY

    marks[i] = TEMPORARY
    for n in node.adj
        dfs_visit!(list, nodes, marks, n)
    end
    marks[i] = PERMANENT
    push!(list, node)
    return nothing
end

function (x::TopologicalSort)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "TopologicalSort_log", x.show_info)

    show_info && @info "[TopologicalSort]: sorting the DAG ..."
    marks = fill(UNMARKED, size(dag.nodes))
    list = []
    for (i, node) in enumerate(dag.nodes)
        marks[i] == UNMARKED || continue
        dfs_visit!(list, dag.nodes, marks, i)
    end
    dag.nodes .= list

    # clean up indices because they are no longer valid
    empty!(dag.tags)
    empty!(dag.ids)

    return dag
end

"""
    CatchDuplicatedAnonymousTags <: AbstractPass
Most duplicated tags are marked as StructDuplicated/UnionDuplicated/EnumDuplicated except
those anonymous tag-types. That's why this pass is necessary.
"""
mutable struct CatchDuplicatedAnonymousTags <: AbstractPass
    show_info::Bool
end
CatchDuplicatedAnonymousTags(; info=false) = CatchDuplicatedAnonymousTags(info)

function (x::CatchDuplicatedAnonymousTags)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "CatchDuplicatedAnonymousTags_log", x.show_info)

    for (i, node) in enumerate(dag.nodes)
        !haskey(dag.tags, node.id) && continue
        is_dup_tagtype(node) && continue
        # `is_anonymous` cannot be used here because the node type may have been changed.
        sid = string(node.id)
        !(startswith(sid, "##Ctag") || startswith(sid, "__JL_Ctag")) && continue
        for (id2, idx2) in dag.tags
            node2 = dag.nodes[idx2]
            node == node2 && continue
            is_dup_tagtype(node2) && continue
            !(startswith(sid, "##Ctag") || startswith(sid, "__JL_Ctag")) && continue
            !is_same(node.cursor, node2.cursor) && continue
            show_info &&
                @info "[CatchDuplicatedAnonymousTags]: found duplicated anonymous tag-type $(node2.id) at dag.nodes[$idx2]."
            ty = dup_type(node2.type)
            dag.nodes[idx2] = ExprNode(node2.id, ty, node2.cursor, node2.exprs, node2.adj)
        end
    end
end

"""
    DeAnonymize <: AbstractPass
In this pass, naive anonymous tag-types are de-anonymized and the correspoding typedefs
are marked [`Skip`](@ref).

```c
typedef struct {
    int x;
} my_struct;
```

In the C code above, what the C programmer really want to do is to bring the name
"my_struct" from the tag scope into the identifier scope and force users to use `my_struct`
instead of `struct my_struct`. In Julia world, we can just do:

```julia
struct my_struct
    x::Cint
end
```

Make sure you run the [`ResolveDependency`](@ref) pass before this pass.
"""
mutable struct DeAnonymize <: AbstractPass
    show_info::Bool
end
DeAnonymize(; info=false) = DeAnonymize(info)

function (x::DeAnonymize)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "DeAnonymize_log", x.show_info)

    for (i, node) in enumerate(dag.nodes)
        is_typedef_to_anonymous(node) || continue
        # a typedef to anonymous node should have only one dependent node and
        # this node must be an anonymous tag-type node.
        @assert length(node.adj) == 1
        dep_idx = node.adj[1]
        dep_node = dag.nodes[dep_idx]

        # skip earlier if the dependent node is a duplicated anonymous tag-type
        is_dup_tagtype(dep_node) && continue

        # loop through the `adj`-list of all nodes in the DAG to find whether this
        # typedef node is the only node that refers to the anonymous tag-type node.
        apply_edit = true
        for n in dag.nodes
            n == node && continue
            if any(i -> dag.nodes[i] == dep_node, n.adj)
                apply_edit = false
            end
        end

        apply_edit || continue

        # apply node editing
        dn = dep_node
        dag.nodes[dep_idx] = ExprNode(node.id, dn.type, dn.cursor, dn.exprs, dn.adj)
        dag.nodes[i] = ExprNode(node.id, SoftSkip(), node.cursor, node.exprs, node.adj)
        show_info &&
            @info "[DeAnonymize]: adding name $(node.id) to $dep_node"
    end

    return dag
end

"""
    CodegenPreprocessing <: AbstractPass
In this pass, additional info are added into expression nodes for codegen.
"""
mutable struct CodegenPreprocessing <: AbstractPass
    skip_nodes::Vector{Int}
    show_info::Bool
end
CodegenPreprocessing(; info=false) = CodegenPreprocessing(Int[], info)

function (x::CodegenPreprocessing)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "CodegenPreprocessing_log", x.show_info)

    empty!(x.skip_nodes)
    for (i, node) in enumerate(dag.nodes)
        if skip_check(dag, node)
            skip_mode = is_dup_tagtype(node) ? SoftSkip() : Skip()
            skip_mode == Skip() && push!(x.skip_nodes, i)
            dag.nodes[i] = ExprNode(node.id, skip_mode, node.cursor, node.exprs, node.adj)
            show_info &&
                @info "[CodegenPreprocessing]: skip a $(node.type) node named $(node.id)"
        end
        if attribute_check(dag, node)
            ty = attribute_type(node.type)
            dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            show_info &&
                @info "[CodegenPreprocessing]: mark an attribute $(node.type) node named $(node.id)"
        end
        if nested_anonymous_check(dag, node)
            ty = nested_anonymous_type(node.type)
            dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            show_info &&
                @info "[CodegenPreprocessing]: mark a nested anonymous $(node.type) node named $(node.id)"
        end
        if bitfield_check(dag, node)
            ty = bitfield_type(node.type)
            dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            show_info &&
                @info "[CodegenPreprocessing]: mark a bitfield $(node.type) node named $(node.id)"
        end
    end

    has_new_skip_node = true
    while has_new_skip_node
        has_new_skip_node = false
        for (i, n) in enumerate(dag.nodes)
            is_hardskip(n) && continue
            # if any dependent node is a `Skip` node, mark this node as `Skip`
            for j in n.adj
                dn = dag.nodes[j]
                is_hardskip(dn) || continue
                push!(x.skip_nodes, i)
                dag.nodes[i] = ExprNode(n.id, Skip(), n.cursor, n.exprs, n.adj)
                show_info &&
                    @info "[CodegenPreprocessing]: skip a $(n.type) node named $(n.id)"
                has_new_skip_node = true
            end
        end
    end

    return dag
end

"""
    Codegen <: AbstractPass
In this pass, Julia expressions are emitted to `node.exprs`.
"""
mutable struct Codegen <: AbstractPass
    show_info::Bool
end
Codegen(; info=false) = Codegen(info)

function (x::Codegen)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "Codegen_log", x.show_info)
    codegen_options = get(options, "codegen", Dict())
    # forward general options
    if haskey(general_options, "library_name")
        codegen_options["library_name"] = general_options["library_name"]
    end
    if haskey(general_options, "library_names")
        codegen_options["library_names"] = general_options["library_names"]
    end

    # store definitions which would be used during codegen
    codegen_options["DAG_tags"] = dag.tags
    codegen_options["DAG_ids"] = dag.ids
    codegen_options["DAG_ids_extra"] = dag.ids_extra
    # collect and map nested anonymous tags
    nested_tags = Dict{Symbol,CLCursor}()
    for (id, i) in dag.tags
        node = dag.nodes[i]
        startswith(string(node.id), "##Ctag") ||
        startswith(string(node.id), "__JL_Ctag") || continue
        if node.type isa NestedRecords
            nested_tags[id] = node.cursor
        end
    end
    codegen_options["nested_tags"] = nested_tags

    for (i, node) in enumerate(dag.nodes)
        !isempty(node.exprs) && empty!(node.exprs)
        emit!(dag, node, codegen_options, idx=i)
        show_info && @info "[Codegen]: emit Julia expression for $(node.id)"
    end

    # clean up
    delete!(codegen_options, "DAG_tags")
    delete!(codegen_options, "DAG_ids")
    delete!(codegen_options, "DAG_ids_extra")
    delete!(codegen_options, "nested_tags")

    return dag
end

"""
    CodegenPostprocessing <: AbstractPass
This pass is reserved for future use.
"""
mutable struct CodegenPostprocessing <: AbstractPass
    show_info::Bool
end
CodegenPostprocessing(; info=false) = CodegenPostprocessing(info)

function (x::CodegenPostprocessing)(dag::ExprDAG, options::Dict)
    # TODO: find a use case
end

"""
    TweakMutability <: AbstractPass
In this pass, the mutability of those structs which are not necessary to be immutable
will be reset to `true` according to the following rules:

if this type is not used as a field type in any other types
    if this type is in the whitelist
        then reset

    if this type is in the blacklist
        then skip

    if this type is used as the argument type in some function protos
        if all of the argument type are non-pointer-type
            then reset
        elseif the argument type is pointer-type
            if all other argument types in this function are not integer type (to pass a vector to the C function, both pointer and size are needed)
                then reset

    if this type is not used as the argument type in any functions (but there is an implicit usage)
        then reset
"""
mutable struct TweakMutability <: AbstractPass
    idxs::Vector{Int}
    show_info::Bool
end
TweakMutability(; info=false) = TweakMutability(Int[], info)

function (x::TweakMutability)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "TweakMutability_log", x.show_info)
    blacklist = get(general_options, "auto_mutability_blacklist", [])
    whitelist = get(general_options, "auto_mutability_whitelist", [])
    add_new = get(general_options, "auto_mutability_with_new", true)

    # collect referenced node ids
    empty!(x.idxs)
    for node in dag.nodes
        t = node.type
        t isa StructAnonymous || t isa StructDefinition || t isa StructMutualRef || continue
        for i in node.adj
            find_and_append_deps!(x.idxs, dag.nodes, i)
        end
    end
    unique!(x.idxs)

    for (i, node) in enumerate(dag.nodes)
        t = node.type
        t isa StructAnonymous || t isa StructDefinition || t isa StructMutualRef || continue
        i ∈ x.idxs && continue
        isempty(node.exprs) && continue

        exprs = filter(x->Meta.isexpr(x, :struct), node.exprs)
        @assert length(exprs) == 1
        expr = first(exprs)
        type_name = string(expr.args[2])

        apply_reset = false
        if type_name ∈ whitelist
            apply_reset = true
        elseif type_name ∈ blacklist
            apply_reset = false
        else
            apply_reset = should_tweak(dag.nodes, i)
        end

        if apply_reset
            expr.args[1] = true
            add_new && push!(expr.args[3].args, Expr(:(=), Expr(:call, expr.args[2]), Expr(:call, :new)))
            show_info &&
                @info "[TweakMutability]: reset the mutability of $type_name to mutable"
        end
    end

    return dag
end

"""
    AddFPtrMethods <: AbstractPass
This pass adds a method definition for each function prototype method which `ccall`s into a library.

The generated method allows the use of a function pointer to `ccall` into directly, instead
of relying on a library to give the pointer via a symbol look up. This is useful for libraries that
use runtime loaders to dynamically resolve function pointers for API calls.
"""
struct AddFPtrMethods <: AbstractPass end

function (::AddFPtrMethods)(dag::ExprDAG, options::Dict)
    codegen_options = get(options, "codegen", Dict())
    use_ccall_macro = get(codegen_options, "use_ccall_macro", false)
    for node in dag.nodes
        node.type isa FunctionProto || continue
        ex = copy(first(node.exprs))
        call = ex.args[1]
        push!(call.args, :fptr)
        body = ex.args[findfirst(x -> Base.is_expr(x, :block), ex.args)]
        stmt_idx = if use_ccall_macro
            findfirst(x -> Base.is_expr(x, :macrocall) && x.args[1] == Symbol("@ccall"), body.args)
        else
            findfirst(x -> Base.is_expr(x, :call) && x.args[1] == :ccall, body.args)
        end
        stmt = body.args[stmt_idx]
        if use_ccall_macro
            typeassert = stmt.args[findfirst(x -> Base.is_expr(x, :(::)), stmt.args)]
            call = typeassert.args[findfirst(x -> Base.is_expr(x, :call), typeassert.args)]
            call.args[1] = Expr(:$, :fptr)
        else
            stmt.args[2] = :fptr
        end
        push!(node.exprs, ex)
    end
end

const DEFAULT_AUDIT_FUNCTIONS = [
    audit_library_name,
    sanity_check,
    report_default_tag_types,
]

mutable struct Audit <: AbstractPass
    funcs::Vector{Function}
    show_info::Bool
end
Audit(; show_info=true) = Audit(DEFAULT_AUDIT_FUNCTIONS, show_info)

function (x::Audit)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    if !haskey(log_options, "Audit_log")
        log_options["Audit_log"] = x.show_info
    end

    for f in x.funcs
        f(dag, options)
    end

    return dag
end

"""
    AbstractPrinter <: AbstractPass
Supertype for printers.
"""
abstract type AbstractPrinter <: AbstractPass end

"""
    FunctionPrinter <: AbstractPrinter
In this pass, only those functions are dumped to file.
"""
mutable struct FunctionPrinter <: AbstractPrinter
    file::AbstractString
    show_info::Bool
end
FunctionPrinter(file::AbstractString; info=true) = FunctionPrinter(file, info)

function (x::FunctionPrinter)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "FunctionPrinter_log", x.show_info)
    blacklist = get(general_options, "printer_blacklist", [])

    show_info && @info "[FunctionPrinter]: print to $(x.file)"
    open(x.file, "w") do io
        for node in dag.nodes
            string(node.id) ∈ blacklist && continue
            node.type isa AbstractFunctionNodeType || continue
            pretty_print(io, node, general_options)
        end
    end
    return dag
end

"""
    CommonPrinter <: AbstractPrinter
In this pass, only those non-functions are dumped to file.
"""
mutable struct CommonPrinter <: AbstractPrinter
    file::AbstractString
    show_info::Bool
end
CommonPrinter(file::AbstractString; info=true) = CommonPrinter(file, info)

function (x::CommonPrinter)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "CommonPrinter_log", x.show_info)
    blacklist = get(general_options, "printer_blacklist", [])

    show_info && @info "[CommonPrinter]: print to $(x.file)"
    open(x.file, "w") do io
        for node in dag.nodes
            string(node.id) ∈ blacklist && continue
            node.type isa AbstractMacroNodeType && continue
            pretty_print(io, node, general_options)
        end
        # print macros in the bottom of the file
        for node in dag.nodes
            string(node.id) ∈ blacklist && continue
            node.type isa AbstractMacroNodeType || continue
            pretty_print(io, node, options)
        end
    end
    return dag
end

"""
    GeneralPrinter <: AbstractPrinter
In this pass, all symbols are dumped to file.
"""
mutable struct GeneralPrinter <: AbstractPrinter
    file::AbstractString
    show_info::Bool
end
GeneralPrinter(file::AbstractString; info=true) = GeneralPrinter(file, info)

function (x::GeneralPrinter)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "GeneralPrinter_log", x.show_info)
    blacklist = get(general_options, "printer_blacklist", [])
    extract_c_comment = get(general_options, "extract_c_comment", false)

    show_info && @info "[GeneralPrinter]: print to $(x.file)"
    open(x.file, "a") do io
        for node in dag.nodes
            string(node.id) ∈ blacklist && continue
            node.type isa AbstractMacroNodeType && continue
            isempty(node.exprs) || extract_c_comment && print_documentation(io, node, "")
            pretty_print(io, node, general_options)
        end
        # print macros in the bottom of the file
        for node in dag.nodes
            string(node.id) ∈ blacklist && continue
            node.type isa AbstractMacroNodeType || continue
            isempty(node.exprs) || extract_c_comment && print_documentation(io, node, "")
            pretty_print(io, node, options)
        end
    end
    return dag
end

"""
   StdPrinter <: AbstractPrinter
In this pass, all symbols are dumped to stdout.
"""
mutable struct StdPrinter <: AbstractPrinter
    show_info::Bool
end
StdPrinter(; info=true) = StdPrinter(info)

function (x::StdPrinter)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "StdPrinter_log", x.show_info)
    blacklist = get(general_options, "printer_blacklist", [])

    for node in dag.nodes
        string(node.id) ∈ blacklist && continue
        node.type isa AbstractMacroNodeType && continue
        pretty_print(stdout, node, general_options)
    end
    # print macros
    for node in dag.nodes
        string(node.id) ∈ blacklist && continue
        node.type isa AbstractMacroNodeType || continue
        pretty_print(stdout, node, options)
    end

    return dag
end

"""
    ProloguePrinter <: AbstractPrinter
In this pass, prologues are dumped to file.
"""
mutable struct ProloguePrinter <: AbstractPrinter
    file::AbstractString
    show_info::Bool
end
ProloguePrinter(file::AbstractString; info=true) = ProloguePrinter(file, info)

function (x::ProloguePrinter)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "ProloguePrinter_log", x.show_info)
    module_name = get(general_options, "module_name", "")
    jll_pkg_name = get(general_options, "jll_pkg_name", "")
    jll_pkg_extra = get(general_options, "jll_pkg_extra", [])
    prologue_file_path = get(general_options, "prologue_file_path", "")
    use_native_enum = get(general_options, "use_julia_native_enum_type", false)
    print_CEnum = get(general_options, "print_using_CEnum", true)

    show_info && @info "[ProloguePrinter]: print to $(x.file)"
    open(x.file, "w") do io
        # print "module name"
        if !isempty(module_name)
            println(io, "module $module_name")
            println(io)
        end
        # print _jll pkgs
        if !isempty(jll_pkg_name)
            println(io, "using $jll_pkg_name")
            println(io, "export $jll_pkg_name")
            println(io)
        end
        # print extra _jll pkgs
        if !isempty(jll_pkg_extra)
            for jll in jll_pkg_extra
                println(io, "using $jll")
                println(io, "export $jll")
                println(io)
            end
        end

        # print "using CEnum"
        if !use_native_enum && print_CEnum
            println(io, "using CEnum")
            println(io)
        end
        # print prelogue patches
        if !isempty(prologue_file_path)
            println(io, read(prologue_file_path, String))
            println(io)
        end
    end
    return dag
end

"""
    EpiloguePrinter <: AbstractPrinter
In this pass, epilogues are dumped to file.
"""
mutable struct EpiloguePrinter <: AbstractPrinter
    file::AbstractString
    show_info::Bool
end
EpiloguePrinter(file::AbstractString; info=true) = EpiloguePrinter(file, info)

function (x::EpiloguePrinter)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "EpiloguePrinter_log", x.show_info)
    module_name = get(general_options, "module_name", "")
    epilogue_file_path = get(general_options, "epilogue_file_path", "")
    export_prefixes = get(general_options, "export_symbol_prefixes", "")

    show_info && @info "[EpiloguePrinter]: print to $(x.file)"
    open(x.file, "a") do io
        # print epilogue patches
        if !isempty(epilogue_file_path)
            println(io, read(epilogue_file_path, String))
            println(io)
        end
        # print exports
        if !isempty(export_prefixes)
            str = """# exports
const PREFIXES = $export_prefixes
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export \$name
    end
end"""
            println(io, str)
            println(io)
        end
        # print "end # module"
        if !isempty(module_name)
            println(io, "end # module")
        end
    end
    return dag
end

## EXPERIMENTAL
"""
    CodegenMacro <: AbstractPass
[`Codegen`](@ref) pass for macros.
"""
mutable struct CodegenMacro <: AbstractPass
    show_info::Bool
end
CodegenMacro(; info=false) = CodegenMacro(info)

function (x::CodegenMacro)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "CodegenMacro_log", x.show_info)
    codegen_options = get(options, "codegen", Dict())
    macro_options = get(codegen_options, "macro", Dict())
    macro_mode = get(macro_options, "macro_mode", "basic")

    (macro_mode == "none" || macro_mode == "disable") && return dag

    for node in dag.nodes
        node.type isa AbstractMacroNodeType || continue
        !isempty(node.exprs) && empty!(node.exprs)
        macro_emit!(dag, node, macro_options)
        show_info && @info "[CodegenMacro]: emit Julia expression for $(node.id)"
    end

    return dag
end

print_documentation(io::IO, node::ExprNode, indent) = print_documentation(io, node.cursor, indent)
function print_documentation(io::IO, cursor::Union{CLCursor, CXCursor}, indent)
    comment = Clang.getRawCommentText(cursor)
    doc = strip_comment_markers(comment)
    # Do not print """ if no doc
    all(isempty, doc) && return

    println(io, indent * '"'^3)
    for line in doc
        println(io, indent, replace(line, r"([\\$])"=>s"\\\1"))
    end
    println(io, indent * '"'^3)
end

function strip_comment_markers(s::AbstractString)::Vector
    # Assume the comments are either /**/ or //, 
    # although Clang may associate multiple consecutive comments as a whole

    # // /*
    first_line_pattern = r"^\s*(/{2,}!?|/\*+!?)\s*(.*)$"
    # // *
    middle_line_pattern = r"^\s*(/{2,}!?\s?|\*?\s?)(.*)$"
    # // */
    last_line_pattern = r"^\s*(/{2,}!?\s*(.*)|(.*?)\*+/)$"
    # // /**/
    single_line_pattern = r"^\s*(/\*+<?\s*(.*)\s*\*/|/{2,}!?\s*(.*))$"

    lines = split(s, '\n')
    if length(lines) == 0
        return []
    elseif length(lines) == 1
        m = match(single_line_pattern, only(lines))
        if isnothing(m)
            return [s]
        else
            return [isnothing(m[2]) ? m[3] : m[2]]
        end
    else
        first = lines[1]
        last = lines[end]
        middle = lines[2:end-1]
        stripped = SubString{String}[]
        m_first = match(first_line_pattern, first)
        m_last = match(last_line_pattern, last)
        if isnothing(m_first)
            push!(stripped, first)
        elseif !isempty(m_first[2])
            push!(stripped, m_first[2])
        end
        for line in middle
            m = match(middle_line_pattern, line)
            if isnothing(m)
                push!(stripped, line)
            else
                push!(stripped, m[2])
            end
        end
        if isnothing(m_last)
            push!(stripped, last)
        else
            m = isnothing(m_last[2]) ? m_last[3] : m_last[2]
            isempty(m) || push!(stripped, m)
        end
        return stripped
    end
end