"""
Unsupported argument types
"""
const RESERVED_ARG_TYPES = ["va_list"]

"""
    wrap!(ctx::AbstractContext, cursor::CLFunctionDecl)
Subroutine for handling function declarations.
"""
function wrap!(ctx::AbstractContext, cursor::CLFunctionDecl)
    func_type = type(cursor)
    if kind(func_type) == CXType_FunctionNoProto
        @warn "No Prototype for $cursor - assuming no arguments"
    elseif isvariadic(func_type)
        @warn "Skipping VarArg Function $cursor"
        return ctx
    end

    func_name = isempty(ctx.force_name) ? Symbol(spelling(cursor)) : ctx.force_name
    ret_type = clang2julia(return_type(cursor))
    args = function_args(cursor)
    arg_types = [argtype(func_type, i) for i in 0:(length(args) - 1)]
    # if argtypes contains any ObjectveC's block pointer, then skip this function
    for at in arg_types
        if kind(canonical(at)) == CXType_BlockPointer
            @info "  Skipping Function with ObjectveC's block pointer $cursor"
            return ctx
        end
    end

    arg_reps = clang2julia.(arg_types)
    for (i, arg) in enumerate(arg_reps)
        # constant array argument should be converted to Ptr
        # e.g. double f[3] => Ptr{Cdouble} instead of NTuple{3, Cdouble}
        # TODO: Julia 1.6+ `NTuple{3, Cdouble}` should be fine
        if Meta.isexpr(arg, :curly) && first(arg.args) == :NTuple
            arg_reps[i] = Expr(:curly, :Ptr, last(arg.args))
        end
    end

    # check whether any argument types are blocked
    for t in arg_types
        if spelling(t) in RESERVED_ARG_TYPES
            @warn "Skipping $(name(cursor)) due to unsupported argument: $(spelling(t))"
            return ctx
        end
    end

    # handle unnamed args and convert names to symbols
    arg_count = 0
    arg_names = map(args) do x
        n = name_safe(name(x))
        s = !isempty(n) ? n : "arg" * string(arg_count += 1)
        return Symbol(s)
    end

    isstrict = get(ctx.options, "is_function_strictly_typed", true)
    signature = if isstrict
        efunsig(func_name, arg_names, arg_reps)
    else
        Expr(:call, func_name, arg_names...)
    end

    ctx.libname == "libxxx" &&
        @warn "default libname: \":libxxx\" are being used, did you forget to specify `context.libname`?"
    body = eccall(func_name, Symbol(ctx.libname), ret_type, arg_names, arg_reps)

    push!(ctx.api_buffer, Expr(:function, signature, Expr(:block, body)))

    return ctx
end

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

function eccall(func_name::Symbol, libname::Symbol, rtype, args, types)
    return :(ccall(
        ($(QuoteNode(func_name)), $libname), $rtype, $(Expr(:tuple, types...)), $(args...)
    ))
end

"""
    wrap!(ctx::AbstractContext, cursor::CLEnumDecl)
Subroutine for handling enum declarations.
"""
function wrap!(ctx::AbstractContext, cursor::CLEnumDecl)
    cursor_name = name(cursor)
    # handle typedef anonymous enum
    idx = ctx.children_index
    if 0 < idx < length(ctx.children)
        next_cursor = ctx.children[idx + 1]
        if is_typedef_anon(cursor, next_cursor)
            cursor_name = name(next_cursor)
        end
    end
    !isempty(ctx.force_name) && (cursor_name = ctx.force_name)
    if cursor_name == ""
        @warn "  Skipping unnamed EnumDecl: $cursor"
        return ctx
    end

    enum_sym = symbol_safe(cursor_name)
    enum_type = INT_CONVERSION[clang2julia(cursor)]
    name2value = Tuple{Symbol,Int}[]
    # extract values and names
    for item_cursor in children(cursor)
        kind(item_cursor) == CXCursor_PackedAttr && (
            @warn("this is a `__attribute__((packed))` enum, the underlying alignment of generated structure may not be compatible with the original one in C!"); continue
        )
        item_name = spelling(item_cursor)
        isempty(item_name) && continue
        item_sym = symbol_safe(item_name)
        push!(name2value, (item_sym, value(item_cursor)))
    end

    expr = Expr(:macrocall, Symbol("@cenum"), nothing, Expr(:(::), enum_sym, enum_type))
    enum_pairs = Expr(:block)
    ctx.common_buffer[enum_sym] = ExprUnit(expr)
    for (name, value) in name2value
        ctx.common_buffer[name] = ctx.common_buffer[enum_sym]
        push!(enum_pairs.args, :($name = $value))
    end
    push!(expr.args, enum_pairs)

    return ctx
