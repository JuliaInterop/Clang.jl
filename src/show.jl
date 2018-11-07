# pretty showing
Base.show(io::IO, x::CXCursor) = print(io, "$(kind(x)): $(spelling(x)) $(name(x))")
Base.show(io::IO, x::CXType) = print(io, "$(kind(x)): $(spelling(x))")
Base.show(io::IO, x::CXToken) = print(io, "$(kind(x))")
