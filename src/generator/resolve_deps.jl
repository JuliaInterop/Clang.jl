"""
    resolve_dependency!(dag::ExprDAG, node::ExprNode, options)
Build the DAG, resolve dependency.
"""
function resolve_dependency! end

resolve_dependency!(dag::ExprDAG, node::ExprNode, options) = dag

function resolve_dependency!(dag::ExprDAG, node::ExprNode{FunctionProto}, options)
    cursor = node.cursor
    types = CLType[getArgType(getCursorType(cursor), i - 1) for i in 1:getNumArguments(cursor)]
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
        elseif !hasref && haskey(dag.tags, leaf_ty.sym)
            # FIXME: in some cases, this system-header symbol is in dag.tags
            push!(node.adj, dag.tags[leaf_ty.sym])
        elseif hasref && is_jl_pointer(jlty)
            # if opaque pointers are being used as function argument like
            #   void func(struct foo *x);
            # we can simply translate this argument type to `Ptr{Cvoid}` because it is only
            # visible to local.
            # pass
        else
            tycu = getTypeDeclaration(ty)
            file, line, col = get_file_line_column(cursor)
            cspell = spelling(cursor)
            tspell = spelling(ty)
            error("There is no definition for $cspell's parameter type: [`$tspell`] at $file:$line:$col")
        end
    end
    return dag
end

function resolve_dependency!(dag::ExprDAG, node::ExprNode{FunctionNoProto}, options)
    cursor = node.cursor
    @assert getNumArguments(cursor) == 0
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
    elseif !hasref && haskey(dag.tags, leaf_ty.sym)
        # FIXME: in some cases, this system-header symbol is in dag.tags
        push!(node.adj, dag.tags[leaf_ty.sym])
    else
        tycu = getTypeDeclaration(ty)
        file, line, col = get_file_line_column(cursor)
        cspell = spelling(cursor)
        tspell = spelling(ty)
        error("There is no definition for $cspell's return type: [`$tspell`] at $file:$line:$col")
    end
    return dag
end

function resolve_dependency!(dag::ExprDAG, node::ExprNode{TypedefElaborated}, options)
    cursor = node.cursor
    ty = getTypedefDeclUnderlyingType(cursor)
    jlty = tojulia(ty)
    leaf_ty = get_jl_leaf_type(jlty)

    is_jl_basic(leaf_ty) && return dag

    if haskey(dag.tags, leaf_ty.sym)
        push!(node.adj, dag.tags[leaf_ty.sym])
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

function resolve_dependency!(dag::ExprDAG, node::ExprNode{TypedefDefault}, options)
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

function resolve_dependency!(dag::ExprDAG, node::ExprNode{TypedefToAnonymous}, options)
    s = node.type.sym
    @assert haskey(dag.tags, s)
    push!(node.adj, dag.tags[s])
    return dag
end

# ignore non-opaque forward decls, that's our purpose
resolve_dependency!(dag::ExprDAG, node::ExprNode{StructForwardDecl}, options) = dag

function resolve_dependency!(dag::ExprDAG, node::ExprNode{<:AbstractStructNodeType}, options)
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
        elseif !hasref && haskey(dag.tags, leaf_ty.sym)
            # FIXME: in some cases, this system-header symbol is in dag.tags
            push!(node.adj, dag.tags[leaf_ty.sym])
        elseif occursin("anonymous", spelling(ty))
            nested_tags = get(options, "nested_tags", Dict())
            tag = get_nested_tag(nested_tags, leaf_ty)
            if !isnothing(tag)
                push!(node.adj, dag.tags[tag])
            end
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
resolve_dependency!(dag::ExprDAG, node::ExprNode{<:AbstractEnumNodeType}, options) = dag

# to workaround some nasty field alignment problems, we simply generate Julia structs with
# a single `data::NTuple` field for union nodes, so no need to add any dependencies here.
resolve_dependency!(dag::ExprDAG, node::ExprNode{<:AbstractUnionNodeType}, options) = dag

# at least sort macros according to identifiers, otherwise the order is terribly wrong
function resolve_dependency!(dag::ExprDAG, node::ExprNode{<:AbstractMacroNodeType}, options)
    # check whether the macro is function-line by inspecting the source code
    args = Set{Symbol}()
    if node.type isa MacroFunctionLike
        for tok in Iterators.drop(tokenize(node.cursor), 2)
            if is_identifier(tok)
                push!(args, Symbol(tok.text))
            elseif is_punctuation(tok) && tok.text == ")"
                break
            end
        end
    end
    for tok in Iterators.drop(tokenize(node.cursor), 1)
        sym = Symbol(tok.text)
        if is_identifier(tok) && haskey(dag.ids, sym) && !(tok in args)
            push!(node.adj, dag.ids[sym])
        end
    end
end
