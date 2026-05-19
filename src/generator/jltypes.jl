"""
    AbstractJuliaType
"""
abstract type AbstractJuliaType end

struct JuliaUnknown{T<:CLType} <: AbstractJuliaType
    x::T
end

struct JuliaUnsupported <: AbstractJuliaType end

struct JuliaCpointer <: AbstractJuliaType
    ref::CLPointer
end

struct JuliaObjCObjectPointer <: AbstractJuliaType
    ref::CLObjCObjectPointer
end
struct JuliaObjCId{T<:Union{CLCursor}} <: AbstractJuliaType
    sym::Symbol
    ref::T
end
JuliaObjCId() = JuliaObjCId(Symbol(), CLCursor(getNullCursor()))
JuliaObjCId(x::AbstractString) = JuliaObjCId(Symbol(x), CLCursor(getNullCursor()))
struct JuliaObjCClass{T<:Union{CLCursor}} <: AbstractJuliaType
    sym::Symbol
    ref::T
end
JuliaObjCClass() = JuliaObjCClass(Symbol(), CLCursor(getNullCursor()))
JuliaObjCClass(x::AbstractString) = JuliaObjCClass(Symbol(x), CLCursor(getNullCursor()))

struct JuliaCconstarray <: AbstractJuliaType
    ref::CLConstantArray
end
struct JuliaCincompletearray <: AbstractJuliaType
    ref::CLIncompleteArray
end
struct JuliaCvariablearray <: AbstractJuliaType
    ref::CLVariableArray
end

struct JuliaCrecord{T<:CLCursor} <: AbstractJuliaType
    sym::Symbol
    cursor::T
end
JuliaCrecord() = JuliaCrecord(Symbol(), CLCursor(getNullCursor()))
JuliaCrecord(x::AbstractString) = JuliaCrecord(Symbol(x), CLCursor(getNullCursor()))

struct JuliaCenum{T<:CLCursor} <: AbstractJuliaType
    sym::Symbol
    cursor::T
end
JuliaCenum() = JuliaCenum(Symbol(), CLCursor(getNullCursor()))
JuliaCenum(x::AbstractString) = JuliaCenum(Symbol(x), CLCursor(getNullCursor()))

struct JuliaCtypedef <: AbstractJuliaType
    sym::Symbol
end
JuliaCtypedef() = JuliaCtypedef(Symbol())
JuliaCtypedef(x::AbstractString) = JuliaCtypedef(Symbol(x))

struct JuliaCfunction <: AbstractJuliaType
    sym::Symbol
end
JuliaCfunction() = JuliaCfunction(Symbol())
JuliaCfunction(x::AbstractString) = JuliaCfunction(Symbol(x))

"""
    System Independent Types
"""
abstract type AbstractJuliaSIT <: AbstractJuliaType end

struct JuliaCbool <: AbstractJuliaSIT end
struct JuliaCuchar <: AbstractJuliaSIT end
struct JuliaCshort <: AbstractJuliaSIT end
struct JuliaCushort <: AbstractJuliaSIT end
struct JuliaCint <: AbstractJuliaSIT end
struct JuliaCuint <: AbstractJuliaSIT end
struct JuliaClonglong <: AbstractJuliaSIT end
struct JuliaCulonglong <: AbstractJuliaSIT end
struct JuliaCintmax_t <: AbstractJuliaSIT end
struct JuliaCuintmax_t <: AbstractJuliaSIT end
struct JuliaCfloat <: AbstractJuliaSIT end
struct JuliaCdouble <: AbstractJuliaSIT end
struct JuliaComplexF32 <: AbstractJuliaSIT end
struct JuliaComplexF64 <: AbstractJuliaSIT end
struct JuliaCptrdiff_t <: AbstractJuliaSIT end
struct JuliaCssize_t <: AbstractJuliaSIT end
struct JuliaCsize_t <: AbstractJuliaSIT end
struct JuliaCvoid <: AbstractJuliaSIT end
struct JuliaNoReturn <: AbstractJuliaSIT end
struct JuliaPtrCvoid <: AbstractJuliaSIT end
struct JuliaCstring <: AbstractJuliaSIT end
struct JuliaPtrUInt8 <: AbstractJuliaSIT end
struct JuliaPtrPtrUInt8 <: AbstractJuliaSIT end
struct JuliaAny <: AbstractJuliaSIT end
struct JuliaRefAny <: AbstractJuliaSIT end

struct JuliaCuint128 <: AbstractJuliaSIT end
struct JuliaCint128 <: AbstractJuliaSIT end
struct JuliaCschar <: AbstractJuliaSIT end
struct JuliaClongdouble <: AbstractJuliaSIT end
struct JuliaComplex <: AbstractJuliaSIT end
struct JuliaChalf <: AbstractJuliaSIT end
struct JuliaCfloat16 <: AbstractJuliaSIT end
struct JuliaCfloat128 <: AbstractJuliaSIT end

