"""
    name_safe(name::AbstractString)
Return a valid Julia variable name, prefixed with "_" if the `name` is conflict with Julia's
reserved words.
"""
name_safe(name::AbstractString) = (name in RESERVED_WORDS) ? "_"*name : name

"""
    symbol_safe(name::AbstractString)
Same as [`name_safe`](@ref), but return a Symbol.
"""
symbol_safe(name::AbstractString) = Symbol(name_safe(name))