end

"""
    wrap!(ctx::AbstractContext, cursor::CLStructDecl)
Subroutine for handling struct declarations.
"""
function wrap!(ctx::AbstractContext, cursor::CLStructDecl)
    # make sure a empty struct is indeed an opaque struct typedef/typealias
    # cursor = canonical(cursor)  # this won't work
    cursor = typedecl(canonical(type(cursor)))
    cursor_name = name(cursor)
    # handle typedef anonymous struct
    idx = ctx.children_index
    if 0 < idx < length(ctx.children)
        next_cursor = ctx.children[idx + 1]
        if is_typedef_anon(cursor, next_cursor)
            cursor_name = name(next_cursor)
        end
    end
    !isempty(ctx.force_name) && (cursor_name = ctx.force_name)
    cursor_name == "" && (@warn("  Skipping unnamed StructDecl: $cursor"); return ctx)

    struct_sym = symbol_safe(cursor_name)
    ismutable = get(ctx.options, "is_struct_mutable", false)
    buffer = ctx.common_buffer

    # generate struct declaration
    block = Expr(:block)
    expr = Expr(:struct, ismutable, struct_sym, block)
    deps = OrderedSet{Symbol}()
    struct_fields = children(cursor)
    for (field_idx, field_cursor) in enumerate(struct_fields)
        field_name = name(field_cursor)
        field_kind = kind(field_cursor)
        if field_kind == CXCursor_StructDecl || field_kind == CXCursor_UnionDecl
            continue
        elseif field_kind == CXCursor_FirstAttr
            continue
        elseif field_kind != CXCursor_FieldDecl || field_kind == CXCursor_TypeRef
            buffer[struct_sym] = ExprUnit(Poisoned())
            @warn "Skipping struct: \"$cursor\" due to unsupported field: $field_cursor"
            return ctx
        elseif isempty(field_name)
            error("Unnamed struct member in: $cursor ... cursor: $field_cursor")
        end

        if occursin("anonymous", string(clang2julia(field_cursor)))
            idx = field_idx - 1
            anonymous_record = struct_fields[idx]
            while idx != 0 && kind(anonymous_record) == CXCursor_FieldDecl
                idx -= 1
                anonymous_record = struct_fields[idx]
            end
            if idx == field_idx - 1
                ctx.anonymous_counter += 1
                anon_name = "ANONYMOUS$(ctx.anonymous_counter)_" * spelling(field_cursor)
                ctx.force_name = anon_name
                wrap!(ctx, anonymous_record)
                ctx.force_name = ""
                repr = symbol_safe(anon_name)
            else
                anon_name =
                    "ANONYMOUS$(ctx.anonymous_counter)_" * spelling(struct_fields[idx + 1])
                repr = symbol_safe(anon_name)
            end
        else
            repr = clang2julia(field_cursor)
        end
        push!(block.args, Expr(:(::), symbol_safe(field_name), repr))
        push!(deps, target_type(repr))
    end

    # check for a previous forward ordering
    if !(struct_sym in keys(buffer)) || buffer[struct_sym].state == :empty
        if !isempty(struct_fields)
            buffer[struct_sym] = ExprUnit(expr, deps)
        else
            # opaque struct typedef/typealias
            buffer[struct_sym] = ExprUnit(:(const $struct_sym = Cvoid), deps; state=:empty)
        end
    end

    return ctx
