# InternalOptions
mutable struct InternalOptions
    wrap_structs::Bool
    ismutable::Bool
end
InternalOptions() = InternalOptions(true, false)

struct Poisoned end

mutable struct ExprUnit
    items::Vector
    deps::OrderedSet{Symbol}
    state::Symbol
end

function ExprUnit(a::Array, deps=[]; state::Symbol=:new)
    ExprUnit(a, OrderedSet{Symbol}([target_type(dep) for dep in deps]), state)
end
function ExprUnit(e::Union{Expr,Symbol,String,Poisoned}, deps=[]; state::Symbol=:new)
    ExprUnit([e], OrderedSet{Symbol}([target_type(dep) for dep in deps]), state)
end
ExprUnit() = ExprUnit([], OrderedSet{Symbol}(), :new)

### WrapContext
# stores shared information about the wrapping session
mutable struct WrapContext
    index::Index
    headers::Array{String,1}
    output_file::String
    common_file::String
    clang_includes::Array{String,1}              # clang include paths
    clang_args::Array{String,1}                  # additional {"-Arg", "value"} pairs for clang
    header_wrapped::Function                     # called to determine header inclusion status
                                                 #   (top_header, cursor_header) -> Bool
    header_library::Function                     # called to determine shared library for given header
                                                 #   (header_name) -> library_name::AbstractString
    header_outputfile::Function                  # called to determine output file group for given header
                                                 #   (header_name) -> output_file::AbstractString
    cursor_wrapped::Function                     # called to determine cursor inclusion status
                                                 #   (cursor_name, cursor) -> Bool
    common_buf::OrderedDict{Symbol, ExprUnit}    # output buffer for common items: typedefs, enums, etc.
    output_bufs::DefaultOrderedDict{String, Array{Any}}
    options::InternalOptions
    rewriter::Function
end

### Convenience function to initialize wrapping context with defaults
function init(;
            headers                         = String[],
            index                           = Union{},
            output_file::String             = "",
            common_file::String             = "",
            output_dir::String              = "",
            clang_args::Array{String,1}
                                            = String[],
            clang_includes::Array{String,1}
                                            = String[],
            clang_diagnostics::Bool         = true,
            header_wrapped                  = (header, cursorname) -> true,
            header_library                  = Union{},
            header_outputfile               = Union{},
            cursor_wrapped                  = (cursorname, cursor) -> true,
            options                         = InternalOptions(),
            rewriter                        = x -> x)

    # Set up some optional args if they are not explicitly passed.

    (index == Union{}) && ( index = Index(0, clang_diagnostics) )

    if (output_file == "" && header_outputfile == Union{})
        header_outputfile = x->joinpath(output_dir, strip(splitext(basename(x))[1]) * ".jl")
    end

    (common_file == "") && ( common_file = output_file )
    common_file = joinpath(output_dir, common_file)

    if (header_library == Union{})
        header_library = x->strip(splitext(basename(x))[1])
    elseif isa(header_library, String)
        libname = copy(header_library)
        header_library = x->libname
    end
    if (header_outputfile == Union{})
        header_outputfile = x->joinpath(output_dir, output_file)
    end

    # Instantiate and return the WrapContext
    global context = WrapContext(index,
                                 headers,
                                 output_file,
                                 common_file,
                                 clang_includes,
                                 clang_args,
                                 header_wrapped,
                                 header_library,
                                 header_outputfile,
                                 cursor_wrapped,
                                 OrderedDict{Symbol,ExprUnit}(),
                                 DefaultOrderedDict{String, Array{Any}}(()->Any[]),
                                 options,
                                 rewriter)
    return context
end



"""
    clang2julia(t::CXType) -> Symbol/Expr
    clang2julia(c::Cursor) -> Symbol/Expr
Convert libclang cursor/type to Julia type.
"""
clang2julia(t::CXType) = _clang2julia(Val(kind(t)), t)
function _clang2julia(::Val, t::CXType)
    typeKind = kind(t)
    !haskey(CLANG_JULIA_TYPEMAP, typeKind) && error("No CXType translation available for: $typeKind")
    return CLANG_JULIA_TYPEMAP[typeKind]
