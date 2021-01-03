"""
    emit!
Emit Julia expression.
"""
function emit! end

emit!(dag::ExprDAG, node::ExprNode, options::Dict; args...) = dag

############################### Function ###############################

function emit!(dag::ExprDAG, node::ExprNode{FunctionProto}, options::Dict; args...)
    cursor = node.cursor

    library_name = options["library_name"]
    library_expr = Meta.parse(library_name)

    func_name = Symbol(spelling(cursor))
    func_args = get_function_args(cursor)
    arg_types = [getArgType(getCursorType(cursor), i - 1) for i in 1:length(func_args)]
    ret_type = translate(tojulia(getCursorResultType(cursor)), options)

    args = [translate(tojulia(arg), options) for arg in arg_types]
    for (i, arg) in enumerate(args)
        # array function arguments should decay to pointers
        # e.g. double f[3] => Ptr{Cdouble} instead of NTuple{3, Cdouble}
        if Meta.isexpr(arg, :curly) && first(arg.args) == :NTuple
            args[i] = Expr(:curly, :Ptr, last(arg.args))
        end
    end

    # handle unnamed args
    arg_names = Vector{Symbol}(undef, length(func_args))
    for (i, arg) in enumerate(func_args)
        ns = Symbol(name(arg))
        safe_name = make_name_safe(ns)
        safe_name = isempty(safe_name) ? "arg$i" : safe_name
        # handle name collisions
        if haskey(dag.tags, ns) || haskey(dag.ids, ns) || haskey(dag.ids_extra, ns)
            safe_name *= "_"
        end
        arg_names[i] = Symbol(safe_name)
    end

    is_strict_typed = get(options, "is_function_strictly_typed", false)
    signature = if is_strict_typed
        efunsig(func_name, arg_names, args)
    else
        Expr(:call, func_name, arg_names...)
    end

    body = :(ccall(
        ($(QuoteNode(func_name)), $library_expr),
        $ret_type,
        $(Expr(:tuple, args...)),
        $(arg_names...),
    ))

    push!(node.exprs, Expr(:function, signature, Expr(:block, body)))

    return dag
end

# TODO: clean up this
function is_ptr_type_expr(@nospecialize t)
    (t === :Cstring || t === :Cwstring) && return true
    isa(t, Expr) || return false
    t = t::Expr
    return t.head === :curly && t.args[1] === :Ptr
end

function efunsig(name::Symbol, args::Vector{Symbol}, types)
    x = [is_ptr_type_expr(t) ? a : Expr(:(::), a, t) for (a, t) in zip(args, types)]
    return Expr(:call, name, x...)
end

function emit!(dag::ExprDAG, node::ExprNode{FunctionNoProto}, options::Dict; args...)
    cursor = node.cursor
    @warn "No Prototype for $cursor - assuming no arguments"
    @assert isempty(get_function_args(cursor))

    library_name = options["library_name"]
    library_expr = Meta.parse(library_name)

    func_name = Symbol(spelling(cursor))
    ret_type = translate(tojulia(getCursorResultType(cursor)))

    signature = Expr(:call, func_name)
    body = :(ccall(($(QuoteNode(func_name)), $library_expr), $ret_type, $(Expr(:tuple))))

    push!(node.exprs, Expr(:function, signature, Expr(:block, body)))

    return dag
end

function emit!(dag::ExprDAG, node::ExprNode{FunctionVariadic}, options::Dict; args...)
    # TODO: add impl
    return dag
end


############################### Typedef ###############################

function emit!(dag::ExprDAG, node::ExprNode{TypedefElaborated}, options::Dict; args...)
    if haskey(dag.tags, node.id) || haskey(dag.ids_extra, node.id)
        # generate nothing for duplicated typedef nodes
        # pass
    else
        ty = getTypedefDeclUnderlyingType(node.cursor)
        typedefee = translate(tojulia(ty), options)
        typedef_sym = make_symbol_safe(node.id)
        push!(node.exprs, :(const $typedef_sym = $typedefee))
    end
    return dag
