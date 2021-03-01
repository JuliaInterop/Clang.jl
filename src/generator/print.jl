"""
    pretty_print
Pretty-print a buffer of expressions (and comments) to an output stream, add
blank lines at appropriate places for readability, and also apply some simple
post-editing.
"""
function pretty_print end

function pretty_print(io, node::ExprNode, options::Dict)
    # warn if the node has been edited in the codegen pass.
    # this usually happens when certain new node type is support in the codegen,
    # but the corresponding `pretty_print` method is missing.
    !isempty(node.exprs) && @warn "skip a node that has non-empty expressions. is the corresponding `pretty_print` method defined?"
    return nothing
end

function pretty_print(io, node::ExprNode{FunctionProto}, options::Dict)
    @assert !isempty(node.exprs)
    for expr in node.exprs
        println(io, expr)
        println(io)
    end
    return nothing
end

function pretty_print(io, node::ExprNode{FunctionNoProto}, options::Dict)
    @assert !isempty(node.exprs)
    file, line, col = get_file_line_column(node.cursor)
    println(io, "# no prototype is found for this function at $(basename(file)):$line:$col, please use with caution")
    for expr in node.exprs
        println(io, expr)
        println(io)
    end
    return nothing
end

function pretty_print(io, node::ExprNode{TypedefElaborated}, options::Dict)
    for expr in node.exprs
        println(io, expr)
        println(io)
    end
    return nothing
end

function pretty_print(io, node::ExprNode{TypedefMutualRef}, options::Dict)
    for expr in node.exprs
        println(io, expr)
        println(io)
    end
    return nothing
end

function pretty_print(io, node::ExprNode{TypedefFunction}, options::Dict)
    @assert length(node.exprs) == 1

    # print C code
    toks = tokenize(node.cursor)
    c_str = reduce((lhs, rhs) -> lhs * " " * rhs, [tok.text for tok in toks])
    println(io, "# C code:")
    println(io, "# " * c_str)

    # print expr
    println(io, node.exprs[1])
    println(io)

    return nothing
end

function pretty_print(io, node::ExprNode{TypedefToAnonymous}, options::Dict)
    @assert length(node.exprs) == 1
    println(io, node.exprs[1])
    println(io)
    return nothing
end

function pretty_print(io, node::ExprNode{TypedefDefault}, options::Dict)
    for expr in node.exprs
        println(io, expr)
        println(io)
    end
    return nothing
end

function pretty_print(io, node::ExprNode{<:AbstractStructNodeType}, options::Dict)
    @assert !isempty(node.exprs)
    for expr in node.exprs
        println(io, expr)
        println(io)
    end
    return nothing
end

function pretty_print(io, node::ExprNode{StructMutualRef}, options::Dict)
    @assert length(node.exprs) == 1
    expr = node.exprs[1]

    @assert Meta.isexpr(expr, :struct)
    mutability = expr.args[1] ? "mutable struct" : "struct"
    struct_name = expr.args[2]
    println(io, "$mutability $struct_name")

    block = expr.args[3]
    @assert Meta.isexpr(block, :block)
    for ex in block.args
        if Meta.isexpr(ex, :block)
            println(io, "    # " * string(ex.args[1]))
        else
            println(io, "    " * string(ex))
        end
    end
    println(io, "end")
    println(io)

    return nothing
end

function pretty_print(io, node::ExprNode{<:AbstractEnumNodeType}, options::Dict)
    @assert !isempty(node.exprs)
    use_native_enum = get(options, "use_julia_native_enum_type", false)
    enum_values = Dict()

    head = node.exprs[1]
    head_expr = head.args[3]
    if length(node.exprs) ≥ 2
        enum_macro = use_native_enum ? "@enum" : "@cenum"
        println(io, "$enum_macro $head_expr begin")
        for i = 2:length(node.exprs)
            expr = node.exprs[i]
            if use_native_enum
                n, v = expr.args
                if haskey(enum_values, v)
                    println(io, "    # " * string(expr))
                    continue
                end
                enum_values[v] = n
            end
            println(io, "    " * string(expr))
        end
        println(io, "end")
    else
        # for empty enums, we make it an alias of the corresponding integer type
        enum_name, int_ty = head_expr.args[3].args
        println(io, "const $enum_name = $int_ty")
    end
    println(io)

    return nothing
end

function pretty_print(io, node::ExprNode{<:RecordLayouts}, options::Dict)
    @assert !isempty(node.exprs)
    for expr in node.exprs
        println(io, expr)
        println(io)
    end
    return nothing
end

pretty_print(io, node::ExprNode{<:ForwardDecls}, options::Dict) = nothing

function pretty_print(io, node::ExprNode{<:OpaqueTags}, options::Dict)
    @assert length(node.exprs) == 1
    expr = node.exprs[1]

    codegen_ops = get(options, "codegen", Dict())
    opaque_as_mutable = get(codegen_ops, "opaque_as_mutable_struct", true)

    if opaque_as_mutable && Meta.isexpr(expr, :struct)
        struct_name = expr.args[2]
        println(io, "mutable struct $struct_name end")
    else
        println(io, expr)
    end
    println(io)
    return nothing
end

pretty_print(io, node::ExprNode{<:UnknownDefaults}, options::Dict) = nothing
pretty_print(io, node::ExprNode{<:DuplicatedTags}, options::Dict) = nothing

## EXPERIMENTAL
function pretty_print(io, node::ExprNode{<:AbstractMacroNodeType}, options::Dict)
    for expr in node.exprs
        if Meta.isexpr(expr, :block)
            println(io, string(expr.args[1]))
        else
            println(io, expr)
        end
        println(io)
    end
    return nothing
end
