"""
    collect_dependant_system_nodes!(dag::ExprDAG, node::ExprNode, system_nodes)
Collect dependant nodes in the system headers.
"""
function collect_dependant_system_nodes! end

collect_dependant_system_nodes!(dag::ExprDAG, node::ExprNode, system_nodes) = dag

function collect_dependant_system_nodes!(dag::ExprDAG, node::ExprNode{FunctionProto}, system_nodes)
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
            tycu = getTypeDeclaration(ty)
            file, line, col = get_file_line_column(cursor)
            cspell = spelling(cursor)
            aspell = spelling(tycu)
            tspell = spelling(tycu)
            error("There is no definition for $cspell's parameter: $aspell's type: [`$tspell`] at $file:$line:$col")
        end
    end
    return dag
end

function resolve_dependency!(dag::ExprDAG, node::ExprNode{FunctionNoProto})
    cursor = node.cursor
    @assert isempty(get_function_args(cursor))
    ty = getCursorResultType(cursor)
    jlty = tojulia(ty)
    leaf_ty = get_jl_leaf_type(jlty)

    is_jl_basic(leaf_ty) && return dag

    hasref = has_elaborated_reference(ty)
    if hasref && haskey(dag.tags, leaf_ty.sym)
        push!(node.adj, dag.tags[leaf_ty.sym])
    elseif !hasref && haskey(dag.ids, leaf_ty.sym)
        push!(node.adj, dag.ids[leaf_ty.sym])
    elseif haskey(dag.ids_extra, leaf_ty.sym)
        # pass
    else
        tycu = getTypeDeclaration(ty)
        file, line, col = get_file_line_column(cursor)
        cspell = spelling(cursor)
        tspell = spelling(tycu)
        error("There is no definition for $cspell's return type: [`$tspell`] at $file:$line:$col")
    end
    return dag
end

function resolve_dependency!(dag::ExprDAG, node::ExprNode{TypedefElaborated})
    cursor = node.cursor
    ty = getTypedefDeclUnderlyingType(cursor)
    jlty = tojulia(ty)
    leaf_ty = get_jl_leaf_type(jlty)

    is_jl_basic(leaf_ty) && return dag

    if haskey(dag.tags, leaf_ty.sym)
        push!(node.adj, dag.tags[leaf_ty.sym])
    else
        tycu = getTypeDeclaration(ty)
        file, line, col = get_file_line_column(cursor)
        cspell = spelling(cursor)
        tspell = spelling(tycu)
        error("There is no definition for $cspell's underlying type: [`$tspell`] at $file:$line:$col")
    end
    return dag
end

function resolve_dependency!(dag::ExprDAG, node::ExprNode{TypedefDefault})
    cursor = node.cursor
    ty = getTypedefDeclUnderlyingType(cursor)
    jlty = tojulia(ty)
    leaf_ty = get_jl_leaf_type(jlty)

    is_jl_basic(leaf_ty) && return dag

    # do nothing for unknowns since we just skip them in the downstream passes
    is_jl_unknown(leaf_ty) && return dag

    if haskey(dag.ids, leaf_ty.sym)
        push!(node.adj, dag.ids[leaf_ty.sym])
    elseif haskey(dag.ids_extra, leaf_ty.sym)
        # pass
    else
        tycu = getTypeDeclaration(ty)
        file, line, col = get_file_line_column(cursor)
        cspell = spelling(cursor)
        tspell = spelling(tycu)
        error("There is no definition for $cspell's underlying type: [`$tspell`] at $file:$line:$col")
    end
    return dag
end

function resolve_dependency!(dag::ExprDAG, node::ExprNode{TypedefToAnonymous})
    s = node.type.sym
    @assert haskey(dag.tags, s)
    push!(node.adj, dag.tags[s])
    return dag
end

# ignore non-opaque forward decls, that's our purpose
resolve_dependency!(dag::ExprDAG, node::ExprNode{StructForwardDecl}) = dag

function resolve_dependency!(dag::ExprDAG, node::ExprNode{<:AbstractStructNodeType})
    cursor = node.cursor
    for c in fields(getCursorType(cursor))
        ty = getCursorType(c)
        jlty = tojulia(ty)
        leaf_ty = get_jl_leaf_type(jlty)

        is_jl_basic(leaf_ty) && continue

        hasref = has_elaborated_reference(ty)
        if hasref && haskey(dag.tags, leaf_ty.sym)
            push!(node.adj, dag.tags[leaf_ty.sym])
        elseif !hasref && haskey(dag.ids, leaf_ty.sym)
            push!(node.adj, dag.ids[leaf_ty.sym])
        elseif haskey(dag.ids_extra, leaf_ty.sym)
            # pass
        elseif occursin("anonymous", spelling(ty))
            # it could be a nested anonymous tag-type.
            # pass
        else
            file, line, col = get_file_line_column(cursor)
            cspell = spelling(cursor)
            fspell = spelling(c)
            tspell = spelling(getCursorType(c))
            error("There is no definition for $cspell's field: $fspell's type: [`$tspell`] at $file:$line:$col")
        end
    end
    return dag
end

# enums are just "named integers", no dependency needs to be resolved.
resolve_dependency!(dag::ExprDAG, node::ExprNode{<:AbstractEnumNodeType}) = dag

# to workaround some nasty field alignment problems, we simply generate Julia structs with
# a single `data::NTuple` field for union nodes, so no need to add any dependencies here.
resolve_dependency!(dag::ExprDAG, node::ExprNode{<:AbstractUnionNodeType}) = dag

# for now, do nothing for macros, just assume they are written in a correct order
resolve_dependency!(dag::ExprDAG, node::ExprNode{<:AbstractMacroNodeType}) = dag
