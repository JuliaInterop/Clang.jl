"""
    emit!
Emit Julia expression.
"""
function emit! end

emit!(dag::ExprDAG, node::ExprNode, options::Dict; args...) = dag

############################### Function ###############################

function _get_func_name(cursor, options)
    library_name = options["library_name"]
    haskey(options, "library_names") || return library_name
    file_name = get_filename(cursor) |> normpath
    ks = filter(x->endswith(file_name, Regex(x)), collect(keys(options["library_names"])))
    if !isempty(ks)
        library_name = options["library_names"][ks[1]] # FIXME: same file name in different folders?
    end
    return library_name
end

"Get argument names and types. Return (names, types)."
function _get_func_arg(cursor, options, dag)
    # argument names
    conflict_syms = get(options, "function_argument_conflict_symbols", [])
    func_args = get_function_args(cursor)
    # handle unnamed args
    arg_names = Vector{Symbol}(undef, length(func_args))
    for (i, arg) in enumerate(func_args)
        ns = Symbol(name(arg))
        safe_name = make_name_safe(ns)
        safe_name = isempty(safe_name) ? "arg$i" : safe_name
        # handle name collisions
        if haskey(dag.tags, ns) || haskey(dag.ids, ns) || haskey(dag.ids_extra, ns)
            safe_name *= "_"
        elseif safe_name ∈ conflict_syms
            safe_name = "_" * safe_name
        end
        arg_names[i] = Symbol(safe_name)
    end

    # argument types
    arg_types = [getArgType(getCursorType(cursor), i - 1) for i in 1:length(func_args)]
    args = Union{Expr,Symbol}[translate(tojulia(arg), options) for arg in arg_types]
    for (i, arg) in enumerate(args)
        # array function arguments should decay to pointers
        # e.g. double f[3] => Ptr{Cdouble} instead of NTuple{3, Cdouble}
        if Meta.isexpr(arg, :curly) && first(arg.args) == :NTuple
            args[i] = Expr(:curly, :Ptr, last(arg.args))
        end

        # do the same test for the underlying type of a typedef
        c = getTypeDeclaration(arg_types[i])
        if c isa CLTypedefDecl
            ty = getCanonicalType(getTypedefDeclUnderlyingType(c))
            jl = translate(tojulia(ty), options)
            if Meta.isexpr(jl, :curly) && first(jl.args) == :NTuple
                args[i] = Expr(:curly, :Ptr, last(jl.args))
            end
        end
    end
    return arg_names, args
end

function _get_func_return_type(cursor, options)
    translate(tojulia(getCursorResultType(cursor)), options)
end

function emit!(dag::ExprDAG, node::ExprNode{FunctionProto}, options::Dict; args...)
    cursor = node.cursor

    library_name = _get_func_name(cursor, options)
    library_expr = Meta.parse(library_name)

    func_name = Symbol(spelling(cursor))

    arg_names, args = _get_func_arg(cursor, options, dag)
    ret_type = _get_func_return_type(cursor, options)

    is_strict_typed = get(options, "is_function_strictly_typed", false)
    signature = if is_strict_typed
        efunsig(func_name, arg_names, args)
    else
        Expr(:call, func_name, arg_names...)
    end

    use_ccall_macro = get(options, "use_ccall_macro", false)
    if use_ccall_macro
        name_type_pairs = [Expr(:(::), n, t) for (n, t) in zip(arg_names, args)]
        library_func = library_expr == nothing ? func_name : :($library_expr.$func_name)
        body = Expr(:macrocall, Symbol("@ccall"), nothing,
                    Expr(:(::), Expr(:call,
                                        library_func,
                                        name_type_pairs...,
                                    ),
                         ret_type
                        )
                    )
    else
        body = :(ccall(
            ($(QuoteNode(func_name)), $library_expr),
            $ret_type,
            $(Expr(:tuple, args...)),
            $(arg_names...),
        ))
    end

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
    use_ccall_macro = get(options, "use_ccall_macro", false)
    cursor = node.cursor
    @warn "No Prototype for $cursor - assuming no arguments"
    @assert getNumArguments(cursor) == 0

    library_name = _get_func_name(cursor, options)
    library_expr = Meta.parse(library_name)

    func_name = Symbol(spelling(cursor))
    ret_type = translate(tojulia(getCursorResultType(cursor)), options)

    signature = Expr(:call, func_name)
    if use_ccall_macro
        call = :($library_expr.$func_name()::$ret_type)
        body = Expr(:macrocall, Symbol("@ccall"), nothing, call)
    else
        body = :(ccall(($(QuoteNode(func_name)), $library_expr), $ret_type, $(Expr(:tuple))))
    end

    push!(node.exprs, Expr(:function, signature, Expr(:block, body)))

    return dag
