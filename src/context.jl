abstract type AbstractContext end

mutable struct DefaultContext <: AbstractContext
    index::Index
    trans_units::Dict{String,TranslationUnit}
    options::Dict{String,Bool}
    libname::String
    common_buffer::OrderedDict{Symbol,ExprUnit}
    api_buffer::Vector{Expr}
    cursor_stack::Vector{CXCursor}
    children::Vector{CXCursor}
    children_index::Int
end
DefaultContext(index::Index) = DefaultContext(index, Dict{String,TranslationUnit}(), Dict{String,Bool}(),
                                              "libxxx", OrderedDict{Symbol,ExprUnit}(), Expr[],
                                              CXCursor[], CXCursor[], -1)
DefaultContext(diagnostic::Bool) = DefaultContext(Index(diagnostic))

parse_header!(ctx::AbstractContext, header::AbstractString; args...) = (ctx.trans_units[header]=parse_header(headers; args...);)
parse_headers!(ctx::AbstractContext, headers::Vector{String}; args...) = merge!(ctx.trans_units, parse_headers(headers; args...))
