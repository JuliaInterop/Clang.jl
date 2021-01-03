# TODO: https://github.com/JuliaLang/julia/issues/29420
const EXTRA_DEFINITIONS = Dict(
    :ssize_t => JuliaCssize_t(),
    :size_t => JuliaCsize_t(),
    :ptrdiff_t => JuliaCptrdiff_t(),
    :uint64_t => JuliaCuint64_t(),
    :uint32_t => JuliaCuint32_t(),
    :uint16_t => JuliaCuint16_t(),
    :uint8_t => JuliaCuint8_t(),
    :int64_t => JuliaCint64_t(),
    :int32_t => JuliaCint32_t(),
    :int16_t => JuliaCint16_t(),
    :int8_t => JuliaCint8_t(),
    :uintptr_t => JuliaCuintptr_t(),
    :tm => JuliaCtm(),
    :wchar_t => JuliaCwchar_t(),
    :va_list => JuliaUnsupported(),
    :FILE => JuliaCFILE(),
)

add_definition(x::Dict{Symbol,<:AbstractJuliaType}) = merge!(EXTRA_DEFINITIONS, x)