end

function emit!(dag::ExprDAG, node::ExprNode{FunctionVariadic}, options::Dict; args...)
    # @ccall is needed to support variadic argument
    use_ccall_macro = get(options, "use_ccall_macro", true)
    wrap_variadic_function = get(options, "wrap_variadic_function", false)
    if use_ccall_macro && wrap_variadic_function
        cursor = node.cursor
        is_strict_typed = get(options, "is_function_strictly_typed", false)
        arg_names, args = _get_func_arg(cursor, options, dag)
        ret_type = _get_func_return_type(cursor, options)
        library_name = _get_func_name(cursor, options)
        library_expr = Meta.parse(library_name)
        func_name = Symbol(spelling(cursor))

        signature = is_strict_typed ? efunsig(func_name, arg_names, args) : Expr(:call, func_name, arg_names...)
        push!(signature.args, :(va_list...))

        fixed_args = map(arg_names, args) do name, type
            :($name::$type)
        end
        va_list_expr = Expr(:$, :(to_c_type_pairs(va_list)...))
        ccall_body = :($library_expr.$func_name($(fixed_args...); $va_list_expr)::$ret_type)
        ccall_expr = Expr(:macrocall, Symbol("@ccall"), nothing, ccall_body)
        body = quote
            $(Meta.quot(ccall_expr))
        end

        generated = Expr(:function, signature, body)
        ex = Expr(:macrocall, Symbol("@generated"), nothing, generated)
        rm_line_num_node!(ex)
        push!(node.exprs, ex)
    end
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

function emit!(dag::ExprDAG, node::ExprNode{TypedefMutualRef}, options::Dict; args...)
    if haskey(dag.tags, node.id) || haskey(dag.ids_extra, node.id)
        # generate nothing for duplicated typedef nodes
        # pass
    else
        ty = getTypedefDeclUnderlyingType(node.cursor)
        jlty = tojulia(ty)
        leaf_ty = get_jl_leaf_type(jlty)

        # first, we generate a fake struct
        real_sym = leaf_ty.sym
        fake_sym = Symbol("__JL_$real_sym")
        push!(node.exprs, Expr(:struct, true, fake_sym, Expr(:block)))
        # then, generate overloading methods to emulates the behavior
        # `Base.unsafe_load`
        signature = Expr(:call, :(Base.unsafe_load), :(x::Ptr{$fake_sym}))
        body = Expr(:block, :(unsafe_load(Ptr{$real_sym}(x))))
        push!(node.exprs, Expr(:function, signature, body))
        # `Base.getproperty`
        signature = Expr(:call, :(Base.getproperty), :(x::Ptr{$fake_sym}), :(f::Symbol))
        body = Expr(:block, :(getproperty(Ptr{$real_sym}(x), f)))
        push!(node.exprs, Expr(:function, signature, body))
        # `Base.setproperty!`
        signature = Expr(:call, :(Base.setproperty!), :(x::Ptr{$fake_sym}), :(f::Symbol), :v)
        body = Expr(:block, :(setproperty!(Ptr{$real_sym}(x), f, v)))
        push!(node.exprs, Expr(:function, signature, body))

        # These exprs for `Base.unsafe_convert()` need to be emitted after the
        # struct named `real_sym` has been emitted so that we can use `real_sym`
        # in the method signature (which is necessary to avoid a method
        # ambiguity with Base). Hence we add it to `node.premature_exprs` to be
        # used later when the struct itself is emitted.
        lhs = Expr(:call, :(Base.unsafe_convert), :(::Type{Ptr{$fake_sym}}), :(x::Base.RefValue{$real_sym}))
        rhs = :(Base.unsafe_convert(Ptr{$fake_sym}, Base.unsafe_convert(Ptr{$real_sym}, x)))
        push!(node.premature_exprs, :($lhs = $rhs))
        # make sure the behavior remains the same for `Ptr`
        lhs = Expr(:call, :(Base.unsafe_convert), :(::Type{Ptr{$fake_sym}}), :(x::Ptr{$real_sym}))
        rhs = :(Ptr{$fake_sym}(x))
        push!(node.premature_exprs, :($lhs = $rhs))

        # generate typedef
        typedefee = translate(jlty, options)
        replace_pointee!(typedefee, fake_sym)
        typedef_sym = make_symbol_safe(node.id)
        push!(node.exprs, :(const $typedef_sym = $typedefee))

        # Record this node as only partially emitted
        dag.partially_emitted_nodes[real_sym] = node
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
    ty = getTypedefDeclUnderlyingType(node.cursor)
    typedefee = translate(tojulia(ty), options)
    typedef_sym = make_symbol_safe(node.id)
    push!(node.exprs, :(const $typedef_sym = $typedefee))
    return dag