end

"""
    wrap!(ctx::AbstractContext, cursor::CLUnionDecl)
Subroutine for handling union declarations.
"""
function wrap!(ctx::AbstractContext, cursor::CLUnionDecl)
    # make sure a empty union is indeed an opaque union typedef/typealias
    cursor = typedecl(canonical(type(cursor)))
    cursor_name = name(cursor)
    # handle typedef anonymous union
    idx = ctx.children_index
    if 0 < idx < length(ctx.children)
        next_cursor = ctx.children[idx + 1]
        if is_typedef_anon(cursor, next_cursor)
            cursor_name = name(next_cursor)
        end
    end
    !isempty(ctx.force_name) && (cursor_name = ctx.force_name)
    cursor_name == "" && (@warn("  Skipping unnamed UnionDecl: $cursor"); return ctx)

    union_sym = symbol_safe(cursor_name)
    ismutable = get(ctx.options, "is_struct_mutable", false)
    buffer = ctx.common_buffer

    block = Expr(:block)
    expr = Expr(:struct, ismutable, union_sym, block)
    deps = OrderedSet{Symbol}()
    # find the largest union field and declare a block of bytes to match.
    union_fields = children(cursor)
    if !isempty(union_fields)
        max_size = 0
        largest_field_idx = 0
        for i in 1:length(union_fields)
            field_cursor = union_fields[i]
            field_kind = kind(field_cursor)
            (field_kind == CXCursor_StructDecl || field_kind == CXCursor_UnionDecl) &&
                continue
            field_kind == CXCursor_FirstAttr && continue
            field_size = typesize(type(field_cursor))
            if field_size > max_size
                max_size = field_size
                largest_field_idx = i
            end
        end
        largest_field = union_fields[largest_field_idx]
        if occursin("anonymous", string(clang2julia(largest_field)))
            idx = largest_field_idx - 1
            anonymous_record = union_fields[idx]
            while idx != 0 && kind(anonymous_record) == CXCursor_FieldDecl
                idx -= 1
                anonymous_record = union_fields[idx]
            end
            ctx.anonymous_counter += 1
            anon_name = "ANONYMOUS$(ctx.anonymous_counter)_" * spelling(largest_field)
            ctx.force_name = anon_name
            wrap!(ctx, anonymous_record)
            ctx.force_name = ""
            repr = symbol_safe(anon_name)
        else
            repr = clang2julia(largest_field)
        end
        largest_field_sym = symbol_safe(spelling(largest_field))
        push!(block.args, Expr(:(::), largest_field_sym, repr))
        push!(deps, target_type(repr))
        buffer[union_sym] = ExprUnit(expr, deps)
    elseif !(union_sym in keys(buffer)) || buffer[union_sym].state == :empty
        buffer[union_sym] = ExprUnit(:(const $union_sym = Cvoid), deps; state=:empty)
    else
        @warn "Skipping union: \"$cursor\" due to unknown cases."
    end

    return ctx
end

"""
    wrap!(ctx::AbstractContext, cursor::CLTypedefDecl)
Subroutine for handling typedef declarations.
"""
function wrap!(ctx::AbstractContext, cursor::CLTypedefDecl)
    td_type = underlying_type(cursor)
    td_sym = isempty(ctx.force_name) ? Symbol(spelling(cursor)) : ctx.force_name
    buffer = ctx.common_buffer

    if kind(td_type) == CXType_Unexposed
        @error "  Skipping Typedef: CXType_Unexposed, $cursor, please report please report this to https://github.com/JuliaInterop/Clang.jl/issues."
    end

    # skip ObjectveC's block pointers
    if kind(td_type) == CXType_BlockPointer
        @info "  Skipping Typedef: CXType_BlockPointer, $cursor, ObjectveC's block pointers are intendedly not supported."
        return ctx
    end

    if kind(td_type) == CXType_FunctionProto
        if !haskey(buffer, td_sym)
            buffer[td_sym] = ExprUnit(:(const $td_sym = Cvoid))
        end
        return ctx
    end

    td_target = clang2julia(td_type)
    if !haskey(buffer, td_sym)
        buffer[td_sym] = ExprUnit(:(const $td_sym = $td_target), [td_target])
    end
    return ctx
