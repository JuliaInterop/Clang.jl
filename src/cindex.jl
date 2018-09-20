module cindex

export parse_header, cu_type, ty_kind, name, spelling,
       value, children, cu_file, resolve_type, return_type,
       tokenize, pointee_type, typedef_type
export CLType, CLCursor, CXString, CXTypeKind, CursorList, TokenList

import Base.search
export search

export function_return_modifiers, function_arg_modifiers, cu_visitor_cb

import ..libclang

###############################################################################

include("cindex/defs.jl")
include("cindex/types.jl")
include("cindex/base.jl")

###############################################################################

# Main entry point for parsing
# Returns root CXCursor in the TranslationUnit for a given header
#
# Required argument:
#   "header.h"          header file to parse
#
# Optional (keyword) arguments:
#   index:              CXIndex pointer (pass to avoid re-allocation)
#   diagnostics:        Display Clang diagnostics
#   cplusplus:          Parse as C++
#   includes:           Vector of extra include directories to search
#   args:               Compiler switches as string array, eg: ["-x", "c++", "-fno-elide-type"]
#   flags:              Bitwise OR of TranslationUnitFlags
#
function parse_header(header::AbstractString;
                index                           = Union{},
                diagnostics::Bool               = true,
                cplusplus::Bool                 = false,
                args                            = [""],
                includes                        = String[],
                flags                           = TranslationUnit_Flags.None)
    if !isfile(header)
        error(header, " not found")

        # TODO: support parsing in-memory with CXUnsavedFile arg
        #       to _parseTranslationUnit.jj
        #unsaved_file = CXUnsavedFile()
    end
    if (index == Union{})
        index = idx_create(0, (diagnostics ? 1 : 0))
    end
    if (cplusplus)
        append!(args, ["-x", "c++"])
    end
    if (length(includes) > 0)
        args = vcat(args, [["-I",x] for x in includes]...)
    end

    tu = tu_parse(index, header, args, length(args),
                  C_NULL, 0, flags)
    if (tu == C_NULL)
        error("ParseTranslationUnit returned NULL; unable to create TranslationUnit for header $(header)")
    end

    return tu_cursor(tu)
end

###############################################################################
# Search function for CursorList
# Returns vector of CXCursors in CursorList matching predicate
#
# Required arguments:
#   CursorList      List to search
#   IsMatch(CXCursor)
#                   Predicate Function, accepting a CXCursor argument
#
function search(cl::Vector{CLCursor}, ismatch::Function)
    ret = CLCursor[]
    for cu in cl
        ismatch(cu) && push!(ret, cu)
    end
    ret
end
search(cu::CLCursor, ismatch::Function) = search(children(cu), ismatch)
search(cu::CLCursor, T::DataType) = search(cu, x->isa(x, T))
search(cu::CLCursor, name::String) = search(cu, x->(cindex.spelling(x) == name))

###############################################################################
# Extended search function
# Returns a Dict{ DataType => CLCursor

function matchchildren(cu::CLCursor, types::Array{DataType,1})
    ret = Dict{Any,Any}([(t, CLCursor[]) for t in types])
    for child in children(cu)
        for t in types
            isa(child, t) && push!(ret[t], child)
        end
    end
    return ret
end

###############################################################################

# TODO: macro version should be more efficient.
anymatch(first, args...) = any([==(first, a) for a in args])

cu_type(c::CLCursor) = getCursorType(c)
ty_kind(c::CLType) = convert(Int, c.typ.kind)
name(c::CLCursor) = getCursorDisplayName(c)
spelling(c::CLType) = getTypeKindSpelling(convert(Int32, ty_kind(c)))
spelling(c::CLCursor) = getCursorSpelling(c)
is_null(c::CLCursor) = (Cursor_isNull(c) != 0)

function resolve_type(rt::CLType)
    # This helper attempts to work around some limitations of the
    # current libclang API.
    if ty_kind(rt) == cindex.TypeKind.Unexposed
        # try to resolve Unexposed type to cursor definition.
        rtdef_cu = cindex.getTypeDeclaration(rt)
        if (!is_null(rtdef_cu) && !isa(rtdef_cu, NoDeclFound))
            return cu_type(rtdef_cu)
        end
    end
    # otherwise, this will either be a builtin or unexposed
    # client needs to sort out.
    return rt
end

