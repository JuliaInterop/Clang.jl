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
    empty_structs::Set{String}
    output_bufs::DefaultOrderedDict{String, Array{Any}}
    options::InternalOptions
    anon_count::Int
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
                                 Set{String}(),
                                 DefaultOrderedDict{String, Array{Any}}(()->Any[]),
                                 options,
                                 0,
                                 rewriter)
    return context
end



"""
    represent2jl(t::CXType)
    represent2jl(c::Cursor)
libclang objects to Julia representation.
"""
represent2jl(t::CXType) = _represent2jl(Val(kind(t)), t)
function _represent2jl(::Val, t::CXType)
    typeKind = kind(t)
    !haskey(CLANG_JULIA_TYPEMAP, typeKind) && error("No CXType translation available for: $typeKind")
    return CLANG_JULIA_TYPEMAP[typeKind]
end
function _represent2jl(::Union{Val{CXType_Record},Val{CXType_Typedef}}, t::CXType)
    tname = Symbol(spelling(typedecl(t)))
    return get(CLANG_JULIA_TYPEMAP, tname, tname)
end
function _represent2jl(::Val{CXType_Pointer}, t::CXType)
    ptee = pointee_type(t)
    pteeKind = kind(pteeKind)
    (pteeKind == CXType_Char_U || pteeKind == CXType_Char_S) && return :Cstring
    pteeKind == CXType_WChar && return :Cwstring
    Expr(:curly, :Ptr, represent2jl(ptee))
end
function _represent2jl(::Val{CXType_Unexposed}, t::CXType)
    r = spelling(typedecl(t))
    r == "" ? :Cvoid : Symbol(r)
end
function _represent2jl(::Val{CXType_ConstantArray}, t::CXType)
    # For ConstantArray declarations, we use NTuples
    arrsize = clang_getArraySize(t)
    eltype = represent2jl(clang_getArrayElementType(t))
    return :(NTuple{$arrsize, $eltype})
end
function _represent2jl(::Val{CXType_IncompleteArray}, t::CXType)
    eltype = clang_getArrayElementType(t)
    Expr(:curly, :Ptr, represent2jl(eltype))
end

represent2jl(c::CXCursor) = _represent2jl(Val(kind(c)), c)
_represent2jl(::Val, c::CXCursor) = represent2jl(type(c))
_represent2jl(::Val{CXCursor_UnionDecl}, c::CXCursor) = typedecl(c) |> largestfield |> represent2jl
_represent2jl(::Val{CXCursor_EnumDecl}, c::CXCursor) = clang_getEnumDeclIntegerType(c) |> represent2jl
function _represent2jl(::Val{CXCursor_TypeRef}, c::CXCursor)
    reftype = clang_getCursorReferenced(c)
    refdef = clang_getCursorDefinition(reftype)
    cursorKind = kind(refdef)
    if isnull(refdef) || cursorKind == CXCursor_InvalidFile || cursorKind == CXCursor_FirstInvalid
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
_typesize(::Val{CXType_ConstantArray}, t::CXType) = clang_getArraySize(t)
_typesize(::Val{CXType_Typedef}, t::CXType) = typesize(typedecl(t))
_typesize(::Val{CXType_Record}, t::CXType) = (@warn("  incorrect typesize for CXType_Record field"); 0)
_typesize(::Val{CXType_Unexposed}, t::CXType) = (@warn("  incorrect typesize for CXType_Unexposed field"); 0)
_typesize(::Val{CXType_Invalid}, t::CXType) = (@warn("  incorrect typesize for CXType_Invalid field"); 0)

typesize(c::CXCursor) = _typesize(Val(kind(c)), c)
_typesize(::Val{CXCursor_TypedefDecl}, c::CXCursor) = typesize(clang_getTypedefDeclUnderlyingType(c))

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
        @warn "No Prototype for $(cursor) - assuming no arguments"
    elseif clang_isFunctionTypeVariadic(func_type) == 1
        @warn "Skipping VarArg Function $(cursor)"
        return buffer
    end
    libname == "libxxx" && @warn "default libname: \"libxxx\" are being used, did you forget to specify the libname?"

    func_name = Symbol(spelling(cursor))
    ret_type = represent2jl(return_type(cursor))

    args = function_args(cursor)

    arg_types = [clang_getArgType(func_type, i) for i in 0:length(args)-1]
    arg_reps = [represent2jl(x) for x in arg_types]

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

    sig = efunsig(func_name, arg_names, arg_reps)
    body = eccall(func_name, Symbol(libname), ret_type, arg_names, arg_reps)
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
    _wrap!(::Val{CXCursor_EnumDecl}, cursor::CXCursor, buffer::OrderedDict; usename="")
