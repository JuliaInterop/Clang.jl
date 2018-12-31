using .LibClang.CEnum: enum_names, enum_name

cxname2clname(x::AbstractString) = "CL" * last(split(x, '_', limit=2))
cxname2clname(x::Symbol) = cxname2clname(string(x))

# each CXCursorKind enum gets a specific Julia type wrapping
# so that we can dispatch directly on node kinds.
abstract type CLCursor end

const CXCursorMap = Dict()

for sym in enum_names(CXCursorKind)
    clsym = Symbol(cxname2clname(sym))
    @eval begin
        struct $clsym <: CLCursor
            cursor::CXCursor
        end
        CXCursorMap[$sym] = $clsym
    end
end

CLCursor(c::CXCursor) = CXCursorMap[c.kind](c)
Base.convert(::Type{CXCursor}, x::T) where {T<:CLCursor} = x.cursor
Base.convert(::Type{CLCursor}, x::CXCursor) = CLCursor(x)


# each CXTypeKind enum gets a specific Julia type wrapping
# so that we can dispatch directly on node kinds.
abstract type CLType end

const CLTypeMap = Dict()

for sym in enum_names(CXTypeKind)
    clsym = Symbol(cxname2clname(sym))
    @eval begin
        struct $clsym <: CLType
            type::CXType
        end
        CLTypeMap[$sym] = $clsym
    end
end

CLType(c::CXType) = CLTypeMap[c.kind](c)
Base.convert(::Type{CXType}, x::T) where {T<:CLType} = x.cursor
Base.convert(::Type{CLType}, x::CXType) = CLType(x)


# CLToken
abstract type CLToken end

const CLTokenMap = Dict()

for sym in enum_names(CXTokenKind)
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

Base.convert(::Type{CXToken}, x::T) where {T<:CLToken} = x.token