end

############################## TypeAlias #############################

function emit!(dag::ExprDAG, node::ExprNode{TypeAliasFunction}, options::Dict; args...)
    typedefee = Ptr{Cvoid}
    typedef_sym = make_symbol_safe(node.id)
    push!(node.exprs, :(const $typedef_sym = $typedefee))
    return dag
end

############################### Struct ###############################

function _emit_pointer_access!(body, root_cursor, cursor, options)
    field_cursors = fields(getCursorType(cursor))
    field_cursors = isempty(field_cursors) ? children(cursor) : field_cursors
    for field_cursor in field_cursors
        n = name(field_cursor)
        if isempty(n)
            _emit_pointer_access!(body, root_cursor, field_cursor, options)
            continue
        end
        fsym = make_symbol_safe(n)
        fty = getCursorType(field_cursor)
        ty = translate(tojulia(fty), options)
        offset = getOffsetOf(getCursorType(root_cursor), n)

        if isBitField(field_cursor)
            w = getFieldDeclBitWidth(field_cursor)
            @assert w <= 32 # Bit fields should not be larger than int(32 bits)
            d, r = divrem(offset, 32)
            ex = :(f === $(QuoteNode(fsym)) && return (Ptr{$ty}(x + $(4d)), $r, $w))
        else
            d = offset ÷ 8
            ex = :(f === $(QuoteNode(fsym)) && return Ptr{$ty}(x + $d))
        end
        push!(body.args, ex)
    end
end

# getptr(x::Ptr, f::Symbol) -> Ptr
function emit_getptr!(dag, node, options)
    sym = make_symbol_safe(node.id)
    signature = Expr(:call, :getptr, :(x::Ptr{$sym}), :(f::Symbol))
    body = Expr(:block)
    _emit_pointer_access!(body, node.cursor, node.cursor, options)

    push!(body.args, :(error($("Unrecognized field of type `$sym`") * ": $f")))
    push!(node.exprs, Expr(:function, signature, body))
    return dag
end

function emit_deref_getproperty!(body, root_cursor, cursor, options)
    field_cursors = fields(getCursorType(cursor))
    field_cursors = isempty(field_cursors) ? children(cursor) : field_cursors
    for field_cursor in field_cursors
        n = name(field_cursor)
        if isempty(n)
            emit_deref_getproperty!(body, root_cursor, field_cursor, options)
            continue
        end
        fsym = make_symbol_safe(n)
        fty = getCursorType(field_cursor)
        canonical_type = getCanonicalType(fty)

        return_expr = :(getptr(x, f))

        # Automatically dereference all field types except for nested structs
        # and arrays.
        if !(canonical_type isa Union{CLRecord, CLConstantArray}) && !isBitField(field_cursor)
            return_expr = :(unsafe_load($return_expr))
        elseif isBitField(field_cursor)
            return_expr = :(getbitfieldproperty(x, $return_expr))
        end

        ex = :(f === $(QuoteNode(fsym)) && return $return_expr)
        push!(body.args, ex)
    end