Subroutine for handling enum declarations.
"""
function _wrap!(::Val{CXCursor_EnumDecl}, cursor::CXCursor, buffer::OrderedDict; usename="")
    if usename == "" && (usename = name(cursor)) == ""
        usename = name_anon()
    end
    enumname = symbol_safe(usename)
    enumtype = represent2jl(cursor)
    name_values = Tuple{Symbol,Int}[]
    # exctract values and names
    for enumitem in children(cursor)
        cur_name = spelling(enumitem)
        isempty(cur_name) && continue
        cur_sym = symbol_safe(cur_name)
        push!(name_values, (cur_sym, Int(value(enumitem))))
    end
    int_size = 8*sizeof(INT_CONVERSION[enumtype])
    if int_size == 32 # only add size if != 32
        enum_expr = :(@cenum($enumname))
    else
        enum_expr = :(@cenum($enumname{$int_size}))
    end
    buffer[enumname] = ExprUnit(enum_expr)
    for (name, value) in name_values
        buffer[name] = buffer[enumname]
        push!(enum_expr.args, :($name = $value))
    end
    return buffer
end

"""
    _wrap!(::Val{CXCursor_StructDecl}, cursor::CXCursor, buffer::OrderedDict; usename="", ismutable=false)
Subroutine for handling struct declarations.
"""
function _wrap!(::Val{CXCursor_StructDecl}, cursor::CXCursor, buffer::OrderedDict; usename="", ismutable=false)
    if usename == "" && name(cursor) == ""
        @warn "Skipping unnamed StructDecl!"
        return buffer
    end
    usesym = Symbol(name(cursor))
    structFields = children(cursor)

    # Generate type declaration
    b = Expr(:block)
    e = Expr(:struct, ismutable, usesym, b)
    deps = OrderedSet{Symbol}()
    for cursor in structFields
        cursorName = spelling(cursor)
        cursorKind = kind(cursor)
        if cursorKind == CXCursor_StructDecl || cursorKind == CXCursor_UnionDecl
            continue
        elseif cursorKind != CXCursor_FieldDecl || cursorKind == CXCursor_TypeRef
            buffer[usesym] = ExprUnit(Poisoned())
            @warn "Skipping struct: \"$usename\" due to unsupported field: $cursorName"
            return buffer
        elseif isempty(cursorName)
            error("Unnamed struct member in: $usename ... cursor: $cursorName")
        end
        repr = represent2jl(cursor)
        push!(b.args, Expr(:(::), symbol_safe(cursorName), repr))
        push!(deps, target_type(repr))
    end

    # Check for a previous forward ordering
    if !(usesym in keys(buffer)) || (buffer[usesym].state == :empty)
        if !isempty(structFields)
            buffer[usesym] = ExprUnit(e, deps)
        else
            # Possible forward definition
            buffer[usesym] = ExprUnit(e, deps, state=:empty)
        end
    end
    return buffer
end

"""
    _wrap!(::Val{CXCursor_UnionDecl}, cursor::CXCursor, buffer::OrderedDict; usename="", ismutable=false)
Subroutine for handling union declarations.
"""
function _wrap!(::Val{CXCursor_UnionDecl}, cursor::CXCursor, buffer::OrderedDict; usename="", ismutable=false)
    if usename == "" && name(cursor) == ""
        @warn "Skipping unnamed StructDecl!"
        return buffer
    end

    b = Expr(:block)
    e = Expr(:struct, ismutable, Symbol(usename), b)
    cursorSym = Symbol("_", usename)
    cursorMax = largestfield(cursor)
    target = represent2jl(cursorMax)
    push!(b.args, Expr(:(::), cursorSym, target))

    # TODO: add other dependencies
    buffer[cursorSym] = ExprUnit(e, Any[target])

    return buffer
end

"""
    _wrap!(::Val{CXCursor_TypedefDecl}, cursor::CXCursor, buffer::OrderedDict; usename="")