end

## macros
const LITERAL_LONG = ["L", "l"]
const LITERAL_ULONG = ["UL", "Ul", "uL", "ul", "LU", "Lu", "lU", "lu"]
const LITERAL_ULONGLONG = ["ULL", "Ull", "uLL", "ull", "LLU", "LLu", "llU", "llu"]
const LITERAL_LONGLONG = ["LL", "ll"]

const LITERAL_SUFFIXES = [
    LITERAL_ULONGLONG..., LITERAL_LONGLONG..., LITERAL_ULONG..., LITERAL_LONG...,
    "U", "u", "F", "f"
]

function literal_totype(literal, txt)
    literal = lowercase(literal)

    # Floats following http://en.cppreference.com/w/cpp/language/floating_literal
    float64 = occursin(".", txt) && occursin("l", literal)  # long double
    float32 = occursin("f", literal)

    if float64 || float32
        float64 && return "Float64"
        float32 && return "Float32"
    end

    # Integers following http://en.cppreference.com/w/cpp/language/integer_literal
    unsigned = occursin("u", literal)
    if unsigned && (endswith(literal, "llu") || endswith(literal, "ull"))
        return "Culonglong"
    elseif !unsigned && endswith(literal, "ll")
        return "Clonglong"
    elseif occursin("ul", literal) || occursin("lu", literal)
        return "Culong"
    elseif !unsigned && endswith(literal, "l")
        return "Clong"
    else
        return unsigned ? "Cuint" : "Cint"
    end
end

normalize_literal(tok) = strip(tok.text)

function normalize_literal(tok::Literal)
    txt = strip(tok.text)
    for sfx in LITERAL_SUFFIXES
        if endswith(txt, sfx)
            type = literal_totype(sfx, txt)
            txt = txt[1:(end - length(sfx))]
            return "$(type)($txt)"
        end
    end
    # Char to Cchar
    if match(r"^'.*'$", txt) !== nothing
        return "Cchar($txt)"
    end
    return txt
end

function literally(tok)
    m = match(r"^0[0-9]*\d$", tok.text)
    if m !== nothing && m.match !== "0"
        literals = "0o"*normalize_literal(tok)
    else
        literals = normalize_literal(tok)
    end
    if occursin('\$', literals)
        return "($(replace(literals, "\$"=>"\\\$")))"
    else
        return "($literals)"
    end
end

is_macro_pure_definition(toks) = toks.size == 1 && toks[1].kind == CXToken_Identifier

function is_macro_constants(toks)
    if toks.size == 2 &&
        toks[1].kind == CXToken_Identifier &&
        toks[2].kind == CXToken_Literal
        # `#define CONSTANT_LITERALS_1 0`
        return true
    elseif toks.size == 4 &&
        toks[1].kind == CXToken_Identifier &&
        toks[2].kind == CXToken_Punctuation &&
        toks[3].kind == CXToken_Literal &&
        toks[4].kind == CXToken_Punctuation
        # `#define CONSTANT_LITERALS_BRACKET ( 0x10u )`
        return true
    else
        return false
    end
end

function is_macro_naive_alias(toks)
    if toks.size == 2 &&
        toks[1].kind == CXToken_Identifier &&
        toks[2].kind == CXToken_Identifier
        # `#define CONSTANT_ALIAS CONSTANT_LITERALS_1`
        return true
    else
        return false
    end