end

# Base.getproperty(x::Ptr, f::Symbol)
function emit_getproperty_ptr!(dag, node, options)
    auto_deref = get(options, "auto_field_dereference", false)
    sym = make_symbol_safe(node.id)

    # If automatically dereferencing, we first need to emit getptr!()
    if auto_deref
        emit_getptr!(dag, node, options)
    end

    signature = Expr(:call, :(Base.getproperty), :(x::Ptr{$sym}), :(f::Symbol))
    body = Expr(:block)
    if auto_deref
        emit_deref_getproperty!(body, node.cursor, node.cursor, options)
    else
        _emit_pointer_access!(body, node.cursor, node.cursor, options)
    end
    push!(body.args, :(return getfield(x, f)))
    getproperty_expr = Expr(:function, signature, body)
    push!(node.exprs, getproperty_expr)
    return dag
end

function rm_line_num_node!(ex::Expr)
    filter!(ex.args) do arg
        arg isa Expr && rm_line_num_node!(arg)
        !isa(arg, LineNumberNode)
    end
    return ex
end

function emit_getproperty!(dag, node, options)
    sym = make_symbol_safe(node.id)

    # Build the macrocall manually so we can set the extra LineNumberNode to
    # nothing to stop it from being printed.
    return_expr = :(GC.@preserve r getproperty(ptr, f))
    return_expr.args[2] = nothing

    ex = quote
        function Base.getproperty(x::$sym, f::Symbol)
            r = Ref{$sym}(x)
            ptr = Base.unsafe_convert(Ptr{$sym}, r)
            return $return_expr
        end
    end

    # Remove line number nodes and the enclosing :block node
    rm_line_num_node!(ex)
    ex = ex.args[1]

    push!(node.exprs, ex)

    return dag
end

function emit_setproperty!(dag, node, options)
    sym = make_symbol_safe(node.id)
    signature = Expr(:call, :(Base.setproperty!), :(x::Ptr{$sym}), :(f::Symbol), :v)

    auto_deref = get(options, "auto_field_dereference", false)
    pointer_getter = auto_deref ? :getptr : :getproperty
    store_expr = :(unsafe_store!($pointer_getter(x, f), v))

    if is_bitfield_type(node.type)
        body = quote
            fptr = $pointer_getter(x, f)
            if fptr isa Ptr
                $store_expr
            else
                # setbitfieldproperty!() is emitted by ProloguePrinter
                setbitfieldproperty!(fptr, v)
            end
        end
        rm_line_num_node!(body)
    else
        body = Expr(:block, store_expr)
    end
    setproperty_expr = Expr(:function, signature, body)
    push!(node.exprs, setproperty_expr)
    return dag
end

function get_names_types(root_cursor, cursor, options)
    field_cursors = fields(getCursorType(cursor))
    field_cursors = isempty(field_cursors) ? children(cursor) : field_cursors
    tys = []
    fsyms = []
    for field_cursor in field_cursors
        n = name(field_cursor)
        if isempty(n)
            _emit_pointer_access!(root_cursor, field_cursor, options)
            continue
        end
        fsym = make_symbol_safe(n)
        fty = getCursorType(field_cursor)
        ty = translate(tojulia(fty), options)
        push!(tys, ty)
        push!(fsyms, fsym)
    end
    fsyms, tys
end