end
function _clang2julia(::Union{Val{CXType_Record},Val{CXType_Typedef}}, t::CXType)
    tname = Symbol(spelling(typedecl(t)))
    return get(CLANG_JULIA_TYPEMAP, tname, tname)
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

clang2julia(c::CXCursor) = _clang2julia(Val(kind(c)), c)
_clang2julia(::Val, c::CXCursor) = clang2julia(type(c))
_clang2julia(::Val{CXCursor_UnionDecl}, c::CXCursor) = typedecl(c) |> largestfield |> clang2julia
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
Return field decl sizes.
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
    _wrap!(::Val{CXCursor_FunctionDecl}, cursor::CXCursor, buffer::Vector; libname="libxxx")
Subroutine for handling function declarations.
"""
function _wrap!(::Val{CXCursor_FunctionDecl}, cursor::CXCursor, buffer::Vector; libname="libxxx")
    func_type = type(cursor)
    if kind(func_type) == CXType_FunctionNoProto
        @warn "No Prototype for $cursor - assuming no arguments"
    elseif isvariadic(func_type) == 1
        @warn "Skipping VarArg Function $cursor"
        return buffer
    end
    libname == "libxxx" && @warn "default libname: \"libxxx\" are being used, did you forget to specify the libname?"

    funcName = Symbol(spelling(cursor))
    ret_type = clang2julia(return_type(cursor))

    args = function_args(cursor)

    arg_types = [argtype(func_type, i) for i in 0:length(args)-1]
    arg_reps = [clang2julia(x) for x in arg_types]

    # check whether any argument types are blocked
    for t in arg_types
        if spelling(t) in RESERVED_ARG_TYPES
            @warn "Skipping $(name(cursor)) due to unsupported argument: $(name(t))"
            return buffer
        end
    end

    # Handle unnamed args and convert names to symbols
    arg_count = 0
    arg_names = convert(Vector{Symbol},
                        map(x-> Symbol(begin
                                         nm = name_safe(name(x))
                                         nm != "" ? nm : "arg"*string(arg_count+=1)
                                       end),
                                args))

    sig = efunsig(funcName, arg_names, arg_reps)
    body = eccall(funcName, Symbol(libname), ret_type, arg_names, arg_reps)
    e = Expr(:function, sig, Expr(:block, body))
    push!(buffer, e)
end

function is_ptr_type_expr(@nospecialize t)
    (t === :Cstring || t === :Cwstring) && return true
    isa(t, Expr) || return false
    t = t::Expr
    t.head === :curly && t.args[1] === :Ptr
end

function efunsig(name::Symbol, args::Vector{Symbol}, types)
    x = Any[is_ptr_type_expr(t) ? a : Expr(:(::), a, t) for (a,t) in zip(args,types)]
    Expr(:call, name, x...)
end

function eccall(funcname::Symbol, libname::Symbol, rtype, args, types)
  :(ccall(($(QuoteNode(funcname)), $libname),
            $rtype,
            $(Expr(:tuple, types...)),
            $(args...))
    )
end

"""
    _wrap!(::Val{CXCursor_EnumDecl}, cursor::CXCursor, buffer::OrderedDict; customName="")
Subroutine for handling enum declarations.
"""
function _wrap!(::Val{CXCursor_EnumDecl}, cursor::CXCursor, buffer::OrderedDict{Symbol,ExprUnit}; customName="")
    cursorName = name(cursor)
    if cursorName == "" && customName == ""
        @warn "Skipping unnamed EnumDecl: $cursor"
        return buffer
    end
    enumName = customName == "" ? cursorName : customName
    enumSym = symbol_safe(enumName)
    enumType = clang2julia(cursor)
    name2value = Tuple{Symbol,Int}[]
    # exctract values and names
    for itemCursor in children(cursor)
        itemName = spelling(itemCursor)
        isempty(itemName) && continue
        itemSym = symbol_safe(itemName)
        push!(name2value, (itemSym, value(itemCursor)))
    end
    intSize = 8*sizeof(INT_CONVERSION[enumType])
    if intSize == 32 # only add size if != 32
        expr = :(@cenum($enumSym))
    else
        expr = :(@cenum($enumSym{$intSize}))
    end
    buffer[enumSym] = ExprUnit(expr)
    for (name,value) in name2value
        buffer[name] = buffer[enumSym]
        push!(expr.args, :($name = $value))
    end
    return buffer
end

"""
    _wrap!(::Val{CXCursor_StructDecl}, cursor::CXCursor, buffer::OrderedDict; customName="", ismutable=false)