function return_type(c::Union{FunctionDecl, CXXMethod}, resolve::Bool)
    if (resolve)
        return resolve_type( getCursorResultType(c) )
    else
        return getCursorResultType(c)
    end
end
return_type(c::CLCursor) = return_type(c, true)

function pointee_type(t::Pointer)
    return cindex.getPointeeType(t)
end
pointee_type(cu::CLCursor) = error("pointee_type(CLCursor) is discontinued, please use pointee_type(cindex.cu_type(cu))")

function typedef_type(c::TypedefDecl)
    t = cindex.getTypedefDeclUnderlyingType(c)
    if isa(t, Unexposed)
        t = cu_type(children(c)[1])
    end
    return t
end

function value(c::EnumConstantDecl)
    t = cu_type(c)
    if isa(t, IntType) || isa(t, Long) || isa(t, LongLong)
            return getEnumConstantDeclValue(c)
    elseif isa(t, UInt) || isa(t, ULong) || isa(t, ULongLong)
            return getEnumConstantDeclUnsignedValue(c)
    end
    error("Unknown EnumConstantDecl type: ", t, " cursor: ", c)
end

function cu_children_visitor(cursor::CXCursor, parent::CXCursor, client_data::Ptr{Cvoid})
    list = unsafe_pointer_to_objref(client_data)
    push!(list, cursor)
    return Cuint(1) # CXChildVisit_Continue TODO: use enum
end

# TODO implement -- reduce allocations
#=
function cu_children_search(cursor::CXCursor, parent::CXCursor, client_data::Ptr{Cvoid})
    # expect ("target", store::Array{CXCursor,1}, findfirst::Bool)
    target,store,findfirst = unsafe_pointer_to_objref(client_data)
end
=#

function children(cu::CLCursor)
    # TODO: possible to use sizehint! here?
    list = CLCursor[]
    ccall( (:clang_visitChildren, libclang), Nothing,
           (CXCursor, Ptr{Cvoid}, Ptr{Cvoid}),
           cu, cu_visitor_cb, pointer_from_objref(list))
    list
end

# TODO add cu_location
function cu_file(cu::CLCursor)
    # TODO should return a struct or namedtuple
    # TODO turn this in to a normal wrapper
    loc = ccall( (:clang_getCursorLocation, libclang), CXSourceLocation,
                 (CXCursor,), cu)

    cxfile = Ref{CXFile}()
    line = Ref{Cuint}(); col = Ref{Cuint}(); offset = Ref{Cuint}()

    ccall( (:clang_getExpansionLocation, libclang), (Nothing),
            (CXSourceLocation, Ref{CXFile}, Ref{Cuint}, Ref{Cuint}, Ref{Cuint}),
            loc,               cxfile,       line,       col,        offset)

    getFileName(cxfile[])
end

################################################################################
# Tokenizer access
################################################################################

# Returns TokenList
function tokenize(cursor::CLCursor)
    tu = Cursor_getTranslationUnit(cursor)
    sourcerange = getCursorExtent(cursor)
    return cindex.tokenize(tu, sourcerange)
end

Base.firstindex(tl::TokenList) = 1
Base.lastindex(tl::TokenList) = length(tl)
Base.length(tl::TokenList) = tl.size
Base.iterate(tl::TokenList, state=1) = state > tl.size ? nothing : (tl[state], state+1)

function Base.getindex(tl::TokenList, i::Int)
    if (i < 1 || i > length(tl))
        # throw(BoundsError())
        @warn "TokenList miss at index ", i
        return Comment(string("TokenList miss at index ", i))
    end

    c = unsafe_load(tl.ptr, i)
    kind = c.int_data[1]
    spelling = cindex.getTokenSpelling(tl.tunit, c)

    if (kind == TokenKind.Punctuation)
        return Punctuation(spelling)
    elseif (kind == TokenKind.Keyword)
        return Keyword(spelling)
    elseif (kind == TokenKind.Identifier)
        return Identifier(spelling)
    elseif (kind == TokenKind.Literal)
        return Literal(spelling)
    elseif (kind == TokenKind.Comment)
        return Comment(spelling)
    end
    throw("Unknown TokenKind: $kind")
end

################################################################################
# Helper functions
################################################################################

# Retrieve function arguments for a given cursor
function function_args(cursor::Union{FunctionDecl, CXXMethod})
    search(cursor, ParmDecl)
end