end

function emit!(dag::ExprDAG, node::ExprNode{TypedefFunction}, options::Dict; args...)
    ty = getTypedefDeclUnderlyingType(node.cursor)
    typedefee = translate(tojulia(ty), options)
    typedef_sym = make_symbol_safe(node.id)
    push!(node.exprs, :(const $typedef_sym = $typedefee))
    return dag
end

function emit!(dag::ExprDAG, node::ExprNode{TypedefDefault}, options::Dict; args...)
    ty = getTypedefDeclUnderlyingType(node.cursor)
    typedefee = translate(tojulia(ty), options)
    typedef_sym = make_symbol_safe(node.id)
    push!(node.exprs, :(const $typedef_sym = $typedefee))
    return dag
end

function emit!(dag::ExprDAG, node::ExprNode{TypedefToAnonymous}, options::Dict; args...)
    typedefee = node.type.sym
    typedef_sym = make_symbol_safe(node.id)
    push!(node.exprs, :(const $typedef_sym = $typedefee))
    return dag
end


############################### Struct ###############################

function emit!(dag::ExprDAG, node::ExprNode{<:AbstractStructNodeType}, options::Dict; args...)
    struct_sym = make_symbol_safe(node.id)
    block = Expr(:block)
    expr = Expr(:struct, false, struct_sym, block)
    for field_cursor in fields(getCursorType(node.cursor))
        field_sym = make_symbol_safe(name(field_cursor))
        field_ty = getCursorType(field_cursor)
        push!(block.args, Expr(:(::), field_sym, translate(tojulia(field_ty), options)))
    end
    push!(node.exprs, expr)
    return dag
end

function replace_pointee!(expr, s::Symbol)
    if Meta.isexpr(expr, :curly)
        if expr.args[2] isa Expr
            replace_pointee!(expr.args[2], s)
        elseif expr.args[2] isa Symbol
            expr.args[2] = s
        end
    end
    return nothing
end

function emit!(dag::ExprDAG, node::ExprNode{StructMutualRef}, options::Dict; args...)
    node_idx = args[:idx]
    struct_sym = make_symbol_safe(node.id)
    block = Expr(:block)
    expr = Expr(:struct, false, struct_sym, block)
    for field_cursor in fields(getCursorType(node.cursor))
        field_sym = make_symbol_safe(name(field_cursor))
        field_ty = getCursorType(field_cursor)
        jlty = tojulia(field_ty)
        leaf_ty = get_jl_leaf_type(jlty)
        translated = translate(jlty, options)

        if !is_jl_basic(leaf_ty)
            # this assumes tag-types and identifiers that have the same name are the same
            # thing, which is validated in the audit pass.
            field_idx = get(dag.tags, leaf_ty.sym, typemax(Int))
            if field_idx == typemax(Int)
                field_idx = get(dag.ids, leaf_ty.sym, typemax(Int))
            end

            # if `leaf_ty.sym` can not be found in `tags` and `ids` then it's in `ids_extra`
            field_idx == typemax(Int) && @assert haskey(dag.ids_extra, leaf_ty.sym)

            if node_idx < field_idx
                # this assumes that circular references were removed at pointers
                @assert is_jl_pointer(jlty)

                # also emit the original expressions, so we can add corresponding comments
                # in the pretty-print pass
                comment = Expr(:(::), field_sym, deepcopy(translated))
                push!(block.args, Expr(:block, comment))
                replace_pointee!(translated, :Cvoid)
            end
        end

        push!(block.args, Expr(:(::), field_sym, translated))
    end

    push!(node.exprs, expr)

    return dag
end

function get_getter_expr(field_cursor::CLCursor, prefix::String)
    n = name(field_cursor)
    if isempty(n)

    else

    end
    field_sym = make_symbol_safe(n)
