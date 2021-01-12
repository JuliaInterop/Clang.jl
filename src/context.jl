abstract type AbstractContext end

mutable struct DefaultContext <: AbstractContext
    index::Index
    trans_units::Vector{TranslationUnit}
    options::Dict{String,Bool}
    libname::String
    force_name::String  # a tmp cursor name
    common_buffer::OrderedDict{Symbol,ExprUnit}
    api_buffer::Vector
    cursor_stack::Vector{CLCursor}
    children::Vector{CLCursor}
    children_index::Int
    anonymous_counter::Int
end
function DefaultContext(index::Index)
    return DefaultContext(
        index,
        TranslationUnit[],
        Dict{String,Bool}(),
        "libxxx",
        "",
        OrderedDict{Symbol,ExprUnit}(),
        [],
        CLCursor[],
        CLCursor[],
        -1,
        0,
    )
end
DefaultContext(diagnostic::Bool=true) = DefaultContext(Index(diagnostic))

function parse_header!(ctx::AbstractContext, header::AbstractString; args...)
    return push!(ctx.trans_units, parse_header(header; args...))
end
function parse_headers!(ctx::AbstractContext, headers::Vector{String}; args...)
    return (ctx.trans_units = parse_headers(headers; args...))
end
