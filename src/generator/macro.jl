# FIXME: this file is a mess and needs to be purged.

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

const C_OPERATORS = [
    "*", "/", "%", "+", "-",
    "<<", ">>",
    "<", "<=", ">", ">=", "==", "!=",
    "&", "|", "^", "&&", "||",
]

function is_macro_binary_operator(toks)
    toks[1].kind != CXToken_Identifier && return false
    if toks.size == 4 &&
        toks[1].kind == CXToken_Identifier &&
        (toks[2].kind == CXToken_Literal || toks[2].kind == CXToken_Identifier) &&
        toks[3].kind == CXToken_Punctuation &&
        (toks[4].kind == CXToken_Literal || toks[4].kind == CXToken_Identifier) &&
        toks[3].text in C_OPERATORS
        # `#define SINGLE_BINARY_OP A | B`
        return true
    elseif toks.size == 6 &&
        toks[1].kind == CXToken_Identifier &&
        toks[2].kind == CXToken_Punctuation &&
        (toks[3].kind == CXToken_Literal || toks[3].kind == CXToken_Identifier) &&
        toks[4].kind == CXToken_Punctuation &&
        (toks[5].kind == CXToken_Literal || toks[5].kind == CXToken_Identifier) &&
        toks[6].kind == CXToken_Punctuation &&
        toks[4].text in C_OPERATORS
        # `#define SINGLE_BINARY_OP (A | B)`
        return true
    else
        return false
    end
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

function get_comment_expr(tokens)
    code = join([tok.text for tok in tokens], " ")
    return Expr(:block, "# Skipping MacroDefinition: " * code)
end


"""
    macro_emit!
Emit Julia expression for macros.
"""
function macro_emit! end

macro_emit!(dag::ExprDAG, node::ExprNode, options::Dict) = dag

function macro_emit!(dag::ExprDAG, node::ExprNode{MacroFunctionLike}, options::Dict)
    print_comment = get(options, "add_comment_for_skipped_macro", true)
    mode = get(options, "macro_mode", "basic")
    mode != "aggressive" && return dag

    cursor = node.cursor
    tokens = tokenize(cursor)

    toks = collect(tokens)
    lhs_sym = make_symbol_safe(tokens[1].text)

    i = findfirst(x->x.text == ")", toks)
    sig_ex = Meta.parse(mapreduce(x->x.text, *, toks[1:i]))
    sig_ex.args[1] = lhs_sym
    if i == tokens.size
        push!(node.exprs, Expr(:(=), sig_ex, nothing))
    else
        body_toks = toks[1+i:end]
        txts = [tok.kind == CXToken_Literal ? literally(tok) : tok.text for tok in body_toks]
        str = reduce(add_spaces_for_macros, txts)
        try
            push!(node.exprs, Expr(:(=), sig_ex, Meta.parse(str)))
        catch err
            print_comment && push!(node.exprs, get_comment_expr(tokens))
        end
    end

    return dag
end

function macro_emit!(dag::ExprDAG, node::ExprNode{MacroDefault}, options::Dict)
    mode = get(options, "macro_mode", "basic")
    print_comment = get(options, "add_comment_for_skipped_macro", true)
    ignore_header_guards = get(options, "ignore_header_guards", true)
    suffixes = get(options, "ignore_header_guards_with_suffixes", [])
    if ignore_header_guards
        endswith(string(node.id), "_H") && return dag
        for suffix in suffixes
            endswith(string(node.id), suffix) && return dag
        end
    end
    ignore_pure_def = get(options, "ignore_pure_definition", true)

    cursor = node.cursor
    tokens = tokenize(cursor)

    if !ignore_pure_def && is_macro_pure_definition(tokens)
        sym = make_symbol_safe(tokens[1].text)
        push!(node.exprs, Expr(:const, Expr(:(=), sym, :nothing)))
        return dag
    end

    if is_macro_constants(tokens)
        literal_tok = tokens.size == 2 ? tokens[2] : tokens[3]
        literals = literally(literal_tok)
        sym = make_symbol_safe(tokens[1].text)
        literal_sym = Meta.parse(literals)
        push!(node.exprs, Expr(:const, Expr(:(=), sym, literal_sym)))
        return dag
    end

    if is_macro_naive_alias(tokens)
        lhs, rhs = tokens
        lhs_sym = make_symbol_safe(lhs.text)
        rhs_sym = make_symbol_safe(rhs.text)
        push!(node.exprs, Expr(:const, Expr(:(=), lhs_sym, rhs_sym)))
        return dag
    end

    if is_macro_keyword_alias(tokens)
        lhs_sym = make_symbol_safe(tokens[1].text)
        keywords = [tok.text for tok in collect(tokens)[2:end] if tok.text ∉ C_KEYWORDS_CVR]
        str = join(keywords, " ")
        if all(x->x ∈ C_KEYWORDS_DATATYPE, keywords) && haskey(C_DATATYPE_TO_JULIA_DATATYPE, str)
            rhs_sym = C_DATATYPE_TO_JULIA_DATATYPE[str]
            push!(node.exprs, Expr(:const, Expr(:(=), lhs_sym, rhs_sym)))
        else
            print_comment && push!(node.exprs, get_comment_expr(tokens))
        end
        return dag
    end

    if is_macro_binary_operator(tokens)
        op_tok = tokens.size == 4 ? tokens[3] : tokens[4]
        op = op_tok.text == "/" ? Symbol("÷") :
             op_tok.text == "^" ? Symbol("⊻") : Symbol(op_tok.text)
        lhs_literal_tok = tokens.size == 4 ? tokens[2] : tokens[3]
        rhs_literal_tok = tokens.size == 4 ? tokens[4] : tokens[5]
        if lhs_literal_tok.kind == CXToken_Literal
            lhs_literals = literally(lhs_literal_tok)
        else
            lhs_literals = lhs_literal_tok.text
        end
        if rhs_literal_tok.kind == CXToken_Literal
            rhs_literals = literally(rhs_literal_tok)
        else
            rhs_literals = rhs_literal_tok.text
        end
        sym = make_symbol_safe(tokens[1].text)
        lhs_sym = Meta.parse(lhs_literals)
        rhs_sym = Meta.parse(rhs_literals)
        push!(node.exprs, Expr(:const, Expr(:(=), sym, Expr(:call, op, lhs_sym, rhs_sym))))
        return dag
    end

    # for all the other cases, we just blindly use Julia's Meta.parse to parse the C code.
    if tokens.size > 1 && tokens[1].kind == CXToken_Identifier && mode == "aggressive"
        sym = make_symbol_safe(tokens[1].text)
        try
            txts = [tok.kind == CXToken_Literal ? literally(tok) : tok.text for tok in collect(tokens)[2:end]]
            str = reduce(add_spaces_for_macros, txts)
            push!(node.exprs, Expr(:const, Expr(:(=), sym, Meta.parse(str))))
        catch err
            print_comment && push!(node.exprs, get_comment_expr(tokens))
        end
    else
        print_comment && push!(node.exprs, get_comment_expr(tokens))
    end

    return dag
end