Subroutine for handling typedef declarations.
"""
function _wrap!(::Val{CXCursor_TypedefDecl}, cursor::CXCursor, buffer::OrderedDict; usename="")
    td_type = clang_getTypedefDeclUnderlyingType(cursor)
    @assert !isvalid(td_type)
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
            unxp_target = represent2jl(tdunxp)
            if !haskey(buffer, td_sym)
                buffer[td_sym] = ExprUnit(:(const $td_sym = $unxp_target), Any[unxp_target])
            end
            return buffer
        else
            _wrap!(Val(kind(tdunxp)), tdunxp, buffer, usename=name(cursor))
            return buffer
        end
    end

    if kind(td_type) == CXType_FunctionProto
        if !haskey(buffer, td_sym)
            buffer[td_sym] = ExprUnit(string("# Skipping Typedef: CXType_FunctionProto ", spelling(cursor)))
        end
        return buffer
    end

    td_target = represent2jl(td_type)
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
function _wrap!(::Val{CXCursor_MacroDefinition}, cursor::CXCursor, buffer::OrderedDict)
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
function _wrap!(::Val{CXCursor_TypeRef}, cursor::CXCursor, buffer::OrderedDict; usename="")
    usename == "" && (usename = name(cursor);)
    @error "Found CXCursor_TypeRef: ", cursor
    println("Printing CXCursor_TypeRef: ", cursor)
    usesym = Symbol(usename)
    buffer[usesym] = ExprUnit(usesym)
end

_wrap!(::Val, cursor::CXCursor, buffer; usename="") = @warn "Not wrapping $(typeof(cursor))  $usename $(name(cursor))"
wrap!(cursor::CXCursor, buffer; args...) = _wrap!(Val(kind(cursor)), cursor, buffer; args...)


function wrap_header(wc::WrapContext, top_cursor::CXCursor, top_header, out_buffer::Array)
    @info "wrapping header: $top_header ..."
    push!(DEBUG_CURSORS, top_cursor)
    # Loop over all of the child cursors and wrap them, if appropriate.
    child_cursors = children(top_cursor)
    for (i, cursor) in enumerate(child_cursors)
        cursor_name = name(cursor)
        cursor_header = filename(cursor)
        cursor_kind = kind(cursor)

        # what should be wrapped:
        #   1. wrap if context.header_wrapped(top_header, cursor_header) == True
        #   2. wrap if context.cursor_wrapped(cursor_name, cursor) == True
        #   3. skip compiler defs and cursors already wrapped
        if !wc.header_wrapped(top_header, cursor_header) ||
           !wc.cursor_wrapped(cursor_name, cursor) ||       # client callbacks
           startswith(cursor_name, "__")           ||       # skip compiler definitions
           ((cursor_name in keys(wc.common_buf)) &&         # already wrapped
                    !(cursor_name in keys(wc.empty_structs)))
            continue
        end

        try
            if cursor_kind == CXCursor_FunctionDecl
                wrap(cursor, out_buffer, wc.header_library(filename(cursor)))
            elseif cursor_kind == CXCursor_EnumDecl || cursor_kind == CXCursor_StructDecl
                if i != length(cursors) && kind(child_cursors[i+1]) == CXCursor_TypedefDecl
                    # combine EnumDecl or StructDecl followed by TypedefDecl
                    # without this, this enum from C:
                    # typedef enum {
                    #     GA_ReadOnly = 0,
                    #     GA_Update = 1
                    # } GDALAccess;
                    # would be converted into Julia:
                    # @enum ANONYMOUS_* GA_ReadOnly = 0, GA_Update = 1
                    # const GDALAccess = Void
                    # instead of just
                    # @enum GDALAccess GA_ReadOnly = 0, GA_Update = 1
                    wrap!(cursor, wc.common_buf, usename=name(child_cursors[i+1]))
                else
                    wrap!(cursor, wc.common_buf)
                end
            elseif cursor_kind != CXCursor_TypeRef
                wrap!(cursor, wc.common_buf)
            else
                continue
            end
        catch err
            push!(DEBUG_CURSORS, cursor)
            @error "error thrown. Last cursor available in Clang.wrap_c.DEBUG_CURSORS."
            rethrow(err)
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
                          flags = TranslationUnit_Flags.DetailedPreprocessingRecord |
                                  TranslationUnit_Flags.SkipFunctionBodies)
        parsed[header] = tu
    end
    return parsed
end

function sort_includes(wc::WrapContext, parsed)
    includes = mapreduce(x->search(parsed[x], CXCursor_InclusionDirective), append!, keys(parsed))
    header_paths = clang_getIncludedFile.(includes) |> unique
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

        if isa(e, Expr) && e.head == :macrocall && first(e.args) == symbol("@cenum")
            println(out_stream, "@cenum($(e.args[2]),")
            for elem in e.args[3:end]
                println(out_stream, "    $elem,")
            end
            println(out_stream, ")")
            continue
        end
        println(out_stream, e)
    end
end

function dump_to_buffer!(buffer::Vector, expr_dict::OrderedDict{Symbol,ExprUnit}, item::ExprUnit)
    (item.state == :done || item.state == :processing) && return buffer
    item.state = :processing
    for dep in item.deps
        haskey(expr_dict, dep) || continue
        dump_to_buffer!(buffer, expr_dict, buffer[dep])
    end
    append!(buffer, item.items)
    item.state = :done
    return buffer
end

function dump_to_buffer(expr_dict::OrderedDict{Symbol,ExprUnit})
    buffer = []
    for item in values(expr_dict)
        item.state == :done && continue
        dump_to_buffer!(buffer, expr_dict, item)
    end
    return buffer
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

name_anon() = "ANONYMOUS_"*string((context::WrapContext).anon_count += 1)
name_safe(cursor_name::AbstractString) = (cursor_name in RESERVED_WORDS) ? "_"*cursor_name : cursor_name
symbol_safe(cursor_name::AbstractString) = Symbol(name_safe(cursor_name))
