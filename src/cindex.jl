"""
    parse_header(header::AbstractString; index=nothing, diagnostics=true, cplusplus=false,
                 args=String[], includes=String[], flags=CXTranslationUnit_None) -> TranslationUnit
Return the TranslationUnit for a given header. This is the main entry point for parsing.

# Arguments
- `header::AbstractString`: the header file to parse.
- `index::Union{Index,Nothing}`: CXIndex pointer (pass to avoid re-allocation).
- `diagnostics::Bool`: display Clang diagnostics.
- `cplusplus::Bool`: parse as C++.
- `args::Vector{String}`: compiler switches as string array, eg: ["-x", "c++", "-fno-elide-type"].
- `includes::Vector{String}`: vector of extra include directories to search.
- `flags::UInt32`: bitwise OR of CXTranslationUnit_Flags.
"""
function parse_header(header::AbstractString; index::Union{Index,Nothing}=nothing, diagnostics::Bool=true,
    cplusplus::Bool=false, args::Vector{String}=String[], includes::Vector{String}=String[], flags::UInt32=CXTranslationUnit_None)
    # TODO: support parsing in-memory with CXUnsavedFile arg
    #       to _parseTranslationUnit.jj
    #unsaved_file = CXUnsavedFile()
    !isfile(header) && throw(ArgumentError(header, " not found"))

    index == nothing && (cidx = CIndex(false, diagnostics);)

    cplusplus && append!(args, ["-x", "c++"])

    !isempty(includes) && foreach(includes) do x
        push!(args, "-I", x)
    end

    return TranslationUnit(cidx, header, args)
end

"""
    search(cursors::Vector{CXCursor}, ismatch::Function)
Return vector of CXCursors that match predicate. `ismatch` is a function that accepts a CXCursor argument.
"""
function search(cursors::Vector{CXCursor}, ismatch::Function)
    matched = CXCursor[]
    for cursor in cursors
        ismatch(cursor) && push!(matched, cursor)
    end
    return matched
end
search(c::CXCursor, s::String) = search(c, x->spelling(x)==s)
search(c::CXCursor, ismatch::Function) = search(children(c), ismatch)
search(c::CXCursor, k::CXCursorKind) = search(c, x->kind(x)==k)
search(tu::TranslationUnit, k::CXCursorKind) = search(getcursor(tu), k)


# TODO implement -- reduce allocations
#=
function cu_children_search(cursor::CXCursor, parent::CXCursor, client_data::Ptr{Cvoid})
    # expect ("target", store::Array{CXCursor,1}, findfirst::Bool)
    target,store,findfirst = unsafe_pointer_to_objref(client_data)
end
=#

function children(cursor::CXCursor)
    # TODO: possible to use sizehint! here?
    list = CXCursor[]
    cu_visitor_cb = @cfunction(cu_children_visitor, Cuint, (CXCursor, CXCursor, Ptr{Cvoid}))
    clang_visitChildren(cursor, cu_visitor_cb, pointer_from_objref(list))
    list
end


## helper functions
"""
    resolve_type(t::CXType) -> CXType
This function attempts to work around some limitations of the current libclang API.
"""
function resolve_type(t::CXType)
    if kind(t) == CXType_Unexposed
        # try to resolve Unexposed type to cursor definition.
        cursor = clang_getTypeDeclaration(t)
        if !isnull(cursor) && kind(cursor) != CXCursor_NoDeclFound
            return type(cursor)
        end
    end
    # otherwise, this will either be a builtin or unexposed client needs to sort out.
    return t
end

"""
    return_type(c::CXCursor, resolve::Bool=true) -> CXtype
Return the return type associated with a function/method cursor.
"""
function return_type(c::CXCursor, resolve::Bool=true)
    t = result_type(c)
    !isvalid(t) && throw(ArgumentError("the cursor does not refer to a function or method."))
    resolve && return resolve_type(t)
    return t
end

"""
    typedef_type(c::CXCursor) -> CXType
Return the underlying type of a typedef declaration.
"""
function typedef_type(c::CXCursor)
    t = clang_getTypedefDeclUnderlyingType(c)
    !isvalid(t) && throw(ArgumentError("the cursor does not reference a typedef declaration."))
    kind(t) == CXType_Unexposed && return type(children(c)[1])
    return t
end

"""
    value(c::CXCursor) -> Union{Clonglong, Culonglong}
Return the integer value of an enum constant declaration.
"""
function value(c::CXCursor)
    typeKind = kind(type(c))
    cursorKind = kind(c)
    cursorKind != CXCursor_EnumConstantDecl && throw(ArgumentError("the cursor does not reference an enum constant declaration."))
    if typeKind == CXType_Int || typeKind == CXType_Long || typeKind == CXType_LongLong
        return clang_getEnumConstantDeclValue(c)
    elseif typeKind == CXType_UInt || typeKind == CXType_ULong || typeKind == CXType_ULongLong
        return clang_getEnumConstantDeclUnsignedValue(c)
    end
    error("Unknown EnumConstantDecl type: ", typeKind, " cursor: ", cursorKind)
end

"""
    function_args(cursor::CXCursor) -> Vector{CXCursor}
Return function arguments for a given cursor.
"""
function_args(cursor::CXCursor) = search(cursor, CXCursor_ParmDecl)

# #returns a tuple with the default argument values for a C++ function
# #only seems to work if cplusplus=true in parse_header
# function function_arg_defaults(method::Union{cindex.CXXMethod, cindex.FunctionDecl, cindex.Constructor})
#     defvals = Any[]
#     for c in children(method)
#         if kind(c) == CXCursor_ParmDecl
#
#             #value in case default was not specified
#             lit = nothing
#             toks = tokenize(c)
#
#             n = 1
#             #get index of '='
#             for tok in toks
#                 if isa(tok, cindex.Punctuation) && tok.text == "="
#                     break
#                 end
#                 n += 1
#             end
#
#             ts = collect(toks)
#
#             #default value is the one after '='
#             if n<length(toks)
#                 lit = join(map(x->x.text, ts[n+1:end]), "")
#             end
#
#             #parse default value as Julia code
#             pl = if (lit != nothing)
#                     try
#                         Meta.parse(lit)
#                     catch err
#                         @info "Error parsing function_default_arg value: $lit"
#                         return tuple(Any[])
#                     end
#                  else
#                      lit
#                  end
#
#             #for empty string, need to add quotes
#             if pl == ""
#                 pl = "\"\""
#             end
#             push!(defvals, pl)
#         end
#     end
#     return tuple(defvals...)
# end
#
# #returns an array of the function return type modifiers
# function function_return_modifiers(f::Union{FunctionDecl, CXXMethod})
#     modifs = Any[]
#     for tok in tokenize(f)
#         if isa(tok, cindex.Keyword)
#             if tok.text in ["const"]
#                 push!(modifs, tok)
#             end
#         end
#         isa(tok, cindex.Identifier) && tok.text==spelling(f) && break
#     end
#     return modifs
# end
#
# function function_arg_modifiers(p::ParmDecl)
#     modifs = cindex.Keyword[]
#     for tok in tokenize(p)
#
#         #only read keywords
#         isa(tok, cindex.Keyword) || continue
#
#         #read up to variable identifier
#         isa(tok, cindex.Identifier) && break
#
#         if tok.text in ["const", "virtual"]
#             push!(modifs, tok)
#         end
#     end
#     return modifs
# end
