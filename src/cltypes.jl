using .LibClang.CEnum: name_value_pairs

cxname2clname(x::AbstractString) = "CL" * last(split(x, '_', limit=2))
cxname2clname(x::Symbol) = cxname2clname(string(x))

# each CXCursorKind enum gets a specific Julia type wrapping
# so that we can dispatch directly on node kinds.
abstract type CLCursor end

const CXCursorMap = Dict()

for (sym, val) in name_value_pairs(CXCursorKind)
    clsym = Symbol(cxname2clname(sym))
    @eval begin
        struct $clsym <: CLCursor
            cursor::CXCursor
        end
        CXCursorMap[$sym] = $clsym
    end
end

CLCursor(c::CXCursor) = CXCursorMap[c.kind](c)
Base.convert(::Type{T}, x::CXCursor) where {T<:CLCursor} = CLCursor(x)
Base.cconvert(::Type{CXCursor}, x::CLCursor) = x
Base.unsafe_convert(::Type{CXCursor}, x::CLCursor) = x.cursor

# each CXTypeKind enum gets a specific Julia type wrapping
# so that we can dispatch directly on node kinds.
abstract type CLType end

const CLTypeMap = Dict()

for (sym, val) in name_value_pairs(CXTypeKind)
    clsym = Symbol(cxname2clname(sym))
    @eval begin
        struct $clsym <: CLType
            type::CXType
        end
        CLTypeMap[$sym] = $clsym
    end
end

CLType(c::CXType) = CLTypeMap[c.kind](c)
Base.convert(::Type{T}, x::CXType) where {T<:CLType} = CLType(x)
Base.cconvert(::Type{CXType}, x::CLType) = x
Base.unsafe_convert(::Type{CXType}, x::CLType) = x.type

# CLToken
abstract type CLToken end

const CLTokenMap = Dict()

for (sym, val) in name_value_pairs(CXTokenKind)
    clsym = split(string(sym), '_', limit=2) |> last |> Symbol
    @eval begin
        struct $clsym <: CLToken
            token::CXToken
            kind::CXTokenKind
            text::String
        end
        CLTokenMap[$sym] = $clsym
    end
end

Base.cconvert(::Type{CXToken}, x::CLToken) = x
Base.unsafe_convert(::Type{CXToken}, x::CLToken) = x.token
