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
    prototype = node.exprs[1].args[1]
    prologue = ["    " * sprint(Base.show_unquoted, prototype), ""]
    print_documentation(io, node, "", options; prologue)
    for expr in node.exprs
        println(io, expr)
        println(io)
    end
    return nothing
end

function pretty_print(io, node::ExprNode{FunctionVariadic}, options::Dict)
    isempty(node.exprs) && return
    println(io, "# automatic type deduction for variadic arguments may not be what you want, please use with caution")
    for expr in node.exprs
        println(io, expr)
        println(io)
    end
    return nothing
end

function pretty_print(io, node::ExprNode{FunctionNoProto}, options::Dict)
    @assert !isempty(node.exprs)
    file, line, col = get_file_line_column(node.cursor)
    prototype = node.exprs[1].args[1]
    prologue = ["    " * sprint(Base.show_unquoted, prototype), ""]
    println(io, "# no prototype is found for this function at $(basename(file)):$line:$col, please use with caution")
    print_documentation(io, node, "", options)
    for expr in node.exprs
        println(io, expr)
        println(io)
    end
    return nothing
end

function pretty_print(io, node::ExprNode{TypedefElaborated}, options::Dict)
    print_documentation(io, node, "", options)
    for expr in node.exprs
        println(io, expr)
        println(io)
    end
    return nothing
end

function pretty_print(io, node::ExprNode{TypedefMutualRef}, options::Dict)
    print_documentation(io, node, "", options)
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
    println(io, "# " * replace(c_str, "\n" => "\n#"))
    
    # print documentation
    print_documentation(io, node, "", options)

    # print expr
    println(io, node.exprs[1])
    println(io)

    return nothing
end

function pretty_print(io, node::ExprNode{TypedefToAnonymous}, options::Dict)
    @assert length(node.exprs) == 1
    print_documentation(io, node, "", options)
    println(io, node.exprs[1])
    println(io)
    return nothing
end

function pretty_print(io, node::ExprNode{TypedefDefault}, options::Dict)
    print_documentation(io, node, "", options)
    for expr in node.exprs
        println(io, expr)
        println(io)
    end
    return nothing
end

function pretty_print(io, node::ExprNode{<:AbstractStructNodeType}, options::Dict)
    @assert !isempty(node.exprs)
    struct_def = node.exprs[1]
    mutable, name, members = struct_def.args
    print_documentation(io, node, "", options; prologue=["    $name", ""])

    # `chldren(node.cursor)` may also return forward declaration of struct type for example, so we filter these out.
    child_nodes = filter(x->x isa CLFieldDecl, children(node.cursor))
    @assert length(child_nodes) == length(members.args)
    mutable && print(io, "mutable ")
    println(io, "struct ", name)
    for (expr, child) in zip(members.args, child_nodes)
        print_documentation(io, child, "    ", options)
        println(io, "    ", string(expr))
    end
    println(io, "end")
    for expr in node.exprs[2:end]
        println(io, expr)
        println(io)
    end
    return nothing
end

function pretty_print(io, node::ExprNode{StructMutualRef}, options::Dict)
    @assert !isempty(node.exprs)
    expr = node.exprs[1]
    prologue = ["    $(expr.args[2])", ""]
    print_documentation(io, node, "", options; prologue)

    @assert Meta.isexpr(expr, :struct)
    mutability = expr.args[1] ? "mutable struct" : "struct"
    struct_name = expr.args[2]
    println(io, "$mutability $struct_name")

    block = expr.args[3]
    @assert Meta.isexpr(block, :block)

    child_nodes = filter(x->x isa CLFieldDecl, children(node.cursor))
    @assert length(child_nodes) == length(block.args)

    # A StructDecl is inserted before the FieldDecl with forward decl
    for (ex, child) in zip(block.args, child_nodes)
        print_documentation(io, child, "    ", options)
        if Meta.isexpr(ex, :block)
            println(io, "    ", string(ex.args[2]), " # ", string(ex.args[1]))
        else
            println(io, "    ", string(ex))
        end
    end
    println(io, "end")
    println(io)

    for expr in node.exprs[2:end]
        println(io, expr)
        println(io)
    end

    return nothing
end

function pretty_print(io, node::ExprNode{<:AbstractEnumNodeType}, options::Dict)
    @assert !isempty(node.exprs)
    use_native_enum = get(options, "use_julia_native_enum_type", false)
    enum_values = Dict()

    head = node.exprs[1]
    head_expr = head.args[3]

    prologue = ["    $(head_expr.args[1])", ""]
    print_documentation(io, node, "", options; prologue)

    if length(node.exprs) ≥ 2
        enum_macro = use_native_enum ? "@enum" : "@cenum"
        println(io, "$enum_macro $head_expr begin")
        child_nodes = filter(x->x isa CLEnumConstantDecl, children(node.cursor))
        @assert length(child_nodes) == length(node.exprs) - 1
        for (i, child) = zip(2:length(node.exprs), child_nodes)
            print_documentation(io, child, "    ", options)
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
        enum_name, int_ty = head_expr.args
        println(io, "const $enum_name = $int_ty")
    end
    println(io)

    return nothing
end

function pretty_print(io, node::ExprNode{<:RecordLayouts}, options::Dict)
    @assert !isempty(node.exprs)
    prologue = ["    $(node.exprs[1].args[2])", ""]
    print_documentation(io, node, "", options; prologue)
    for expr in node.exprs
        println(io, expr)
        println(io)
    end
    return nothing
end

pretty_print(io, node::ExprNode{<:ForwardDecls}, options::Dict) = nothing

function pretty_print(io, node::ExprNode{<:OpaqueTags}, options::Dict)
    @assert length(node.exprs) == 1
    print_documentation(io, node, "", options)
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
    general_options = get(options, "general", Dict())
    print_documentation(io, node, "", general_options)
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