end

# codegen for memory-pool-like structures
function emit!(dag::ExprDAG, node::ExprNode{<:RecordLayouts}, options::Dict; args...)
    sym = make_symbol_safe(node.id)
    n = getSizeOf(getCursorType(node.cursor))
    expr = Expr(:struct, false, sym, Expr(:block, :(data::NTuple{$n,UInt8})))
    push!(node.exprs, expr)

    # Base.getproperty
    signature = Expr(:call, :(Base.getproperty), :(x::Ptr{$sym}), :(f::Symbol))
    body = Expr(:block)
    for fcursor in fields(getCursorType(node.cursor))
        n = name(fcursor)
        fsym = make_symbol_safe(n)
        fty = getCursorType(fcursor)
        offset = getOffsetOf(getCursorType(node.cursor), n)
        ex = :(f === $fsym && return unsafe_load(Ptr{$fsym}(pointer_from_objref(x) + $offset)))
        push!(body.args, ex)
    end
    getter_expr = Expr(:function, signature, body)

    push!(node.exprs, getter_expr)

    return dag
end

const ENUM_SYMBOL2TYPE = Dict(
    :Cchar => Cchar,
    :Cuchar => Cuchar,
    :Cshort => Cshort,
    :Cushort => Cushort,
    :Clong => Clong,
    :Culong => Culong,
    :Cwchar_t => Cwchar_t,
    :Clonglong => Clonglong,
    :Culonglong => Culonglong,
    :Cint => Cint,
    :Cuint => Cuint,
    :Cintmax_t => Cintmax_t,
    :Cuintmax_t => Cuintmax_t,
    :Cptrdiff_t => Cptrdiff_t,
    :Cssize_t => Cssize_t,
    :UInt64 => UInt64,
    :UInt32 => UInt32,
    :UInt16 => UInt16,
    :UInt8 => UInt8,
    :Int64 => Int64,
    :Int32 => Int32,
    :Int16 => Int16,
    :Int8 => Int8,
)

############################### Enum ###############################

function emit!(dag::ExprDAG, node::ExprNode{<:AbstractEnumNodeType}, options::Dict; args...)
    cursor = node.cursor
    ty = translate(tojulia(getEnumDeclIntegerType(cursor)), options)
    # there is no need to treat __attribute__ specially as we directly query the integer
    # type of the enum from Clang
    enum_type = ENUM_SYMBOL2TYPE[ty]
    @assert Core.sizeof(enum_type) == getSizeOf(getCursorType(cursor))

    enum_sym = make_symbol_safe(node.id)
    expr = Expr(:macrocall, Symbol("@cenum"), nothing, Expr(:(::), enum_sym, enum_type))
    push!(node.exprs, expr)

    for item_cursor in children(cursor)
        item_cursor isa CLEnumConstantDecl || continue
        item_name = spelling(item_cursor)
        @assert !isempty(item_name)
        item_sym = make_symbol_safe(item_name)
        val = value(item_cursor)
        push!(node.exprs, :($item_sym = $val))
    end

    return dag
end


##################### ForwardDecl OpaqueDecl DefaultDecl #####################

# skip non-opaque forward decls
emit!(dag::ExprDAG, node::ExprNode{<:ForwardDecls}, options::Dict; args...) = dag

function emit!(dag::ExprDAG, node::ExprNode{<:OpaqueTags}, options::Dict; args...)
    struct_sym = make_symbol_safe(node.id)
    if get(options, "opaque_as_mutable_struct", true)
        push!(node.exprs, Expr(:struct, true, struct_sym, Expr(:block)))
    else
        push!(node.exprs, :(const $struct_sym = Cvoid))
    end
    return dag
end

function emit!(dag::ExprDAG, node::ExprNode{<:UnknownDefaults}, options::Dict; args...)
    @error "missing implementation for $(node), please file an issue to Clang.jl."
    return dag
end
