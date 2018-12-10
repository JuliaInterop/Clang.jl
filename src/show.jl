# pretty showing
Base.show(io::IO, x::CXCursor) = print(io, "$(kind(x)): $(spelling(x))")
Base.show(io::IO, x::CXType) = print(io, "$(kind(x)): $(spelling(x))")
Base.show(io::IO, x::CXToken) = print(io, "$(kind(x))")

Base.show(io::IO, x::CLToken)  = print(io, typeof(x), "(\"", x.text, "\")")
Base.show(io::IO, x::CLType)   = print(io, "CLType (", typeof(x), ") ")
Base.show(io::IO, x::CLCursor) = print(io, "CLCursor (", typeof(x), ") ", name(x))