struct JuliaCuint64_t <: AbstractJuliaSIT end
struct JuliaCuint32_t <: AbstractJuliaSIT end
struct JuliaCuint16_t <: AbstractJuliaSIT end
struct JuliaCuint8_t <: AbstractJuliaSIT end
struct JuliaCint64_t <: AbstractJuliaSIT end
struct JuliaCint32_t <: AbstractJuliaSIT end
struct JuliaCint16_t <: AbstractJuliaSIT end
struct JuliaCint8_t <: AbstractJuliaSIT end

struct JuliaCuintptr_t <: AbstractJuliaSIT end  # Csize_t
struct JuliaCintptr_t <: AbstractJuliaSIT end  # Cptrdiff_t
struct JuliaCtm <: AbstractJuliaSIT end  # Libc.TmStruct
struct JuliaCFILE <: AbstractJuliaSIT end  # Libc.FILE

"""
    System Dependent Types
"""
abstract type AbstractJuliaSDT <: AbstractJuliaType end

struct JuliaCchar <: AbstractJuliaSDT end
struct JuliaClong <: AbstractJuliaSDT end
struct JuliaCulong <: AbstractJuliaSDT end
struct JuliaCwchar_t <: AbstractJuliaSDT end

"""
    tojulia
Map a `CLType` type to a `AbstractJuliaType` type.
"""
function tojulia end

tojulia(x::CLType) = JuliaUnknown(x)
tojulia(x::CLVoid) = JuliaCvoid()
tojulia(x::CLBool) = JuliaCbool()
tojulia(x::CLChar_U) = JuliaCchar()
tojulia(x::CLUChar) = JuliaCuchar()
tojulia(x::CLChar16) = JuliaUnknown(x)  # C++11 char16_t
tojulia(x::CLChar32) = JuliaUnknown(x)  # C++11 char32_t
tojulia(x::CLUShort) = JuliaCushort()
tojulia(x::CLUInt) = JuliaCuint()
tojulia(x::CLULong) = JuliaCulong()
tojulia(x::CLULongLong) = JuliaCulonglong()
tojulia(x::CLUInt128) = JuliaCuint128()
tojulia(x::CLChar_S) = JuliaCchar()
tojulia(x::CLSChar) = JuliaCschar()  # Int8
tojulia(x::CLWChar) = JuliaCwchar_t()
tojulia(x::CLShort) = JuliaCshort()
tojulia(x::CLInt) = JuliaCint()
tojulia(x::CLLong) = JuliaClong()
tojulia(x::CLLongLong) = JuliaClonglong()
tojulia(x::CLInt128) = JuliaCint128()
tojulia(x::CLFloat) = JuliaCfloat()
tojulia(x::CLDouble) = JuliaCdouble()
tojulia(x::CLLongDouble) = JuliaClongdouble()  # depends on compiler
tojulia(x::CLComplex) = JuliaComplex()  # ComplexF32 or ComplexF64
tojulia(x::CLHalf) = JuliaChalf()  # Float16
tojulia(x::CLFloat16) = JuliaCfloat16()  # Float16
tojulia(x::CLFloat128) = JuliaCfloat128() # see Quadmath.jl
tojulia(x::CLNullPtr) = JuliaUnknown(x)  # C++11 nullptr
tojulia(x::CLPointer) = JuliaCpointer(x)
tojulia(x::CLObjCObjectPointer) = JuliaObjCObjectPointer(x)
function tojulia(x::CLObjCId)
    c = getTypeDeclaration(x)
    JuliaObjCId(Symbol(spelling(c)), c)
end
function tojulia(x::CLObjCClass)
    c = getTypeDeclaration(x)
    JuliaObjCClass(Symbol(spelling(c)), c)
end
tojulia(x::CLBlockPointer) = JuliaUnknown(x)  # ObjectveC's block pointer
tojulia(x::CLElaborated) = tojulia(getNamedType(x))
tojulia(x::CLInvalid) = JuliaUnknown(x)
tojulia(x::CLFunctionProto) = JuliaCfunction(spelling(getTypeDeclaration(x)))
tojulia(x::CLFunctionNoProto) = JuliaCfunction(spelling(getTypeDeclaration(x)))
function tojulia(x::CLEnum)
    c = getTypeDeclaration(x)
    JuliaCenum(Symbol(spelling(c)), c)
end
function tojulia(x::CLRecord)
    c = getTypeDeclaration(x)
    JuliaCrecord(Symbol(spelling(c)), c)
end
tojulia(x::CLTypedef) = JuliaCtypedef(spelling(getTypeDeclaration(x)))
tojulia(x::CLUnexposed) = JuliaUnknown(x)
tojulia(x::CLConstantArray) = JuliaCconstarray(x)
tojulia(x::CLIncompleteArray) = JuliaCincompletearray(x)
tojulia(x::CLVariableArray) = JuliaCvariablearray(x)

