"""
    collect_dependent_system_nodes!(dag::ExprDAG, node::ExprNode, system_nodes)
Collect dependent nodes in the system headers.
"""
function collect_dependent_system_nodes! end

collect_dependent_system_nodes!(dag::ExprDAG, node::ExprNode, system_nodes) = dag

function collect_dependent_system_nodes!(dag::ExprDAG, node::ExprNode{FunctionProto}, system_nodes)
    cursor = node.cursor
    args = get_function_args(cursor)
    types = CLType[getArgType(getCursorType(cursor), i - 1) for i in 1:length(args)]
    push!(types, getCursorResultType(cursor))
    for ty in types
        # for arrays and pointers, meaningful types need to be recursively retrieved
        jlty = tojulia(ty)
        leaf_ty = get_jl_leaf_type(jlty)

        # skip julia basic types
        is_jl_basic(leaf_ty) && continue

        hasref = has_elaborated_reference(ty)
        if (hasref && haskey(dag.tags, leaf_ty.sym)) ||
            (!hasref && haskey(dag.ids, leaf_ty.sym)) ||
            haskey(dag.ids_extra, leaf_ty.sym) ||
            (hasref && is_jl_pointer(jlty))
            # pass
        else
            # add all sys nodes with the same id
            for (i, n) in enumerate(dag.sys)
                if n.id == leaf_ty.sym
                    system_nodes[n] = i
                end
            end
        end
    end
    return system_nodes
end

function collect_dependent_system_nodes!(dag::ExprDAG, node::ExprNode{FunctionNoProto}, system_nodes)
    cursor = node.cursor
    @assert isempty(get_function_args(cursor))
    ty = getCursorResultType(cursor)
    jlty = tojulia(ty)
    leaf_ty = get_jl_leaf_type(jlty)

    is_jl_basic(leaf_ty) && return system_nodes

    hasref = has_elaborated_reference(ty)
    if (hasref && haskey(dag.tags, leaf_ty.sym)) ||
        (!hasref && haskey(dag.ids, leaf_ty.sym)) ||
        haskey(dag.ids_extra, leaf_ty.sym)
        # pass
    else
        # add all sys nodes with the same id
        for (i, n) in enumerate(dag.sys)
            if n.id == leaf_ty.sym
                system_nodes[n] = i
            end
        end
    end

    return system_nodes
end

function collect_dependent_system_nodes!(dag::ExprDAG, node::ExprNode{TypedefElaborated}, system_nodes)
    cursor = node.cursor
    ty = getTypedefDeclUnderlyingType(cursor)
    jlty = tojulia(ty)
    leaf_ty = get_jl_leaf_type(jlty)

    is_jl_basic(leaf_ty) && return system_nodes

    if !(haskey(dag.tags, leaf_ty.sym) || haskey(dag.ids_extra, leaf_ty.sym))
        # add all sys nodes with the same id
        for (i, n) in enumerate(dag.sys)
            if n.id == leaf_ty.sym
                system_nodes[n] = i
            end
        end
    end

    return system_nodes
end

function collect_dependent_system_nodes!(dag::ExprDAG, node::ExprNode{TypedefDefault}, system_nodes)
    cursor = node.cursor
    ty = getTypedefDeclUnderlyingType(cursor)
    jlty = tojulia(ty)
    leaf_ty = get_jl_leaf_type(jlty)

    is_jl_basic(leaf_ty) && return system_nodes

    # do nothing for unknowns since we just skip them in the downstream passes
    is_jl_unknown(leaf_ty) && return system_nodes

    if !(haskey(dag.ids, leaf_ty.sym) || haskey(dag.ids_extra, leaf_ty.sym))
        # add all sys nodes with the same id
        for (i, n) in enumerate(dag.sys)
            if n.id == leaf_ty.sym
                system_nodes[n] = i
            end
        end
    end

    return system_nodes
end

function collect_dependent_system_nodes!(dag::ExprDAG, node::ExprNode{TypedefToAnonymous}, system_nodes)
    # add all sys nodes with the same id
    for (i, n) in enumerate(dag.sys)
        if n.id == node.type.sym
            system_nodes[n] = i
        end
    end
    return system_nodes
end

function collect_dependent_system_nodes!(dag::ExprDAG, node::ExprNode{<:AbstractStructNodeType}, system_nodes)
    cursor = node.cursor
    for c in fields(getCursorType(cursor))
        ty = getCursorType(c)
        jlty = tojulia(ty)
        leaf_ty = get_jl_leaf_type(jlty)

        is_jl_basic(leaf_ty) && continue

        hasref = has_elaborated_reference(ty)
        if (hasref && haskey(dag.tags, leaf_ty.sym)) ||
            (!hasref && haskey(dag.ids, leaf_ty.sym)) ||
            haskey(dag.ids_extra, leaf_ty.sym) ||
            occursin("anonymous", spelling(ty))
            # pass
        else
            # add all sys nodes with the same id
            for (i, n) in enumerate(dag.sys)
                if n.id == leaf_ty.sym
                    system_nodes[n] = i
                end
            end
        end
    end
    return dag
end