Subroutine for handling struct declarations.
"""
function _wrap!(::Val{CXCursor_StructDecl}, cursor::CXCursor, buffer::OrderedDict{Symbol,ExprUnit}; customName="", ismutable=false)
    cursorName = name(cursor)
    if cursorName == "" && customName == ""
        @warn "Skipping unnamed StructDecl: $cursor"
        return buffer
    end
    structName = customName == "" ? cursorName : customName
    structSym = symbol_safe(structName)
    # Generate type declaration
    block = Expr(:block)
    expr = Expr(:struct, ismutable, structSym, block)
    deps = OrderedSet{Symbol}()
    structFields = children(cursor)
    for fieldCursor in structFields
        fieldName = name(fieldCursor)
        fieldKind = kind(fieldCursor)
        if fieldKind == CXCursor_StructDecl || fieldKind == CXCursor_UnionDecl
            continue
        elseif fieldKind != CXCursor_FieldDecl || fieldKind == CXCursor_TypeRef
            buffer[structSym] = ExprUnit(Poisoned())
            @warn "Skipping struct: \"$cursor\" due to unsupported field: $fieldCursor"
            return buffer
        elseif isempty(fieldName)
            error("Unnamed struct member in: $cursor ... cursor: $fieldCursor")
        end
        repr = clang2julia(fieldCursor)
        push!(block.args, Expr(:(::), symbol_safe(fieldName), repr))
        push!(deps, target_type(repr))
    end

    # Check for a previous forward ordering
    if !(structSym in keys(buffer)) || (buffer[structSym].state == :empty)
        if !isempty(structFields)
            buffer[structSym] = ExprUnit(expr, deps)
        else
            # Possible forward definition
            buffer[structSym] = ExprUnit(expr, deps, state=:empty)
        end
    end
    return buffer
end

"""
    _wrap!(::Val{CXCursor_UnionDecl}, cursor::CXCursor, buffer::OrderedDict; customName="", ismutable=false)
Subroutine for handling union declarations.
"""
function _wrap!(::Val{CXCursor_UnionDecl}, cursor::CXCursor, buffer::OrderedDict{Symbol,ExprUnit}; customName="", ismutable=false)
    cursorName = name(cursor)
    if cursorName == "" && customName == ""
        @warn "Skipping unnamed UnionDecl: $cursor"
        return buffer
    end
    unionName = customName == "" ? cursorName : customName
    unionSym = symbol_safe(unionName)
    block = Expr(:block)
    expr = Expr(:struct, ismutable, unionSym, block)
    cursorSym = Symbol("_", unionName)
    cursorMax = largestfield(cursor)
    target = clang2julia(cursorMax)
    push!(block.args, Expr(:(::), cursorSym, target))

    # TODO: add other dependencies
    buffer[cursorSym] = ExprUnit(expr, Any[target])

    return buffer
end

"""
    _wrap!(::Val{CXCursor_TypedefDecl}, cursor::CXCursor, buffer::OrderedDict; customName="")
