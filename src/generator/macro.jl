# as C's expression shares some similarities with Julia's expression, we just do some tweaks
# on the tokens and then try to parse them using Julia's `Meta.parse`

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

const LITERAL_LONG = ["L", "l"]
const LITERAL_ULONG = ["UL", "Ul", "uL", "ul", "LU", "Lu", "lU", "lu"]
const LITERAL_ULONGLONG = ["ULL", "Ull", "uLL", "ull", "LLU", "LLu", "llU", "llu"]
const LITERAL_LONGLONG = ["LL", "ll"]

const LITERAL_SUFFIXES = [
    LITERAL_ULONGLONG..., LITERAL_LONGLONG..., LITERAL_ULONG..., LITERAL_LONG...,
    "U", "u", "F", "f"
]

function c_literal_to_julia(txt, sfx)
    sfx = lowercase(sfx)

    # floats following http://en.cppreference.com/w/cpp/language/floating_literal
    float64 = occursin(".", txt) && occursin("l", sfx)  # long double
    float32 = occursin("f", sfx)

    if float64 || float32
        float64 && return "Float64"
        float32 && return "Float32"
    end

    # integers following http://en.cppreference.com/w/cpp/language/integer_literal
    unsigned = occursin("u", sfx)
    if unsigned && (endswith(sfx, "llu") || endswith(sfx, "ull"))
        return "Culonglong"
    elseif !unsigned && endswith(sfx, "ll")
        return "Clonglong"
    elseif occursin("ul", sfx) || occursin("lu", sfx)
        return "Culong"
    elseif !unsigned && endswith(sfx, "l")
        return "Clong"
    else
        return unsigned ? "Cuint" : "Cint"
    end
end

function normalize_literal_type(text::AbstractString)
    txt = strip(text)
    for sfx in LITERAL_SUFFIXES
        if endswith(txt, sfx)
            type = c_literal_to_julia(txt, sfx)
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

function normalize_literal(text)
    m = match(r"^0[0-9]*\d$", text)
    if m !== nothing && m.match !== "0"
        strs = "0o"*normalize_literal_type(text)
    else
        strs = normalize_literal_type(text)
    end
    if occursin('\$', strs)
        return "($(replace(strs, "\$"=>"\\\$")))"
    else
        return "($strs)"
    end
end

normalize_punctuation(text) = text == "/" ? "÷" : text == "^" ? "⊻" : text

is_literal(tok::CLToken) = tok.kind == CXToken_Literal
is_identifier(tok::CLToken) = tok.kind == CXToken_Identifier
is_punctuation(tok::CLToken) = tok.kind == CXToken_Punctuation
is_keyword(tok::CLToken) = tok.kind == CXToken_Keyword
is_comment(tok::CLToken) = tok.kind == CXToken_Comment

const DUMMY_TOKEN = CXToken((0,0,0,0), C_NULL)

function tweak_exprs(toks::Vector)
    new_toks = []
    i = 1
    while i ≤ length(toks)
        tok = toks[i]
        if is_literal(tok)
            push!(new_toks, Literal(DUMMY_TOKEN, CXToken_Literal, normalize_literal(tok.text)))
            i += 1
        elseif is_punctuation(tok)
            push!(new_toks, Punctuation(DUMMY_TOKEN, CXToken_Punctuation, normalize_punctuation(tok.text)))
            i += 1
        elseif is_keyword(tok)
            j = i
            while j ≤ length(toks) && is_keyword(toks[j])
                j += 1
            end
            txt = ""
            for k = i:j-1
                txt = txt * " " * toks[k].text
            end
            txt = strip(txt)
            if haskey(C_DATATYPE_TO_JULIA_DATATYPE, txt)
                txt = string(C_DATATYPE_TO_JULIA_DATATYPE[txt])
                push!(new_toks, Keyword(DUMMY_TOKEN, CXToken_Keyword, txt))
                i = j
            else
                push!(new_toks, tok)
                i += 1
            end
        else
            push!(new_toks, tok)
            i += 1
        end
    end
    return new_toks
end

# `#define SOMETHING`
is_macro_definition_only(toks::Vector) = length(toks) == 1 && is_identifier(toks[1])
is_macro_definition_only(toks::TokenList) = toks.size == 1 && is_identifier(toks[1])
is_macro_definition_only(cursor::CLCursor) = is_macro_definition_only(tokenize(cursor))

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

function macro_emit!(dag::ExprDAG, node::ExprNode{MacroDefinitionOnly}, options::Dict)
    if !get(options, "ignore_pure_definition", true)
        tokens = tokenize(node.cursor)
        sym = make_symbol_safe(tokens[1].text)
        push!(node.exprs, Expr(:const, Expr(:(=), sym, :nothing)))
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

    cursor = node.cursor
    tokens = collect(tokenize(cursor))
    tokens = tweak_exprs(tokens)

    @assert length(tokens) > 1

    sym = make_symbol_safe(tokens[1].text)
    txts = Vector{String}(undef, length(tokens)-1)
    for (i, tok) in enumerate(collect(tokens)[2:end])
        txts[i] = tok.text
    end
    str = reduce(add_spaces_for_macros, txts)
    try
        push!(node.exprs, Expr(:const, Expr(:(=), sym, Meta.parse(str))))
    catch err
        print_comment && push!(node.exprs, get_comment_expr(tokens))
    end

    return dag
end

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
    if i == length(tokens)
        push!(node.exprs, Expr(:(=), sig_ex, nothing))
    else
        body_toks = toks[1+i:end]
        txts = [tok.text for tok in body_toks]
        str = reduce(add_spaces_for_macros, txts)
        try
            push!(node.exprs, Expr(:(=), sig_ex, Meta.parse(str)))
        catch err
            print_comment && push!(node.exprs, get_comment_expr(tokens))
        end
    end

    return dag
end