end

const C_KEYWORDS_DATATYPE = [
    "char", "double", "float", "int", "long", "short", "signed", "unsigned", "void",
    "_Bool", "_Complex", "_Noreturn"
    ]
const C_KEYWORDS_CVR = ["const", "volatile", "restrict"]
const C_KEYWORDS = [
    C_KEYWORDS_DATATYPE..., "auto", "break", "case",  "continue", "default", "do",
    "else", "enum", "extern", "for", "goto", "if", "inline", "register",
    "return", "sizeof", "static", "struct", "switch", "typedef", "union",
    "while", "_Alignas", "_Alignof", "_Atomic", "_Decimal128", "_Decimal32",
    "_Decimal64", "_Generic", "_Imaginary", "_Static_assert", "_Thread_local"
    ]

const C_DATATYPE_TO_JULIA_DATATYPE = Dict(
    "char"                      => :Cchar,
    "double"                    => :Float64,
    "float"                     => :Float32,
    "int"                       => :Cint,
    "long"                      => :Clong,
    "short"                     => :Cshort,
    "void"                      => :Cvoid,
    "_Bool"                     => :Cuchar,
    "_Complex float"            => :ComplexF32,
    "_Complex double"           => :ComplexF64,
    "_Noreturn"                 => :(Union{}),
    "signed char"               => :Int8,
    "signed int"                => :Cint,
    "signed long"               => :Clong,
    "signed short"              => :Cshort,
    "unsigned char"             => :Cuchar,
    "unsigned int"              => :Cuint,
    "unsigned long"             => :Culong,
    "unsigned short"            => :Cushort,
    "long long"                 => :Clonglong,
    "long long int"             => :Clonglong,
    "signed long long int"      => :Clonglong,
    "unsigned long long"        => :Culonglong,
    "unsigned long long int"    => :Culonglong
)

function is_macro_keyword_alias(toks)
    if toks.size ≥ 2 && toks[1].kind == CXToken_Identifier
        toks_kind = [tok.kind for tok in collect(toks)[2:end]]
        return all(x -> x == CXToken_Keyword, toks_kind)
    else
        return false
    end
end

function is_macro_has_compiler_reserved_keyword(toks)
    for tok in toks
        startswith(tok.text, "__") && return true
    end
    return false
end

function add_spaces_for_macros(lhs, rhs)
    if startswith(rhs, "(")  # handle function call
        if endswith(lhs, "?") || endswith(lhs, ":") # handle trinary operator
            return lhs * " " * rhs
        else
            return lhs * rhs
        end
    else
        return lhs * " " * rhs
    end
end


