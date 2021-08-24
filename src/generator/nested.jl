function collect_nested_record!(dag::ExprDAG, node::ExprNode, new_tags, isdeterministic)
    # fall back to use `children` if `fields` returns empty.
    field_cursors = fields(getCursorType(node.cursor))
    field_cursors = isempty(field_cursors) ? children(node.cursor) : field_cursors
    for field_cursor in field_cursors
        field_ty = getCursorType(field_cursor)
        has_elaborated_reference(field_ty) || continue
        field_jlty = tojulia(field_ty)
        leaf_jlty = get_jl_leaf_type(field_jlty)
        leaf_jlty isa JuliaCrecord || continue  # nested enums are not legal in C
        # isempty(string(jlty.sym)) && @assert occursin("anonymous", spelling(named_ty))
        n_cursor = get_elaborated_cursor(field_ty)
        if isempty(string(leaf_jlty.sym))
            @assert isCursorDefinition(n_cursor)
            n_id = gensym_recorded(n_cursor, isdeterministic, dag.gensym_map)
            ty = n_cursor isa CLStructDecl ? StructAnonymous() : UnionAnonymous()
            n_node = ExprNode(n_id, ty, n_cursor, Expr[], Int[])
            push!(dag.nodes, n_node)
            new_tags[n_id] = lastindex(dag.nodes)
            collect_nested_record!(dag, n_node, new_tags, isdeterministic)
        elseif !haskey(dag.tags, leaf_jlty.sym)
            n_id = leaf_jlty.sym
            if isCursorDefinition(n_cursor)
                ty = n_cursor isa CLStructDecl ? StructDefinition() : UnionDefinition()
                n_node = ExprNode(n_id, ty, n_cursor, Expr[], Int[])
                push!(dag.nodes, n_node)
                new_tags[n_id] = lastindex(dag.nodes)
                collect_nested_record!(dag, n_node, new_tags, isdeterministic)
            else
                # then it must be an opaque
                ty = n_cursor isa CLStructDecl ? StructOpaqueDecl() : UnionOpaqueDecl()
                n_node = ExprNode(n_id, ty, n_cursor, Expr[], Int[])
                if !haskey(new_tags, n_id)
                    push!(dag.nodes, n_node)
                    new_tags[n_id] = lastindex(dag.nodes)
                end
            end
        end
    end

    return dag
end