Subroutine for handling typedef declarations.
"""
function _wrap!(::Val{CXCursor_TypedefDecl}, cursor::CXCursor, buffer::OrderedDict{Symbol,ExprUnit}; customName="")
    td_type = underlying_type(cursor)
    td_sym = Symbol(spelling(cursor))

    if kind(td_type) == CXType_Unexposed
        local tdunxp::CXCursor
        for c in children(cursor)
            # skip any leading non-type cursors
            # Attributes, ...
            if kind(c) != CXCursor_FirstAttr
                tdunxp = c
                break
            end
        end

        if kind(tdunxp) == CXCursor_TypeRef
            unxp_target = clang2julia(tdunxp)
            if !haskey(buffer, td_sym)
                buffer[td_sym] = ExprUnit(:(const $td_sym = $unxp_target), Any[unxp_target])
            end
            return buffer
        else
            _wrap!(Val(kind(tdunxp)), tdunxp, buffer, customName=name(cursor))
            return buffer
        end
    end

    if kind(td_type) == CXType_FunctionProto
        if !haskey(buffer, td_sym)
            buffer[td_sym] = ExprUnit(string("# Skipping Typedef: CXType_FunctionProto ", spelling(cursor)))
        end
        return buffer
    end

    td_target = clang2julia(td_type)
    if !haskey(buffer, td_sym)
        buffer[td_sym] = ExprUnit(:(const $td_sym = $td_target), Any[td_target])
    end
    return buffer
end

################################################################################
# Handler for macro definitions
################################################################################
#
# For handling of #define'd constants, allows basic expressions
# but bails out quickly.

function handle_macro_exprn(tokens::TokenList, pos::Int)
    function trans(tok)
        ops = ["+" "-" "*" "~" ">>" "<<" "/" "\\" "%" "|" "||" "^" "&" "&&"]
        tokenKind = kind(tok)
        txt = spelling(tokens.tu, tok)
        (tokenKind == CXToken_Literal || tokenKind == CXToken_Identifier) && return 0
        tokenKind == CXToken_Punctuation && txt ∈ ops && return 1
        return -1
    end

    # normalize literal with a size suffix
    function literally(tok)
        # note: put multi-character first, or it will break out too soon for those!
        literalsuffixes = ["ULL", "Ull", "uLL", "ull", "LLU", "LLu", "llU", "llu",
                           "LL", "ll", "UL", "Ul", "uL", "ul", "LU", "Lu", "lU", "lu",
                           "U", "u", "L", "l", "F", "f"]

        function literal_totype(literal, txt)
          literal = lowercase(literal)

          # Floats following http://en.cppreference.com/w/cpp/language/floating_literal
          float64 = occursin(".", txt) && occursin("l", literal)
          float32 = occursin("f", literal)

          if float64 || float32
            float64 && return "Float64"
            float32 && return "Float32"
          end

          # Integers following http://en.cppreference.com/w/cpp/language/integer_literal
          unsigned = occursin("u", literal)
          nbits = count(x -> x == 'l', literal) == 2 ? 64 : 32
          return "$(unsigned ? "U" : "")Int$nbits"
        end

        tokenKind = kind(tok)
        txt = spelling(tokens.tu, tok) |> strip
        if tokenKind == CXToken_Identifier || tokenKind == CXToken_Punctuation
            # pass
        elseif tokenKind == CXToken_Literal
            for sfx in literalsuffixes
                if endswith(txt, sfx)
                    type = literal_totype(sfx, txt)
                    txt = txt[1:end-length(sfx)]
                    txt = "$(type)($txt)"
                    break
                end
            end
        end
        return txt
    end

    # check whether identifiers and literals alternate
    # with punctuation
    exprn = ""
    pos > length(tokens) && return exprn, pos

    prev = 1 >> trans(tokens[pos])
    for lpos = pos:length(tokens)
        pos = lpos
        tok = tokens[lpos]
        state = trans(tok)
        if xor(state, prev) == 1
            prev = state
        else
            break
        end
        exprn = exprn * literally(tok)
    end
    return exprn, pos
end

# TODO: This really returns many more symbols than we want,
# Functionally, it shouldn't matter, but eventually, we
# might want something more sophisticated.
# (Check: Does this functionality already exist elsewhere?)
get_symbols(s) = Any[]
get_symbols(s::Symbol) = Any[s]
get_symbols(e::Expr) = vcat(get_symbols(e.head), get_symbols(e.args))
get_symbols(xs::Array) = reduce(vcat, [get_symbols(x) for x in xs])

"""
    _wrap!(::Val{CXCursor_MacroDefinition}, cursor::CXCursor, buffer::OrderedDict)
