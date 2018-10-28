target_type(s::Symbol) = s
function target_type(e::Expr)
    if e.head == :curly && e.args[1] == :Ptr
        return target_type(e.args[2])
    elseif  e.head == :curly && e.args[1] == :NTuple
        return target_type(e.args[3])
    else
        error("target_type: don't know how to handle $e")
    end
end
target_type(q) = error("target_type: don't know how to handle $q")


"""
    typesize(t::CXType) -> Int
    typesize(c::CXCursor) -> Int
Return field declaration size.
"""
typesize(t::CXType) = _typesize(Val(kind(t)), t)
_typesize(::Val, t::CXType) = sizeof(getfield(Base, CLANG_JULIA_TYPEMAP[kind(t)]))
_typesize(::Val{CXType_ConstantArray}, t::CXType) = element_num(t)
_typesize(::Val{CXType_Typedef}, t::CXType) = typesize(typedecl(t))
_typesize(::Val{CXType_Record}, t::CXType) = (@warn("  incorrect typesize for CXType_Record field"); 0)
_typesize(::Val{CXType_Unexposed}, t::CXType) = (@warn("  incorrect typesize for CXType_Unexposed field"); 0)
_typesize(::Val{CXType_Invalid}, t::CXType) = (@warn("  incorrect typesize for CXType_Invalid field"); 0)

typesize(c::CXCursor) = _typesize(Val(kind(c)), c)
_typesize(::Val{CXCursor_TypedefDecl}, c::CXCursor) = typesize(underlying_type(c))


"""
Used for hacky union inclusion: we find the largest union field and declare a block of
bytes to match.
"""
function largestfield(c::CXCursor)
    maxsize, maxelem = 0, 0
    fields = children(c)
    for i in 1:length(fields)
        field_size = typesize(type(fields[i]))
        if field_size > maxsize
            maxsize = field_size
            maxelem = i
        end
    end
    fields[maxelem]
end


"""
    clang2julia(t::CXType) -> Symbol/Expr
Convert libclang cursor/type to Julia.
"""
clang2julia(t::CXType) = _clang2julia(Val(kind(t)), t)

# generic subroutine for CXType input
function _clang2julia(::Val, t::CXType)
    typeKind = kind(t)
    !haskey(CLANG_JULIA_TYPEMAP, typeKind) && error("No CXType translation available for: $typeKind")
    return CLANG_JULIA_TYPEMAP[typeKind]
end

# get the original named type if the type is CXType_Elaborated
_clang2julia(::Val{CXType_Elaborated}, t::CXType) = clang2julia(get_named_type(t))

# CXType_Enum types are mapped into Cenums, so we only need to extract enum's names.
_clang2julia(::Val{CXType_Enum}, t::CXType) = spelling(t) |> split |> last |> Symbol

function _clang2julia(::Union{Val{CXType_Record},Val{CXType_Typedef}}, t::CXType)
    cursorName = spelling(typedecl(t))
    typeName = isempty(cursorName) ? spelling(t) : cursorName  # handle anonymous typedef records
    typeSym = Symbol(typeName)
    return get(CLANG_JULIA_TYPEMAP, typeSym, typeSym)
end

function _clang2julia(::Val{CXType_Pointer}, t::CXType)
    ptee = pointee_type(t)
    pteeKind = kind(ptee)
    (pteeKind == CXType_Char_U || pteeKind == CXType_Char_S) && return :Cstring
    pteeKind == CXType_WChar && return :Cwstring
    Expr(:curly, :Ptr, clang2julia(ptee))
end

function _clang2julia(::Val{CXType_Unexposed}, t::CXType)
    r = spelling(typedecl(t))
    r == "" ? :Cvoid : Symbol(r)
end

function _clang2julia(::Val{CXType_ConstantArray}, t::CXType)
    # For ConstantArray declarations, we use NTuples
    arrsize = element_num(t)
    eltype = clang2julia(element_type(t))
    return :(NTuple{$arrsize, $eltype})
end

function _clang2julia(::Val{CXType_IncompleteArray}, t::CXType)
    eltype = clang2julia(element_type(t))
    Expr(:curly, :Ptr, eltype)
end

"""
    clang2julia(c::Cursor) -> Symbol/Expr
Convert libclang cursor/type to Julia.
"""
clang2julia(c::CXCursor) = _clang2julia(Val(kind(c)), c)

# generic subroutine for CXType input
_clang2julia(::Val, c::CXCursor) = clang2julia(type(c))

_clang2julia(::Val{CXCursor_UnionDecl}, c::CXCursor) = type(c) |> largestfield |> clang2julia

_clang2julia(::Val{CXCursor_EnumDecl}, c::CXCursor) = integer_type(c) |> clang2julia

function _clang2julia(::Val{CXCursor_TypeRef}, c::CXCursor)
    reftype = getref(c)
    refdef = getdef(reftype)
    refdefKind = kind(refdef)
    if isnull(refdef) || refdefKind == CXCursor_InvalidFile || refdefKind == CXCursor_FirstInvalid
        return :Cvoid
    else
        return Symbol(spelling(reftype))
    end
end

# function _clang2julia(::Val{CXCursor_TypedefDecl}, c::CXCursor)
#     underlying = underlying_type(c) |> canonical
#     if isempty(spelling(typedecl(underlying)))
#         # handle anonymous typedef
#         if kind(underlying) == CXType_Pointer
#             ptee = pointee_type(t)
#             pteeKind = kind(ptee)
#             (pteeKind == CXType_Char_U || pteeKind == CXType_Char_S) && return :Cstring
#             pteeKind == CXType_WChar && return :Cwstring
#             Expr(:curly, :Ptr, clang2julia(ptee))
#     else
#         return clang2julia(type(c))
#     end
# end