#returns a tuple with the default argument values for a C++ function
#only seems to work if cplusplus=true in parse_header
function function_arg_defaults(method::Union{cindex.CXXMethod, cindex.FunctionDecl, cindex.Constructor})
    defvals = Any[]
    for c in children(method)
        if isa(c,cindex.ParmDecl)

            #value in case default was not specified
            lit = nothing
            toks = tokenize(c)

            n = 1
            #get index of '='
            for tok in toks
                if isa(tok, cindex.Punctuation) && tok.text == "="
                    break
                end
                n += 1
            end

            ts = collect(toks)

            #default value is the one after '='
            if n<length(toks)
                lit = join(map(x->x.text, ts[n+1:end]), "")
            end

            #parse default value as Julia code
            pl = if (lit != nothing)
                    try
                        Meta.parse(lit)
                    catch err
                        @info "Error parsing function_default_arg value: $lit"
                        return tuple(Any[])
                    end
                 else
                     lit
                 end

            #for empty string, need to add quotes
            if pl == ""
                pl = "\"\""
            end
            push!(defvals, pl)
        end
    end
    return tuple(defvals...)
end

#returns an array of the function return type modifiers
function function_return_modifiers(f::Union{FunctionDecl, CXXMethod})
    modifs = Any[]
    for tok in tokenize(f)
        if isa(tok, cindex.Keyword)
            if tok.text in ["const"]
                push!(modifs, tok)
            end
        end
        isa(tok, cindex.Identifier) && tok.text==spelling(f) && break
    end
    return modifs
end

function function_arg_modifiers(p::ParmDecl)
    modifs = cindex.Keyword[]
    for tok in tokenize(p)

        #only read keywords
        isa(tok, cindex.Keyword) || continue

        #read up to variable identifier
        isa(tok, cindex.Identifier) && break

        if tok.text in ["const", "virtual"]
            push!(modifs, tok)
        end
    end
    return modifs
end

################################################################################
# Display overrides
################################################################################

Base.show(io::IO, tk::CLToken)  = print(io, typeof(tk), "(\"", tk.text, "\")")
Base.show(io::IO, ty::CLType)   = print(io, "CLType (", typeof(ty), ") ")
Base.show(io::IO, cu::CLCursor) = print(io, "CLCursor (", typeof(cu), ") ", name(cu))

###############################################################################
# Internal functions
###############################################################################

tu_init(hdrfile::Any) = tu_init(hdrfile, 0, false, 0)
function tu_init(hdrfile::Any, diagnostics, cpp::Bool, opts::Int)
    idx = idx_create(0,diagnostics)
    tu = tu_parse(idx, hdrfile, (cpp ? ["-x", "c++"] : [""]), opts)
    return tu
end


function tu_dispose(tu::CXTranslationUnit)
    ccall( (:clang_disposeTranslationUnit, libclang), Nothing, (Ptr{Nothing},), tu)
end

function tu_cursor(tu::CXTranslationUnit)
    if (tu == C_NULL)
        error("Invalid TranslationUnit!")
    end
    getTranslationUnitCursor(tu)
end

function tu_parse(CXIndex,
                  source_filename::AbstractString,
                  cl_args::Array{S,1},
                  num_clargs,
                  unsaved_files::CXUnsavedFile,
                  num_unsaved_files,
                  options) where S <: String

    ccall(  (:clang_parseTranslationUnit, libclang),
            CXTranslationUnit,
            (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Ptr{UInt8}}, UInt32, Ptr{Cvoid}, UInt32, UInt32),
                CXIndex,
                source_filename,
                cl_args,
                num_clargs,
                unsaved_files,
                num_unsaved_files,
                options)
end

function idx_create(excludeDeclsFromPCH::Int, displayDiagnostics::Int)
    ccall(  (:clang_createIndex, libclang),
            CXTranslationUnit,
            (Int32, Int32),
                excludeDeclsFromPCH,
                displayDiagnostics)
end
idx_create() = idx_create(0,0)

function getFile(tu::CXTranslationUnit, file::String)
    ccall( (:clang_getFile, libclang),
            CXFile,
            (Ptr{Cvoid}, Ptr{UInt8}),
                tu,
                file)
end

function __init__()
    global cu_visitor_cb = @cfunction(cu_children_visitor, Cuint, (CXCursor, CXCursor, Ptr{Cvoid}))
end

end # module