Subroutine for handling macro declarations.
"""
function _wrap!(::Val{CXCursor_MacroDefinition}, cursor::CXCursor, buffer::OrderedDict{Symbol,ExprUnit})
    tokens = tokenize(cursor)
    # Skip any empty definitions
    tokens.size < 2 && return buffer
    startswith(name(cursor), "_") && return buffer

    text = x->spelling(tokens.tu, x)
    pos = 1; exprn = ""
    if text(tokens[2]) == "("
        exprn, pos = handle_macro_exprn(tokens, 3)
        if pos != lastindex(tokens) || text(tokens[pos]) != ")" || exprn == ""
            mdef_str = join([text(c) for c in tokens], " ")
            buffer[Symbol(mdef_str)] = ExprUnit(string("# Skipping MacroDefinition: ", replace(mdef_str, "\n"=>"\n#")))
            return buffer
        end
        exprn = "(" * exprn * ")"
    else
        exprn, pos = handle_macro_exprn(tokens, 2)
        if pos != lastindex(tokens)
            mdef_str = join([text(c) for c in tokens], " ")
            buffer[Symbol(mdef_str)] = ExprUnit(string("# Skipping MacroDefinition: ", replace(mdef_str, "\n"=>"#\n")))
            return buffer
        end
    end

    # Occasionally, skipped definitions slip through
    (exprn == "" || exprn == "()") && return buffer

    use_sym = symbol_safe(text(tokens[1]))
    target = Meta.parse(exprn)
    e = Expr(:const, Expr(:(=), use_sym, target))

    deps = get_symbols(target)
    buffer[use_sym] = ExprUnit(e, deps)

    return buffer
end

# Does this actually occur in header files???
function _wrap!(::Val{CXCursor_TypeRef}, cursor::CXCursor, buffer::OrderedDict{Symbol,ExprUnit}; customName="")
    customName == "" && (customName = name(cursor);)
    @error "Found CXCursor_TypeRef: ", cursor
    println("Printing CXCursor_TypeRef: ", cursor)
    usesym = Symbol(customName)
    buffer[usesym] = ExprUnit(usesym)
end

_wrap!(::Val, cursor::CXCursor, buffer; customName="") = @warn "Not wrapping $(cursor), custom name: $customName"
wrap!(cursor::CXCursor, buffer; args...) = _wrap!(Val(kind(cursor)), cursor, buffer; args...)


function wrap_header(wc::WrapContext, transUnit::TranslationUnit, topHeader, out_buffer::Array)
    @info "wrapping header: $topHeader ..."
    GC.@preserve transUnit begin
        topCursor = getcursor(transUnit)
        push!(DEBUG_CURSORS, topCursor)
        # Loop over all of the child cursors and wrap them, if appropriate.
        childCursors = children(topCursor)
        for (i, child) in enumerate(childCursors)
            childName = name(child)
            childHeader = filename(child)
            childKind = kind(child)
            # what should be wrapped:
            #   1. wrap if context.header_wrapped(topHeader, childHeader) == True
            #   2. wrap if context.cursor_wrapped(cursor_name, cursor) == True
            #   3. skip compiler defs and cursors already wrapped
            if !wc.header_wrapped(topHeader, childHeader) ||
               !wc.cursor_wrapped(childName, child) ||       # client callbacks
               startswith(childName, "__")          ||       # skip compiler definitions
               childName in keys(wc.common_buf)              # already wrapped
                continue
            end

            # try
                if childKind == CXCursor_FunctionDecl
                    wrap!(child, out_buffer, libname=wc.header_library(filename(child)))
                elseif (childKind == CXCursor_EnumDecl || childKind == CXCursor_StructDecl) &&
                       (i != length(childCursors))
                    nextCursor = childCursors[i+1]
                    if is_typedef_anon(child, nextCursor)
                        wrap!(child, wc.common_buf, customName=name(nextCursor))
                    else
                        wrap!(child, wc.common_buf)
                    end
                elseif childKind != CXCursor_TypeRef
                    wrap!(child, wc.common_buf)
                else
                    continue
                end
            # catch err
            #     push!(DEBUG_CURSORS, cursor)
            #     @error "error thrown. Last cursor available in Clang.wrap_c.DEBUG_CURSORS."
            #     rethrow(err)
            # end
        end
    end
end

function parse_c_headers(wc::WrapContext)
    parsed = Dict{String,TranslationUnit}()

    # Parse the headers
    for header in unique(wc.headers)
        tu = parse_header(header;
                          index = wc.index,
                          args = wc.clang_args,
                          includes = wc.clang_includes,
                          flags = CXTranslationUnit_DetailedPreprocessingRecord |
                                  CXTranslationUnit_SkipFunctionBodies)
        parsed[header] = tu
    end
    return parsed
end

function sort_includes(wc::WrapContext, parsed)
    includes = mapreduce(x->search(parsed[x], CXCursor_InclusionDirective), append!, keys(parsed))
    header_paths = unique(clang_getIncludedFile.(includes))
    return unique(vcat(filter(x -> x in header_paths, wc.headers), wc.headers))
end

"""
Pretty-print a buffer of expressions (and comments) to an output stream
Adds blank lines at appropriate places for readability
"""
function print_buffer(out_stream, out_buffer)
    state = :comment
    in_enum = false
    for e in out_buffer
        isa(e, Poisoned) && continue
        prev_state = state
        state = (isa(e, AbstractString) ? :string :
                 isa(e, Expr) ? e.head :
                 error("output: can't handle type $(typeof(e))"))

        if state == :string && startswith(e, "# Skipping")
            state = :skipping
        end

        if ((state != prev_state && prev_state != :string) ||
            (state == prev_state && (state == :function || state == :type)))
            println(out_stream)
        end

        if isa(e, Expr) && e.head == :macrocall && first(e.args) == Symbol("@cenum")
            println(out_stream, "@cenum($(e.args[3]),")
            for elem in e.args[4:end]
                println(out_stream, "    $elem,")
            end
            println(out_stream, ")")
            continue
        end
        println(out_stream, e)
    end
end

# function dump_to_buffer!(buffer::Vector, expr_dict::OrderedDict{Symbol,ExprUnit}, item::ExprUnit)
#     (item.state == :done || item.state == :processing) && return buffer
#     item.state = :processing
#     for dep in item.deps
#         haskey(expr_dict, dep) || continue
#         dump_to_buffer!(buffer, expr_dict, buffer[dep])
#     end
#     append!(buffer, item.items)
#     item.state = :done
#     return buffer
# end
#
# function dump_to_buffer(expr_dict::OrderedDict{Symbol,ExprUnit})
#     buffer = []
#     for item in values(expr_dict)
#         item.state == :done && continue
#         dump_to_buffer!(buffer, expr_dict, item)
#     end
#     return buffer
# end

function dump_to_buffer!(buf::Array, expr_buf::OrderedDict{Symbol, ExprUnit}, item::ExprUnit)
    (item.state == :done || item.state == :processing) && return nothing
    item.state = :processing

    for dep in item.deps
        dep_expr = get(expr_buf, dep, nothing)
        dep_expr == nothing && continue
        dump_to_buffer!(buf, expr_buf, dep_expr)
    end

    append!(buf, item.items)
    item.state = :done
end


function dump_to_buffer(expr_buf::OrderedDict{Symbol, ExprUnit})
    buf = Any[]
    for item in values(expr_buf)
        item.state == :done && continue
        dump_to_buffer!(buf, expr_buf, item)
    end
    buf
end


function Base.run(wc::WrapContext)
    # Parse headers
    parsed = parse_c_headers(wc)
    # Sort includes by requirement order
    wc.headers = sort_includes(wc, parsed)

    # Helper to store file handles
    filehandles = Dict{String,IOStream}()
    getfile(f) = (f in keys(filehandles)) ? filehandles[f] : (filehandles[f] = open(f, "w"))

    for hfile in wc.headers
        out_file = wc.header_outputfile(hfile)
        out_buffer = wc.output_bufs[hfile]

        # Extract header to Expr[] array
        wrap_header(wc, parsed[hfile], hfile, out_buffer)

        # Apply user-supplied transformation
        wc.output_bufs[hfile] = wc.rewriter(out_buffer)

        # Debug
        @info "writing $(out_file)"

        # Write output
        out_stream = getfile(out_file)
        println(out_stream, "# Julia wrapper for header: $hfile")
        println(out_stream, "# Automatically generated using Clang.jl wrap_c\n")

        print_buffer(out_stream, wc.output_bufs[hfile])
    end

    common_buf = dump_to_buffer(wc.common_buf)

    # Apply user-supplied transformation
    common_buf = wc.rewriter(common_buf)

    # Write "common" definitions: types, typealiases, etc.
    open(wc.common_file, "w") do f
        println(f, "# Automatically generated using Clang.jl wrap_c\n")
        print_buffer(f, common_buf)
    end

    map(close, values(filehandles))
end

###############################################################################
# Utilities
###############################################################################
name_safe(name::AbstractString) = (name in RESERVED_WORDS) ? "_"*name : name
symbol_safe(name::AbstractString) = Symbol(name_safe(name))