"""
    wrap!(ctx::AbstractContext, cursor::CLMacroDefinition)
Subroutine for handling macro declarations.
"""
function wrap!(ctx::AbstractContext, cursor::CLMacroDefinition)
    # skip built-in macros
    isbuiltin(cursor) && return ctx

    tokens = tokenize(cursor)
    buffer = ctx.common_buffer

    if is_macro_has_compiler_reserved_keyword(tokens)
        str = join([tok.text for tok in tokens], " ")
        buffer[Symbol(str)] = ExprUnit("# Skipping MacroDefinition: " * str)
        return ctx
    end

    if isfunctionlike(cursor)
        toks = collect(tokens)
        lhs_sym = symbol_safe(tokens[1].text)
        i = findfirst(x->x.text == ")", toks)
        sig_ex = Meta.parse(mapreduce(x->x.text, *, toks[1:i]))
        sig_ex.args[1] = lhs_sym
        if i == tokens.size
            ex = Expr(:(=), sig_ex, nothing)
            buffer[lhs_sym] = ExprUnit(ex)
        else
            try
                body_toks = toks[1+i:end]
                txts = [tok.kind == CXToken_Literal ? literally(tok) : tok.text for tok in body_toks]
                str = reduce(add_spaces_for_macros, txts)
                ex = Expr(:(=), sig_ex, Meta.parse(str))
                buffer[lhs_sym] = ExprUnit(ex)
            catch err
                str = join([tok.text for tok in tokens], " ")
                buffer[Symbol(str)] = ExprUnit("# Skipping MacroDefinition: " * str)
            end
        end
        return ctx
    end

    if is_macro_pure_definition(tokens)
        sym = symbol_safe(tokens[1].text)
        ex = Expr(:const, Expr(:(=), sym, :nothing))
        buffer[sym] = ExprUnit(ex)
        return ctx
    end

    if is_macro_constants(tokens)
        literal_tok = tokens.size == 2 ? tokens[2] : tokens[3]
        literals = literally(literal_tok)
        sym = symbol_safe(tokens[1].text)
        literal_sym = Meta.parse(literals)
        ex = Expr(:const, Expr(:(=), sym, literal_sym))
        buffer[sym] = ExprUnit(ex)
        return ctx
    end

    if is_macro_naive_alias(tokens)
        lhs, rhs = tokens
        lhs_sym = symbol_safe(lhs.text)
        rhs_sym = symbol_safe(rhs.text)
        ex = Expr(:const, Expr(:(=), lhs_sym, rhs_sym))
        buffer[lhs_sym] = ExprUnit(ex)
        return ctx
    end

    if is_macro_keyword_alias(tokens)
        lhs_sym = symbol_safe(tokens[1].text)
        keywords = [tok.text for tok in collect(tokens)[2:end] if tok.text ∉ C_KEYWORDS_CVR]
        str = join(keywords, " ")
        if all(x->x ∈ C_KEYWORDS_DATATYPE, keywords) && haskey(C_DATATYPE_TO_JULIA_DATATYPE, str)
            rhs_sym = C_DATATYPE_TO_JULIA_DATATYPE[str]
            ex = Expr(:const, Expr(:(=), lhs_sym, rhs_sym))
            buffer[lhs_sym] = ExprUnit(ex)
        else
            str = join([tok.text for tok in tokens], " ")
            buffer[Symbol(str)] = ExprUnit("# Skipping MacroDefinition: " * str)
        end
        return ctx
    end

    # for all the other cases, we just blindly use Julia's Meta.parse to parse the C code.
    if tokens.size > 1 && tokens[1].kind == CXToken_Identifier
        sym = symbol_safe(tokens[1].text)
        try
            txts = [tok.kind == CXToken_Literal ? literally(tok) : tok.text for tok in collect(tokens)[2:end]]
            str = reduce(add_spaces_for_macros, txts)
            ex = Expr(:const, Expr(:(=), sym, Meta.parse(str)))
            buffer[sym] = ExprUnit(ex)
        catch err
            str = join([tok.text for tok in tokens], " ")
            buffer[Symbol(str)] = ExprUnit("# Skipping MacroDefinition: " * str)
        end
    end
    return ctx
end

function wrap!(ctx::AbstractContext, cursor::CLMacroInstantiation)
    @debug "Skipping without wrapping $(cursor)"
    return ctx
end

function wrap!(ctx::AbstractContext, cursor::CLLastPreprocessing)
    @debug "Skipping without wrapping $(cursor)"
    return ctx
end

"""
    wrap!(ctx::AbstractContext, cursor::CLTypeRef)
For now, we just skip CXCursor_TypeRef cursors.
"""
function wrap!(ctx::AbstractContext, cursor::CLTypeRef)
    @warn "Skipping CXCursor_TypeRef cursor: $cursor"
    return ctx
end

function wrap!(ctx::AbstractContext, cursor::CLCursor)
    @error "Skipping without wrapping $(cursor), please report this to https://github.com/JuliaInterop/Clang.jl/issues."
    dumpobj(cursor)
    return ctx
end
