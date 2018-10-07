"""
Reserved Julia identifiers will be prepended with "_"
"""
const RESERVED_WORDS = ["begin", "while", "if", "for", "try", "return", "break", "continue",
                        "function", "macro", "quote", "let", "local", "global", "const", "do",
                        "struct", "module", "baremodule", "using", "import", "export", "end",
                        "else", "elseif", "catch", "finally", "true", "false"]

"""
Unsupported argument types
"""
const RESERVED_ARG_TYPES = ["va_list"]

"""
These argument types will be untyped in the Julia signature
"""
const UNTYPED_ARG_TYPES = [CXType_IncompleteArray]

"""
Any failed cursor will be pushed into this global variable for debugging
"""
const DEBUG_CURSORS = []

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
    )

const INT_CONVERSION = Dict(
    :Cint   => Int32,
    :Cuint  => UInt32,
    :Uint64 => UInt64,
    :Uint32 => UInt32,
    :Uint16 => UInt16,
    :Uint8  => UInt8,
    :UInt64 => UInt64,
    :UInt32 => UInt32,
    :UInt16 => UInt16,
    :UInt8  => UInt8,
    :Int64  => Int64,
    :Int32  => Int32,
    :Int16  => Int16,
    :Int8   => Int8,
    )
