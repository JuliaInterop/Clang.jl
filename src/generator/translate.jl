"""
Reserved Julia identifiers will be prepended with "_"
"""
const RESERVED_WORDS = ["begin", "while", "if", "for", "try", "return", "break", "continue",
                        "function", "macro", "quote", "let", "local", "global", "const", "do",
                        "struct", "module", "baremodule", "using", "import", "export", "end",
                        "else", "elseif", "catch", "finally", "true", "false"]

"""
    make_name_safe(name::Symbol) -> String
    make_name_safe(name::AbstractString) -> String
Return a valid Julia variable name, prefixed with "_" if the `name` is conflict with Julia's
reserved words.
"""
make_name_safe(name::AbstractString) = (name in RESERVED_WORDS) ? "_" * name : name
make_name_safe(name::Symbol) = make_name_safe(string(name))

"""
    make_symbol_safe(name) -> Symbol
Same as [`make_name_safe`](@ref), but return a Symbol.
"""
make_symbol_safe(x) = Symbol(make_name_safe(x))

"""
    translate(jlty::AbstractJuliaType, options=Dict())
Translate [`AbstractJuliaType`](@ref)s to Julia expressions.
"""
translate(jlty::AbstractJuliaType, options=Dict()) = jlty
function translate(jlty::JuliaUnknown, options=Dict())
    return error("hit a JuliaUnknown($(dumpobj(jlty.x))) when translating the type...")
end
translate(jlty::JuliaCvoid, options=Dict()) = :Cvoid
function translate(jlty::JuliaCbool, options=Dict())
    return get(options, "use_julia_bool", true) ? :Bool : :UInt8
end
translate(jlty::JuliaCuchar, options=Dict()) = :Cuchar
translate(jlty::JuliaCshort, options=Dict()) = :Cshort
translate(jlty::JuliaCushort, options=Dict()) = :Cushort
translate(jlty::JuliaCint, options=Dict()) = :Cint
translate(jlty::JuliaCuint, options=Dict()) = :Cuint
translate(jlty::JuliaClonglong, options=Dict()) = :Clonglong
translate(jlty::JuliaCulonglong, options=Dict()) = :Culonglong
translate(jlty::JuliaCintmax_t, options=Dict()) = :Cintmax_t
translate(jlty::JuliaCuintmax_t, options=Dict()) = :Cuintmax_t
translate(jlty::JuliaCfloat, options=Dict()) = :Cfloat
translate(jlty::JuliaCdouble, options=Dict()) = :Cdouble
translate(jlty::JuliaComplexF32, options=Dict()) = :ComplexF32
translate(jlty::JuliaComplexF64, options=Dict()) = :ComplexF64
translate(jlty::JuliaCptrdiff_t, options=Dict()) = :Cptrdiff_t
translate(jlty::JuliaCssize_t, options=Dict()) = :Cssize_t
translate(jlty::JuliaCsize_t, options=Dict()) = :Csize_t
translate(jlty::JuliaNoReturn, options=Dict()) = :(Union{})
translate(jlty::JuliaPtrCvoid, options=Dict()) = :(Ptr{Cvoid})
translate(jlty::JuliaCstring, options=Dict()) = :Cstring
translate(jlty::JuliaPtrUInt8, options=Dict()) = :(Ptr{UInt8})
translate(jlty::JuliaPtrPtrUInt8, options=Dict()) = :(Ptr{Ptr{UInt8}})
translate(jlty::JuliaAny, options=Dict()) = :Any
translate(jlty::JuliaRefAny, options=Dict()) = :(Ref{Any})
translate(jlty::JuliaCuint128, options=Dict()) = :UInt128
translate(jlty::JuliaCint128, options=Dict()) = :Int128
translate(jlty::JuliaCschar, options=Dict()) = :Int8
translate(jlty::JuliaClongdouble, options=Dict()) = :Float64  # FIXME: the actually type depends on compiler
translate(jlty::JuliaComplex, options=Dict()) = :ComplexF32  # FIXME: correct this
translate(jlty::JuliaChalf, options=Dict()) = :Float16
translate(jlty::JuliaCfloat16, options=Dict()) = :Float16
translate(jlty::JuliaCfloat128, options=Dict()) = :(NTuple{2,VecElement{Float64}})
translate(jlty::JuliaCuint64_t, options=Dict()) = :UInt64
translate(jlty::JuliaCuint32_t, options=Dict()) = :UInt32
translate(jlty::JuliaCuint16_t, options=Dict()) = :UInt16
translate(jlty::JuliaCuint8_t, options=Dict()) = :UInt8
translate(jlty::JuliaCint64_t, options=Dict()) = :Int64
translate(jlty::JuliaCint32_t, options=Dict()) = :Int32
translate(jlty::JuliaCint16_t, options=Dict()) = :Int16
translate(jlty::JuliaCint8_t, options=Dict()) = :Int8
translate(jlty::JuliaCuintptr_t, options=Dict()) = :Csize_t
translate(jlty::JuliaCtm, options=Dict()) = :(Libc.TmStruct)
translate(jlty::JuliaCchar, options=Dict()) = :Cchar
translate(jlty::JuliaClong, options=Dict()) = :Clong
translate(jlty::JuliaCulong, options=Dict()) = :Culong
translate(jlty::JuliaCwchar_t, options=Dict()) = :Cwchar_t
translate(jlty::JuliaCFILE, options=Dict()) = :(Libc.FILE)

