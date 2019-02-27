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
    :clock_t                => :Cclock_t,
    :wchar_t                => :Cwchar_t,
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
    typesize(t::CLType) -> Int
    typesize(c::CLCursor) -> Int
Return field declaration size.
"""
typesize(t::CLType) = clang_Type_getSizeOf(t)
typesize(t::CLTypedef) = typesize(typedecl(t))
typesize(t::CLElaborated) = typesize(get_named_type(t))
typesize(t::CLConstantArray) = element_num(t)
typesize(t::CLInvalid) = (@warn("  incorrect typesize for CXType_Invalid field"); 0)
typesize(c::CLTypedefDecl) = typesize(underlying_type(c))

"""
    clang2julia(t::CLType) -> Symbol/Expr
Convert libclang cursor/type to Julia.
"""
function clang2julia(t::CLType)
    type_kind = kind(t)
    !haskey(CLANG_JULIA_TYPEMAP, type_kind) && error("No CXType translation available for: $type_kind")
    return CLANG_JULIA_TYPEMAP[type_kind]
end

# get the original named type if the type is CXType_Elaborated
clang2julia(t::CLElaborated) = clang2julia(get_named_type(t))

# CXType_Enum types are mapped into Cenums, so we only need to extract enum's names.
clang2julia(t::CLEnum) = spelling(t) |> split |> last |> Symbol

function clang2julia(t::Union{CLRecord,CLTypedef})
    cursor_name = spelling(typedecl(t))
    type_name = isempty(cursor_name) ? spelling(t) : cursor_name  # handle anonymous typedef records
    type_sym = Symbol(type_name)
    return get(CLANG_JULIA_TYPEMAP, type_sym, type_sym)
end

"""
    clang2julia(t::CLPointer)
Pointers are translated to `Ptr`s.
"""
function clang2julia(t::CLPointer)
    ptree = pointee_type(t)
    ptree_kind = kind(ptree)
    (ptree_kind == CXType_Char_U || ptree_kind == CXType_Char_S) && return :Cstring
    ptree_kind == CXType_WChar && return :Cwstring
    Expr(:curly, :Ptr, clang2julia(ptree))
end

"""
    clang2julia(t::CLUnexposed)
Unexposed Clang types are translated to the symbol of its cursor name(if exist).
"""
function clang2julia(t::CLUnexposed)
    cursor_name = spelling(typedecl(t))
    isempty(cursor_name) ? :Cvoid : Symbol(cursor_name)
end

"""
    clang2julia(t::CLConstantArray)
`ConstantArray`s are translated to `NTuple`s.
"""
function clang2julia(t::CLConstantArray)
    arrsize = element_num(t)
    eltype = clang2julia(element_type(t))
    return :(NTuple{$arrsize, $eltype})
end

"""
    clang2julia(t::CLIncompleteArray)
`IncompleteArray`s are translated to pointers, so one need to deal with the byte offsets directly.
"""
clang2julia(t::CLIncompleteArray) = Expr(:curly, :Ptr, clang2julia(element_type(t)))

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