function emit_constructor!(dag, node::ExprNode{<:AbstractUnionNodeType}, options)
    sym = make_symbol_safe(node.id)
    fsyms, tys = get_names_types(node.cursor, node.cursor, options)
    union_sym = Symbol(:__U_, sym)
    push!(node.exprs, :(const $union_sym = Union{$(tys...)}))
    body = Expr(:block,
        :(ref = Ref{$sym}()),
        :(ptr = Base.unsafe_convert(Ptr{$sym}, ref)),
    )

    if get(options, "union_single_constructor", false)
        branch_args = map(zip(fsyms, tys)) do (fsym, ty)
            cond = :(val isa $ty)
            assign = :(ptr.$fsym = val)
            (cond, assign)
        end

        first_args, rest = Iterators.peel(branch_args)
        ex = Expr(:if, first_args...)
        push!(body.args, ex)
        foreach(rest) do (cond, assign)
            _ex = Expr(:elseif, cond, assign)
            push!(ex.args, _ex)
            ex = _ex
        end

        push!(body.args, :(ref[]))
        push!(node.exprs, Expr(:function, Expr(:call, sym, :(val::$union_sym)), body))
    else
        foreach(zip(fsyms, tys)) do (fsym, ty)
            _body = copy(body)
            append!(_body.args,
                [
                    :(ptr.$fsym = $fsym),
                    :(ref[]),
                ]
            )
            func = Expr(:function, :($sym($fsym::$ty)), _body)
            push!(node.exprs, func)
        end
    end
end

function emit_constructor!(dag, node::ExprNode{<:StructLayout}, options)
    sym = make_symbol_safe(node.id)
    fsyms, tys = get_names_types(node.cursor, node.cursor, options)
    body = quote
        ref = Ref{$sym}()
        ptr = Base.unsafe_convert(Ptr{$sym}, ref)
        $((:(ptr.$fsym = $fsym) for fsym in fsyms)...)
        ref[]
    end

    rm_line_num_node!(body)

    func = Expr(:function, Expr(:call, sym, (:($fsym::$ty) for (fsym, ty) in zip(fsyms, tys))...), body)
    push!(node.exprs, func)
end

function extract_fields(cursor::CLCursor)
    field_cursors = fields(getCursorType(cursor))
    !isempty(field_cursors) && return field_cursors
    # `chldren(cursor)` may also return forward declaration of struct type for example, so we filter these out.
    filter(x->x isa CLFieldDecl, children(cursor))
end

function emit!(dag::ExprDAG, node::ExprNode{<:AbstractStructNodeType}, options::Dict; args...)
    struct_sym = make_symbol_safe(node.id)
    block = Expr(:block)
    expr = Expr(:struct, false, struct_sym, block)
    for field_cursor in extract_fields(node.cursor)
        field_sym = make_symbol_safe(name(field_cursor))
        field_ty = getCursorType(field_cursor)
        push!(block.args, Expr(:(::), field_sym, translate(tojulia(field_ty), options)))
    end
    push!(node.exprs, expr)

    if startswith(string(node.id), "##Ctag") || startswith(string(node.id), "__JL_Ctag")
        emit_getproperty_ptr!(dag, node, options)
        emit_getproperty!(dag, node, options)
        emit_setproperty!(dag, node, options)
    end

    if haskey(options, "field_access_method_list")
        if string(node.id) in options["field_access_method_list"]
            emit_getproperty_ptr!(dag, node, options)
            # emit_getproperty!(dag, node, options)
            emit_setproperty!(dag, node, options)
        end
    end

    # Emit any existing premature expressions
    if haskey(dag.partially_emitted_nodes, struct_sym)
        partial_node = dag.partially_emitted_nodes[struct_sym]
        append!(node.exprs, partial_node.premature_exprs)
        empty!(partial_node.premature_exprs)
        delete!(dag.partially_emitted_nodes, struct_sym)
    end

    return dag
end

