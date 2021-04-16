function find_and_append_deps!(idxs, nodes, i)
    node = nodes[i]
    if node.type isa AbstractStructNodeType
        push!(idxs, i)
    elseif node.type isa AbstractTypedefNodeType
        if isempty(node.adj)
            return nothing
        else
            @assert length(node.adj) == 1
            find_and_append_deps!(idxs, nodes, first(node.adj))
        end
    end
    return nothing
end

function is_argtype_dep(struct_node, nodes, i)
    node = nodes[i]
    if node.type isa AbstractStructNodeType
        return struct_node == node
    elseif node.type isa AbstractTypedefNodeType
        if isempty(node.adj)
            return false
        else
            @assert length(node.adj) == 1
            return is_argtype_dep(struct_node, nodes, first(node.adj))
        end
    end
    return false
end

function should_tweak(nodes, idx)
    struct_node = nodes[idx]
    is_orphan = true
    is_all_non_pointer = true
    is_all_no_integer_pointer = true
    for (i, node) in enumerate(nodes)
        # only consider FunctionProto for now
        node.type isa FunctionProto || continue

        # do a quick-check
        is_dep = false
        for j in node.adj
            if is_argtype_dep(struct_node, nodes, j)
                is_dep = true
                break
            end
        end

        if is_dep
            is_orphan && (is_orphan = false;)
            cursor = node.cursor
            args = get_function_args(cursor)
            types = [getArgType(getCursorType(cursor), i - 1) for i in 1:length(args)]
            has_integer_args = false
            has_a_pointer_dep = false

            for ty in types
                jlty = tojulia(ty)
                leaf_ty = get_jl_leaf_type(jlty)

                if is_jl_basic(leaf_ty)
                    is_jl_integer(jlty) && (has_integer_args = true;)
                    continue
                end

                if leaf_ty isa JuliaCtypedef && haskey(EXTRA_DEFINITIONS, leaf_ty.sym)
                    if is_jl_integer(EXTRA_DEFINITIONS[leaf_ty.sym])
                        has_integer_args = true
                    end
                end

                expr = first(filter(x->Meta.isexpr(x, :struct), struct_node.exprs))
                struct_name = string(expr.args[2])
                if string(leaf_ty.sym) == struct_name
                    is_jl_pointer(jlty) && (has_a_pointer_dep = true;)
                end
            end

            if is_all_non_pointer && has_a_pointer_dep
                is_all_non_pointer = false
            end

            if is_all_no_integer_pointer && has_a_pointer_dep && has_integer_args
                is_all_no_integer_pointer = false
            end
        end
    end

    return is_orphan || is_all_non_pointer || is_all_no_integer_pointer
end
