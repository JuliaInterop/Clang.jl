"""
    resolve_dependency!(dag::ExprDAG, node::ExprNode)
Build the DAG, resolve dependency.
"""
function resolve_dependency! end

resolve_dependency!(dag::ExprDAG, node::ExprNode) = dag

function resolve_dependency!(dag::ExprDAG, node::ExprNode{FunctionProto})
    cursor = node.cursor
    args = get_function_args(cursor)
    types = CLType[getArgType(getCursorType(cursor), i - 1) for i in 1:length(args)]
    push!(types, getCursorResultType(cursor))
    for ty in types
        # for arrays and pointers, meaningful types need to be recursively retrieved
        jlty = tojulia(ty)
        leaf_ty = get_jl_leaf_type(jlty)

        # there is no dependency that needs to be recorded for those julia basic types
        is_jl_basic(leaf_ty) && continue

        hasref = has_elaborated_reference(ty)
        if hasref && haskey(dag.tags, leaf_ty.sym)
            push!(node.adj, dag.tags[leaf_ty.sym])
        elseif !hasref && haskey(dag.ids, leaf_ty.sym)
            push!(node.adj, dag.ids[leaf_ty.sym])
        elseif haskey(dag.ids_extra, leaf_ty.sym)
            # extra identifiers are printed at the top of the file, so there is no need to
            # add them as dependencies.
            # pass
        elseif hasref && is_jl_pointer(jlty)
            # if opaque pointers are being used as function argument like
            #   void func(struct foo *x);
            # we can simply translate this argument type to `Ptr{Cvoid}` because it is only
            # visible to local.
            # pass
        else
            tycu = getTypeDeclaration(ty)
            file, line, col = get_file_line_column(cursor)
            error("There is no definition for $(cursor)'s parameter: $(tycu) at $file:$line:$col")
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
        error("There is no definition for $(cursor)'s return type: $(tycu) at $file:$line:$col")
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
        error("There is no definition for $(cursor)'s underlying type: $(tycu) at $file:$line:$col")
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
        error("There is no definition for $(cursor)'s underlying type: $(spelling(tycu)) at $file:$line:$col")
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
            # those nested anonymous tag-types should be generated in the codegen pass.
            # pass
        else
            # FIXME:
            # * handle nested opaque pointers by default, we just error out for now, so
            # users needs to `@add_def` the missing symbol.
            file, line, col = get_file_line_column(cursor)
            error("There is no definition for $(cursor)'s field: $c at $file:$line:$col")
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
