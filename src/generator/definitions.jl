# TODO: https://github.com/JuliaLang/julia/issues/29420
const DEFAULT_EXTRA_DEFINITIONS = Dict{Symbol,AbstractJuliaType}(
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
    :__uint64_t => JuliaCuint64_t(),
    :__uint32_t => JuliaCuint32_t(),
    :__uint16_t => JuliaCuint16_t(),
    :__uint8_t => JuliaCuint8_t(),
    :__int64_t => JuliaCint64_t(),
    :__int32_t => JuliaCint32_t(),
    :__int16_t => JuliaCint16_t(),
    :__int8_t => JuliaCint8_t(),
)

const EXTRA_DEFINITIONS = Dict{Symbol,AbstractJuliaType}()

add_definition(x::Dict{Symbol,<:AbstractJuliaType}) = merge!(EXTRA_DEFINITIONS, x)
add_definition(x::Pair{Symbol,<:AbstractJuliaType}) = push!(EXTRA_DEFINITIONS, x)

get_definition() = EXTRA_DEFINITIONS

function reset_definition()
    empty!(EXTRA_DEFINITIONS)
    merge!(EXTRA_DEFINITIONS, DEFAULT_EXTRA_DEFINITIONS)
end

macro add_def(c_symbol::Symbol, type::Symbol=:AbstractJuliaSIT, typename::Symbol=c_symbol, translated::Symbol=c_symbol)
    arg1 = Expr(:(::), typename)
    arg2 = Expr(:kw, :options, :(Dict()))
    sig = Expr(:call, Expr(:., :Generators, QuoteNode(:translate)), arg1, arg2)
    func = Expr(:(=), sig, Expr(:block, QuoteNode(:($translated))))
    ret = quote
        struct $typename <: $type end
        add_definition($(QuoteNode(c_symbol)) => $(esc(typename))())
        $(esc(func))
    end
    return ret
end