function translate(jlty::JuliaCpointer, options=Dict())
    jlptree = tojulia(getPointeeType(jlty.ref))
    if is_jl_funcptr(jlty)
        if jlptree isa JuliaCtypedef
            return Expr(:curly, :Ptr, translate(jlptree, options))
        else
            return translate(JuliaPtrCvoid(), options)
        end
    end
    if get(options, "always_NUL_terminated_string", false)
        is_jl_char(jlptree) && return :Cstring
        is_jl_wchar(jlptree) && return :Cwstring
    end
    return Expr(:curly, :Ptr, translate(jlptree, options))
end

function translate(jlty::JuliaCconstarray, options=Dict())
    n = getNumElements(jlty.ref)
    elty = translate(tojulia(getElementType(jlty.ref)), options)
    return :(NTuple{$n,$elty})
end

function translate(jlty::JuliaCincompletearray, options=Dict())
    elty = translate(tojulia(getElementType(jlty.ref)), options)
    return Expr(:curly, :Ptr, elty)
end

function translate(jlty::JuliaCvariablearray, options=Dict())
    elty = translate(tojulia(getElementType(jlty.ref)), options)
    return Expr(:curly, :Ptr, elty)
end

function translate(jlty::JuliaCtypedef, options=Dict())
    ids = get(options, "DAG_ids", Dict())
    ids_extra = get(options, "DAG_ids_extra", Dict())

    if haskey(ids, jlty.sym)
        return make_symbol_safe(jlty.sym)
    elseif haskey(ids_extra, jlty.sym)
        return translate(ids_extra[jlty.sym], options)
    elseif get(options, "opaque_func_arg_as_PtrCvoid", false)
        return translate(JuliaCvoid(), options)
    else
        return make_symbol_safe(jlty.sym)
    end
end

function translate(jlty::JuliaCenum, options=Dict())
    tags = get(options, "DAG_tags", Dict())
    # for now, we don't distinguish extra tags and ids, this may be improved in the future.
    # tags_extra = get(options, "DAG_tags_extra", Dict())
    ids_extra = get(options, "DAG_tags_extra", Dict())
    if haskey(tags, jlty.sym) || haskey(ids_extra, jlty.sym)
        return make_symbol_safe(jlty.sym)
    else
        # it could a local opaque tag-type
        return translate(JuliaCvoid(), options)
    end
end

function translate(jlty::JuliaCrecord, options=Dict())
    tags = get(options, "DAG_tags", Dict())
    # for now, we don't distinguish extra tags and ids, this may be improved in the future.
    # tags_extra = get(options, "DAG_tags_extra", Dict())
    ids_extra = get(options, "DAG_ids_extra", Dict())
    nested_tags = get(options, "nested_tags", Dict())
    if haskey(tags, jlty.sym) || haskey(ids_extra, jlty.sym)
        return make_symbol_safe(jlty.sym)
    else
        tag = get_nested_tag(nested_tags, jlty)
        isnothing(tag) || return tag
        # then it could be a local opaque tag-type
        return translate(JuliaCvoid(), options)
    end
end

translate(jlty::JuliaCfunction, options=Dict()) = translate(JuliaCvoid(), options)

function translate(jlty::JuliaObjCClass, options=Dict())
    ids = get(options, "DAG_ids", Dict())
    ids_extra = get(options, "DAG_ids_extra", Dict())

    if haskey(ids, jlty.sym)
        return make_symbol_safe(jlty.sym)
    elseif haskey(ids_extra, jlty.sym)
        return translate(ids_extra[jlty.sym], options)
    elseif get(options, "opaque_func_arg_as_PtrCvoid", false)
        return translate(JuliaCvoid(), options)
    else
        return make_symbol_safe(jlty.sym)
    end
end
function translate(jlty::JuliaObjCId, options=Dict())
    ids = get(options, "DAG_ids", Dict())
    ids_extra = get(options, "DAG_ids_extra", Dict())

    if haskey(ids, jlty.sym)
        return :(id{Object})
    else
        return :(id{NSObject})
    end
end

function get_nested_tag(nested_tags, jlty)
    for (id, cursor) in nested_tags
        if is_same(jlty.cursor, cursor)
            # @assert isempty(string(jlty.sym))
            return id
        end
    end
    return nothing
end
