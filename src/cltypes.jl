using .LibClang.CEnum: name_value_pairs

cxname2clname(x::AbstractString) = "CL" * last(split(x, '_'; limit=2))
cxname2clname(x::Symbol) = cxname2clname(string(x))

"Remove FirstXX and LastXX from enumerations."
function remove_ranges(pairs)
    filter(pairs) do (sym, val)
        !occursin(r"first|last"i, string(sym))
    end
end

# each CXCursorKind enum gets a specific Julia type wrapping
# so that we can dispatch directly on node kinds.
abstract type CLCursor end

const CXCursorMap = Dict{CXCursorKind,Any}()

for (sym, val) in name_value_pairs(CXCursorKind)
    clsym = Symbol(cxname2clname(sym))
    @eval begin
        struct $clsym <: CLCursor
            cursor::CXCursor
        end
    end
end

for (sym, val) in remove_ranges(name_value_pairs(CXCursorKind))
    clsym = Symbol(cxname2clname(sym))
    @eval CXCursorMap[$sym] = $clsym
end

CLCursor(c::CXCursor) = CXCursorMap[c.kind](c)
Base.convert(::Type{T}, x::CXCursor) where {T<:CLCursor} = CLCursor(x)
Base.cconvert(::Type{CXCursor}, x::CLCursor) = x
Base.unsafe_convert(::Type{CXCursor}, x::CLCursor) = x.cursor

Base.show(io::IO, x::CXCursor) = print(io, "$(kind(x)): $(spelling(x))")
Base.show(io::IO, x::CLCursor) = print(io, "CLCursor (", typeof(x), ") ", name(x))

# each CXTypeKind enum gets a specific Julia type wrapping
# so that we can dispatch directly on node kinds.
abstract type CLType end

const CLTypeMap = Dict{CXTypeKind,Any}()

for (sym, val) in name_value_pairs(CXTypeKind)
    clsym = Symbol(cxname2clname(sym))
    @eval begin
        struct $clsym <: CLType
            type::CXType
        end
    end
end

for (sym, val) in remove_ranges(name_value_pairs(CXTypeKind))
    clsym = Symbol(cxname2clname(sym))
    @eval CLTypeMap[$sym] = $clsym
end

CLType(c::CXType) = CLTypeMap[c.kind](c)
Base.convert(::Type{T}, x::CXType) where {T<:CLType} = CLType(x)
Base.cconvert(::Type{CXType}, x::CLType) = x
Base.unsafe_convert(::Type{CXType}, x::CLType) = x.type

Base.show(io::IO, x::CXType) = print(io, "$(kind(x)): $(spelling(x))")
Base.show(io::IO, x::CLType) = print(io, "CLType (", typeof(x), ") ")

# CLToken
abstract type CLToken end

const CLTokenMap = Dict{CXTokenKind,Any}()

for (sym, val) in name_value_pairs(CXTokenKind)
    clsym = Symbol(last(split(string(sym), '_'; limit=2)))
    @eval begin
        struct $clsym <: CLToken
            token::CXToken
            kind::CXTokenKind
            text::String
        end
        CLTokenMap[$sym] = $clsym
    end
end

for (sym, val) in remove_ranges(name_value_pairs(CXTokenKind))
    clsym = Symbol(last(split(string(sym), '_'; limit=2)))
    @eval CLTokenMap[$sym] = $clsym
end


Base.cconvert(::Type{CXToken}, x::CLToken) = x
Base.unsafe_convert(::Type{CXToken}, x::CLToken) = x.token

Base.show(io::IO, x::CXToken) = print(io, "$(kind(x))")
Base.show(io::IO, x::CLToken) = print(io, typeof(x), "(\"", x.text, "\")")

# CLComment
abstract type CLComment end

const CLCommentMap = Dict()

for (sym, val) in name_value_pairs(CXCommentKind)
    clsym = Symbol(last(split(string(sym), '_'; limit=2)))
    @eval begin
        struct $clsym <: CLComment
            comment::CXComment
        end
    end
end

for (sym, val) in remove_ranges(name_value_pairs(CXCommentKind))
    clsym = Symbol(last(split(string(sym), '_'; limit=2)))
    @eval CLCommentMap[$sym] = $clsym
end

CLComment(c::CXComment) = CLCommentMap[kind(c)](c)
Base.convert(::Type{T}, x::CXComment) where {T<:CLComment} = T(x)
Base.cconvert(::Type{CXComment}, x::CLComment) = x
Base.unsafe_convert(::Type{CXComment}, x::CLComment) = x.comment

Base.show(io::IO, x::CXComment) = print(io, "$(kind(x))")
Base.show(io::IO, x::CLComment) = print(io, "CLComment (", typeof(x), ")")

getTranslationUnit(c::CLComment) = c.TranslationUnit