# helper functions
is_jl_basic(x::AbstractJuliaType) = false
is_jl_basic(x::AbstractJuliaSIT) = true
is_jl_basic(x::AbstractJuliaSDT) = true

is_jl_unknown(x::AbstractJuliaType) = false
is_jl_unknown(x::JuliaUnknown) = true

is_jl_unsupported(x::AbstractJuliaType) = false
is_jl_unsupported(x::JuliaUnsupported) = true

is_jl_char(x::AbstractJuliaType) = false
is_jl_char(x::JuliaCchar) = true

is_jl_wchar(x::AbstractJuliaType) = false
is_jl_wchar(x::JuliaCwchar_t) = true

is_jl_pointer(x::AbstractJuliaType) = false
is_jl_pointer(x::JuliaCpointer) = true
is_jl_pointer(_::JuliaObjCId) = true
is_jl_pointer(_::JuliaObjCObjectPointer) = true

is_jl_array(x::AbstractJuliaType) = false
is_jl_array(x::JuliaCconstarray) = true
is_jl_array(x::JuliaCincompletearray) = true
is_jl_array(x::JuliaCvariablearray) = true

is_jl_funcptr(x::AbstractJuliaType) = false
is_jl_funcptr(x::CLPointer) = Clang.is_function(getPointeeType(getCanonicalType(x)))
is_jl_funcptr(x::CLConstantArray) = Clang.is_function(getElementType(getCanonicalType(x)))
is_jl_funcptr(x::CLIncompleteArray) = Clang.is_function(getElementType(getCanonicalType(x)))
is_jl_funcptr(x::CLVariableArray) = Clang.is_function(getElementType(getCanonicalType(x)))
is_jl_funcptr(x::JuliaCpointer) = is_jl_funcptr(x.ref)
is_jl_funcptr(x::JuliaCconstarray) = is_jl_funcptr(x.ref)
is_jl_funcptr(x::JuliaCincompletearray) = is_jl_funcptr(x.ref)
is_jl_funcptr(x::JuliaCvariablearray) = is_jl_funcptr(x.ref)

function get_jl_leaf_pointee_type(x::JuliaCpointer)
    jlptree = tojulia(getPointeeType(x.ref))
    if is_jl_funcptr(x)
        if jlptree isa JuliaCtypedef
            return get_jl_leaf_type(jlptree)
        else
            return JuliaPtrCvoid()
        end
    end
    return get_jl_leaf_type(jlptree)
end

function get_jl_leaf_pointee_type(x::JuliaObjCObjectPointer)
    jlptree = tojulia(getPointeeType(x.ref))
    if is_jl_funcptr(x)
        if jlptree isa JuliaCtypedef
            return get_jl_leaf_type(jlptree)
        else
            return JuliaPtrCvoid()
        end
    end
    return get_jl_leaf_type(jlptree)
end

function get_jl_leaf_eltype(x::Union{JuliaCconstarray,JuliaCincompletearray,JuliaCvariablearray})
    is_jl_funcptr(x) && return JuliaPtrCvoid()
    jlelty = tojulia(getElementType(x.ref))
    return get_jl_leaf_type(jlelty)
end

get_jl_leaf_type(x::AbstractJuliaType) = x
get_jl_leaf_type(x::JuliaCpointer) = get_jl_leaf_pointee_type(x)
get_jl_leaf_type(x::JuliaObjCObjectPointer) = get_jl_leaf_pointee_type(x)
get_jl_leaf_type(x::JuliaCconstarray) = get_jl_leaf_eltype(x)
get_jl_leaf_type(x::JuliaCincompletearray) = get_jl_leaf_eltype(x)
get_jl_leaf_type(x::JuliaCvariablearray) = get_jl_leaf_eltype(x)

is_jl_integer(x::AbstractJuliaType) = false
is_jl_integer(x::JuliaCshort) = true
is_jl_integer(x::JuliaCushort) = true
is_jl_integer(x::JuliaCint) = true
is_jl_integer(x::JuliaCuint) = true
is_jl_integer(x::JuliaClonglong) = true
is_jl_integer(x::JuliaCulonglong) = true
is_jl_integer(x::JuliaCintmax_t) = true
is_jl_integer(x::JuliaCuintmax_t) = true
is_jl_integer(x::JuliaCssize_t) = true
is_jl_integer(x::JuliaCsize_t) = true
is_jl_integer(x::JuliaCuint128) = true
is_jl_integer(x::JuliaCint128) = true
is_jl_integer(x::JuliaCuint64_t) = true
is_jl_integer(x::JuliaCuint32_t) = true
is_jl_integer(x::JuliaCuint16_t) = true
is_jl_integer(x::JuliaCuint8_t) = true
is_jl_integer(x::JuliaCint64_t) = true
is_jl_integer(x::JuliaCint32_t) = true
is_jl_integer(x::JuliaCint16_t) = true
is_jl_integer(x::JuliaCint8_t) = true
is_jl_integer(x::JuliaClong) = true
is_jl_integer(x::JuliaCulong) = true
