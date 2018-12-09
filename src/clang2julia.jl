"""
Mapping from libclang types to Julia types
"""
const CLANG_JULIA_TYPEMAP = Dict(
    CXType_Void             => :Cvoid,
    CXType_Bool             => :Bool,
    CXType_Char_U           => :UInt8,
    CXType_UChar            => :Cuchar,
    CXType_Char16           => :UInt16,
    CXType_Char32           => :UInt32,
    CXType_UShort           => :UInt16,
    CXType_UInt             => :UInt32,
    CXType_ULong            => :Culong,
    CXType_ULongLong        => :Culonglong,
    CXType_UInt128          => :UInt128,
    CXType_Char_S           => :UInt8,
    CXType_SChar            => :UInt8,
    CXType_WChar            => :Char,
    CXType_Short            => :Int16,
    CXType_Int              => :Cint,
    CXType_Long             => :Clong,
    CXType_LongLong         => :Clonglong,
    CXType_Int128           => :Int128,
    CXType_Float            => :Cfloat,
    CXType_Double           => :Cdouble,
    CXType_LongDouble       => :Float64,
    CXType_NullPtr          => :C_NULL,
    # CXType_Float128         => ?
    # CXType_Half             => ?
    # CXType_Float16          => :Float16
    CXType_Complex          => :Complex,
    CXType_Pointer          => :Cvoid,
    CXType_BlockPointer     => :Cvoid,
    CXType_Elaborated       => :Cvoid,
    CXType_Invalid          => :Cvoid,
    :size_t                 => :Csize_t,
    :ptrdiff_t              => :Cptrdiff_t,
    :uint64_t               => :UInt64,
    :uint32_t               => :UInt32,
    :uint16_t               => :UInt16,
    :uint8_t                => :UInt8,
    :int64_t                => :Int64,
    :int32_t                => :Int32,
    :int16_t                => :Int16,
    :int8_t                 => :Int8,
    :uintptr_t              => :Csize_t,
    :tm                     => :Ctm,
    :time_t                 => :Ctime_t,
    :clock_t                 => :Cclock_t,
    )

const INT_CONVERSION = Dict(
    :Cint   => Int32,
    :Cuint  => UInt32,
    :UInt64 => UInt64,
    :UInt32 => UInt32,
    :UInt16 => UInt16,
    :UInt8  => UInt8,
    :Int64  => Int64,
    :Int32  => Int32,
    :Int16  => Int16,
    :Int8   => Int8,
    )


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
    clang2julia(c::CLCursor) -> Symbol/Expr
Convert libclang cursor/type to Julia.
"""
clang2julia(c::CLCursor) = clang2julia(type(c))
clang2julia(c::CLUnionDecl) = type(c) |> largestfield |> clang2julia
clang2julia(c::CLEnumDecl) = integer_type(c) |> clang2julia

function clang2julia(c::CLTypeRef)
    reftype = getref(c)
    refdef = getdef(reftype)
    refdefKind = kind(refdef)
    if isnull(refdef) || refdefKind == CXCursor_InvalidFile || refdefKind == CXCursor_FirstInvalid
        return :Cvoid
    else
        return Symbol(spelling(reftype))
    end
end
