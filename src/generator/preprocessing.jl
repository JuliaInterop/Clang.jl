"""
    skip_check
Return `true` if the node should be marked as [`Skip`](@ref).
"""
function skip_check end

skip_check(dag::ExprDAG, node::ExprNode) = false

# we don not generate Julia code for non-opaque forward decls
skip_check(dag::ExprDAG, node::ExprNode{StructForwardDecl}) = true
skip_check(dag::ExprDAG, node::ExprNode{UnionForwardDecl}) = true
skip_check(dag::ExprDAG, node::ExprNode{EnumForwardDecl}) = true
skip_check(dag::ExprDAG, node::ExprNode{StructOpaqueDecl}) = false
skip_check(dag::ExprDAG, node::ExprNode{UnionOpaqueDecl}) = false
skip_check(dag::ExprDAG, node::ExprNode{EnumOpaqueDecl}) = false

# duplicated nodes should be skipped
skip_check(dag::ExprDAG, node::ExprNode{FunctionDuplicated}) = true
skip_check(dag::ExprDAG, node::ExprNode{TypedefDuplicated}) = true
skip_check(dag::ExprDAG, node::ExprNode{MacroDuplicated}) = true
skip_check(dag::ExprDAG, node::ExprNode{StructDuplicated}) = true
skip_check(dag::ExprDAG, node::ExprNode{UnionDuplicated}) = true
skip_check(dag::ExprDAG, node::ExprNode{EnumDuplicated}) = true

function skip_check(dag::ExprDAG, node::ExprNode{FunctionProto})
    cursor = node.cursor
    types = CLType[getArgType(getCursorType(cursor), i - 1) for i in 1:getNumArguments(cursor)]
    push!(types, getCursorResultType(cursor))
    for ty in types
        jlty = tojulia(ty)
        leaf_ty = get_jl_leaf_type(jlty)

        is_jl_basic(leaf_ty) && continue

        # skip if the function uses any non-standard C types
        is_jl_unknown(leaf_ty) && return true

        # skip if the function uses any unsupported type named by users
        extra = dag.ids_extra
        if haskey(extra, leaf_ty.sym) && is_jl_unsupported(extra[leaf_ty.sym])
            return true
        end
    end
    return false
end

function skip_check(dag::ExprDAG, node::ExprNode{FunctionNoProto})
    cursor = node.cursor
    ty = getCursorResultType(cursor)
    jlty = tojulia(ty)
    leaf_ty = get_jl_leaf_type(jlty)

    extra = dag.ids_extra
    if is_jl_basic(leaf_ty)
        return false
    elseif is_jl_unknown(leaf_ty)
        return true
    elseif haskey(extra, leaf_ty.sym) && is_jl_unsupported(extra[leaf_ty.sym])
        return true
    else
        return false
    end
end

function skip_check(dag::ExprDAG, node::ExprNode{TypedefElaborated})
    cursor = node.cursor
    ty = getTypedefDeclUnderlyingType(cursor)
    leaf_ty = get_jl_leaf_type(tojulia(ty))
    @assert !is_jl_basic(leaf_ty)
    @assert !is_jl_unknown(leaf_ty)
    extra = dag.ids_extra
    return haskey(extra, leaf_ty.sym) && is_jl_unsupported(extra[leaf_ty.sym])
end

function skip_check(dag::ExprDAG, node::ExprNode{TypedefDefault})
    cursor = node.cursor
    ty = getTypedefDeclUnderlyingType(cursor)
    jlty = tojulia(ty)
    leaf_ty = get_jl_leaf_type(jlty)

    extra = dag.ids_extra
    if is_jl_basic(leaf_ty)
        return false
    elseif is_jl_unknown(leaf_ty)
        return true
    elseif haskey(extra, leaf_ty.sym) && is_jl_unsupported(extra[leaf_ty.sym])
        return true
    else
        return false
    end
end

function skip_check(dag::ExprDAG, node::ExprNode{<:AbstractStructNodeType})
    cursor = node.cursor
    for c in fields(getCursorType(cursor))
        ty = getCursorType(c)
        jlty = tojulia(ty)
        leaf_ty = get_jl_leaf_type(jlty)

        is_jl_basic(leaf_ty) && continue

        is_jl_unknown(leaf_ty) && return true

        extra = dag.ids_extra
        if haskey(extra, leaf_ty.sym) && is_jl_unsupported(extra[leaf_ty.sym])
            return true
        end
    end
    return false
end

"""
    attribute_check
Return `true` if the node has compiler attributes.
"""
function attribute_check end

attribute_check(dag::ExprDAG, node::ExprNode) = false

function attribute_check(dag::ExprDAG, node::ExprNode{<:Union{StructDefinition,StructMutualRef,UnionDefinition}})
    cursor = node.cursor
    hasAttrs(cursor) && return true
    for c in fields(getCursorType(cursor))
        hasAttrs(c) && return true
    end
    return false
end

function attribute_check(dag::ExprDAG, node::ExprNode{<:AbstractEnumNodeType})
    cursor = node.cursor
    hasAttrs(cursor) && return true
    # TODO: check impl
    return false
end

"""
    nested_anonymous_check
Return `true` if the node is a nested anonymous record type.
"""
function nested_anonymous_check end

nested_anonymous_check(dag::ExprDAG, node::ExprNode) = false

function nested_anonymous_check(dag::ExprDAG, node::ExprNode{<:Union{StructDefinition,StructMutualRef,UnionDefinition}})
    for c in fields(getCursorType(node.cursor))
        ty = getCursorType(c)
        occursin("anonymous", spelling(ty)) && return true
    end
    return false
end

"""
    bitfield_check
Return `true` if the node is a bitfield struct.
"""
function bitfield_check end

bitfield_check(dag::ExprDAG, node::ExprNode) = false

function bitfield_check(dag::ExprDAG, node::ExprNode{<:Union{StructDefinition,StructMutualRef}})
    for c in fields(getCursorType(node.cursor))
        isBitField(c) && return true
    end
    return false
end