function emit!(dag::ExprDAG, node::ExprNode{StructMutualRef}, options::Dict; args...)
    node_idx = args[:idx]
    struct_sym = make_symbol_safe(node.id)
    block = Expr(:block)
    expr = Expr(:struct, false, struct_sym, block)
    mutual_ref_field_cursors = CLCursor[]
    for field_cursor in extract_fields(node.cursor)
        field_sym = make_symbol_safe(name(field_cursor))
        field_ty = getCursorType(field_cursor)
        jlty = tojulia(field_ty)
        leaf_ty = get_jl_leaf_type(jlty)
        translated = translate(jlty, options)

        if jlty != leaf_ty && !is_jl_basic(leaf_ty)
            # this assumes tag-types and identifiers that have the same name are the same
            # thing, which is validated in the audit pass.
            field_idx = get(dag.tags, leaf_ty.sym, typemax(Int))
            if field_idx == typemax(Int)
                field_idx = get(dag.ids, leaf_ty.sym, typemax(Int))
            end

            # if `leaf_ty.sym` can not be found in `tags` and `ids` then it's in `ids_extra`
            field_idx == typemax(Int) && @assert haskey(dag.ids_extra, leaf_ty.sym)

            if node_idx < field_idx && field_idx != typemax(Int)
                # this assumes that circular references were removed at pointers
                @assert is_jl_pointer(jlty) "Expected this field to be a pointer: $(struct_sym).$(field_sym)"

                # also emit the original expressions, so we can add corresponding comments
                # in the pretty-print pass
                comment = Expr(:(::), field_sym, deepcopy(translated))
                replace_pointee!(translated, :Cvoid)
                push!(mutual_ref_field_cursors, field_cursor)
                # Avoid pushing two expressions for one field
                push!(block.args, Expr(:block, comment, :($field_sym::$translated)))
                continue
            end
        end

        push!(block.args, Expr(:(::), field_sym, translated))
    end

    push!(node.exprs, expr)

    # make corrections by overloading `Base.getproperty` for those `Ptr{Cvoid}` fields
    if !isempty(mutual_ref_field_cursors)
        getter = Expr(:call, :(Base.getproperty), :(x::$struct_sym), :(f::Symbol))
        body = Expr(:block)
        for mrfield_cursor in mutual_ref_field_cursors
            n = name(mrfield_cursor)
            @assert !isempty(n)
            fsym = make_symbol_safe(n)
            fty = getCursorType(mrfield_cursor)
            ty = translate(tojulia(fty), options)
            ex = :(f === $(QuoteNode(fsym)) && return $ty(getfield(x, f)))
            push!(body.args, ex)
        end
        push!(body.args, :(return getfield(x, f)))
        getproperty_expr = Expr(:function, getter, body)
        push!(node.exprs, getproperty_expr)
    end

    if haskey(options, "field_access_method_list")
        if string(node.id) in options["field_access_method_list"]
            emit_getproperty_ptr!(dag, node, options)
            # emit_getproperty!(dag, node, options)
            emit_setproperty!(dag, node, options)
        end
    end

    return dag
end

# codegen for memory-pool-like structures
function emit!(dag::ExprDAG, node::ExprNode{<:RecordLayouts}, options::Dict; args...)
    sym = make_symbol_safe(node.id)
    n = getSizeOf(getCursorType(node.cursor))
    expr = Expr(:struct, false, sym, Expr(:block, :(data::NTuple{$n,UInt8})))
    push!(node.exprs, expr)

    # emit Base.getproperty(x::Ptr, f::Symbol) etc.
    emit_getproperty_ptr!(dag, node, options)
    emit_getproperty!(dag, node, options)
    emit_setproperty!(dag, node, options)

    opt = get(options, "add_record_constructors", [])
    if (opt isa Bool && opt) || sym in opt
        emit_constructor!(dag, node, options)
    end

    return dag
end

############################### Enum ###############################
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

function emit!(dag::ExprDAG, node::ExprNode{<:AbstractEnumNodeType}, options::Dict; args...)
    cursor = node.cursor
    ty = getEnumDeclIntegerType(cursor)
    if ty isa Clang.CLTypedef
        ty = getTypeDeclaration(ty) |>
             getTypedefDeclUnderlyingType |>
             getCanonicalType
    end
    ty = translate(tojulia(ty), options)

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


################## ForwardDecl OpaqueDecl DefaultDecl DuplicatedTags ##################

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

# skip duplicated nodes
emit!(dag::ExprDAG, node::ExprNode{<:DuplicatedTags}, options::Dict; args...) = dag
