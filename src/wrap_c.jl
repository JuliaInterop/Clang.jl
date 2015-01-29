################################################################################
# Julia C wrapper generator using libclang from the LLVM project               #
################################################################################

module wrap_c
    version = v"0.0.0"

using Clang.cindex
using DataStructures
using Compat

export wrap_c_headers
export WrapContext

# Reserved Julia identifiers will be prepended with "_"
reserved_words = [ "abstract", "baremodule", "begin", "bitstype", "break", "catch", "ccall",
                   "const", "continue", "do", "else", "elseif", "end", "export", "finally",
                   "for", "function", "global", "if", "immutable", "import", "importall", "in",
                   "let", "local", "macro", "module", "quote", "return", "try", "type",
                   "typealias", "using", "while"]

# These argument types are unsupported
reserved_argtypes = ["va_list"]

# These argument types will be untyped in the Julia signature
untyped_argtypes = [IncompleteArray]

### InternalOptions
type InternalOptions
    wrap_structs::Bool
    immutable_structs::Bool
end
InternalOptions() = InternalOptions(true, false)

type ExprUnit
    items::Array{Any}
    deps::OrderedSet{Symbol}
    state::Symbol
end

immutable Poisoned
end

ExprUnit() = ExprUnit(Any[], OrderedSet{Symbol}(), :new)
ExprUnit(e::Union(Expr,Symbol,ASCIIString,Poisoned), deps=Any[]; state::Symbol=:new) = ExprUnit(Any[e], OrderedSet{Symbol}([target_type(dep) for dep in deps]...), state)
ExprUnit(a::Array, deps=Any[]; state::Symbol=:new) = ExprUnit(a, OrderedSet{Symbol}([target_type(dep) for dep in deps]...), state)

### WrapContext
# stores shared information about the wrapping session
type WrapContext
    index::cindex.CXIndex
    headers::Array{ASCIIString,1}
    output_file::ASCIIString
    common_file::ASCIIString
    clang_includes::Array{ASCIIString,1}         # clang include paths
    clang_args::Array{ASCIIString,1}             # additional {"-Arg", "value"} pairs for clang
    header_wrapped::Function                     # called to determine header inclusion status
                                                 #   (top_header, cursor_header) -> Bool
    header_library::Function                     # called to determine shared library for given header
                                                 #   (header_name) -> library_name::String
    header_outfile::Function                     # called to determine output file group for given header
                                                 #   (header_name) -> output_file::String
    cursor_wrapped::Function                     # called to determine cursor inclusion status
                                                 #   (cursor_name, cursor) -> Bool
    common_buf::OrderedDict{Symbol, ExprUnit}    # output buffer for common items: typedefs, enums, etc.
    empty_structs::Set{ASCIIString}
    output_bufs::DefaultOrderedDict{ASCIIString, Array{Any}}
    options::InternalOptions
    anon_count::Int
    rewriter::Function
end

### Convenience function to initialize wrapping context with defaults
init(;args...) = init(ASCIIString[]; args...)
function init(;
            headers                         = ASCIIString[],
            index                           = None,
            output_file::ASCIIString        = "",
            common_file::ASCIIString        = "",
            output_dir::ASCIIString         = "",
            clang_args::Array{ASCIIString,1}
                                            = ASCIIString[],
            clang_includes::Array{ASCIIString,1}
                                            = ASCIIString[],
            clang_diagnostics::Bool         = true,
            header_wrapped                  = (header, cursorname) -> true,
            header_library                  = None,
            header_outputfile               = None,
            cursor_wrapped                  = (cursorname, cursor) -> true,
            options                         = InternalOptions(),
            rewriter                        = x -> x)

    # Set up some optional args if they are not explicitly passed.

    (index == None)         && ( index = cindex.idx_create(0, (clang_diagnostics ? 1 : 0)) )

    if (output_file == "" && header_outputfile == None)
        header_outputfile = x->joinpath(output_dir, strip(splitext(basename(x))[1]) * ".jl")
    end

    (common_file == "")    && ( common_file = output_file )
    common_file = joinpath(output_dir, common_file)

    if (header_library == None)
        header_library = x->strip(splitext(basename(x))[1])
    elseif isa(header_library, ASCIIString)
        libname = copy(header_library)
        header_library = x->libname
    end
    if (header_outputfile == None)
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
                                 OrderedDict(Symbol, ExprUnit),
                                 Set{ASCIIString}(),
                                 DefaultOrderedDict(ASCIIString, Array{Any}, ()->Any[]),
                                 options,
                                 0,
                                 rewriter)
    return context
end

###############################################################################
#
# Mapping from libclang types to Julia types
#
#   This is primarily used with CXTypeKind enums (aka: cindex.TypeKind)
#   but can also be used to map arbitrary type names to corresponding
#   Julia entities, for example "size_t" -> :Csize_t
#
##############################################################################
cl_to_jl = @compat Dict{Any,Any}(
    cindex.VoidType         => :Void,
    cindex.BoolType         => :Bool,
    cindex.Char_U           => :Uint8,
    cindex.UChar            => :Cuchar,
    cindex.Char16           => :Uint16,
    cindex.Char32           => :Uint32,
    cindex.UShort           => :Uint16,
    cindex.UInt             => :Uint32,
    cindex.ULong            => :Culong,
    cindex.ULongLong        => :Culonglong,
    cindex.Char_S           => :Uint8,
    cindex.SChar            => :Uint8,
    cindex.WChar            => :Char,
    cindex.Short            => :Int16,
    cindex.IntType          => :Cint,
    cindex.Long             => :Clong,
    cindex.LongLong         => :Clonglong,
    cindex.Float            => :Cfloat,
    cindex.Double           => :Cdouble,
    cindex.LongDouble       => :Float64,
    cindex.Enum             => :Cint,
    cindex.NullPtr          => :C_NULL,
    cindex.UInt128          => :Uint128,
    cindex.FirstBuiltin     => :Void,
    :size_t                 => :Csize_t,
    :ptrdiff_t              => :Cptrdiff_t,
    :uint64_t               => :Uint64,
    :uint32_t               => :Uint32,
    :uint16_t               => :Uint16,
    :uint8_t                => :Uint8,
    :int64_t                => :Int64,
    :int32_t                => :Int32,
    :int16_t                => :Int16,
    :int8_t                 => :Int8
    )

int_conversion = @compat Dict{Any,Any}(
    :Cint   => int32,
    :Cuint  => uint32,
    :Uint64 => uint64,
    :Uint32 => uint32,
    :Uint16 => uint16,
    :Uint8  => uint8,
    :Int64  => int64,
    :Int32  => int32,
    :Int16  => int16,
    :Int8   => int8
    )


################################################################################
#
# libclang objects to Julia representation
#
# each repr_jl function takes one or more CLCursor or CLType objects,
# and returns the appropriate representation.
#
################################################################################

function repr_jl(t::Union(cindex.Record, cindex.Typedef))
    tname = symbol(spelling(cindex.getTypeDeclaration(t)))
    return get(cl_to_jl, tname, tname)
end

function repr_jl(t::TypeRef)
    reftype = cindex.getCursorReferenced(t)
    refdef = cindex.getCursorDefinition(reftype)
    if isa(refdef, cindex.InvalidFile) ||
       isa(refdef, cindex.FirstInvalid) ||
       isa(refdef, cindex.Invalid)
        return :Void
    else
        return symbol(spelling(reftype))
    end
end

function repr_jl(ptr::cindex.Pointer)
    ptee = pointee_type(ptr)
    Expr(:curly, :Ptr, repr_jl(ptee))
end

function repr_jl(parm::cindex.ParmDecl)
    return repr_jl(cu_type(parm))
end

function repr_jl(unxp::Unexposed)
    r = spelling(cindex.getTypeDeclaration(unxp))
    r == "" ? :Void : symbol(r)
end

function repr_jl(t::ConstantArray)
    # For ConstantArray declarations, we make an immutable
    # array with that many members of the appropriate type.

    # Override pointer representation so pointee type is not written
    repr_short(t::CLType) = isa(t, Pointer) ? "Ptr" : repr_jl(t)

    # Grab the WrapContext in order to add bitstype
    global context::WrapContext

    arrsize = cindex.getArraySize(t)
    eltype = cindex.getArrayElementType(t)
    typename = string("Array_", arrsize, "_", repr_short(eltype))
    typesym = symbol(typename)

    if !(typesym in keys(context.common_buf))
        b = Expr(:block)
        e = Expr(:type, false, symbol(typename), b)
        repr = repr_jl(eltype)
        for i = 1:arrsize
            push!(b.args, Expr(:(::), symbol("d$i"), repr))
        end

        # Create a zero function for this type
        b = :($(symbol(typename))(fill(zero($repr), $arrsize)...))
        zero_call = :(zero(::Type{$(symbol(typename))}) = $b)

        context.common_buf[typesym] = ExprUnit(Any[e, zero_call])
    end

    return typesym
end

function repr_jl(t::IncompleteArray)
    eltype = cindex.getArrayElementType(t)
    Expr(:curly, :Ptr, repr_jl(eltype))
end

function repr_jl(t::UnionType)
    tdecl = cindex.getTypeDeclaration(t)
    maxelem = largestfield(tdecl)
    return repr_jl(maxelem)
end

function repr_jl(arg::cindex.CLType)
    rep = get(cl_to_jl, typeof(arg), nothing)
    rep == nothing && error("No CLType translation available for: ", arg)
    return rep
end

target_type(s::Symbol) = s
function target_type(e::Expr)
    if e.head == :curly && e.args[1] == :Ptr
        return target_type(e.args[2])
    else
        error("target_type: don't know how to handle $e")
    end
end
target_type(q) = error("target_type: don't know how to handle $q")

###############################################################################
# Get field decl sizes
#   - used for hacky union inclusion: we find the largest union field and
#     declare a block of bytes to match.
###############################################################################

typesize(t::CLType) = sizeof(eval(cl_to_jl[typeof(t)]))
typesize(t::Record) = begin warn("  incorrect typesize for Record field"); 0 end
typesize(t::Unexposed) = begin warn("  incorrect typesize for Unexposed field"); 0 end
typesize(t::ConstantArray) = cindex.getArraySize(t)
typesize(t::TypedefDecl) = typesize(cindex.getTypedefDeclUnderlyingType(t))
typesize(t::Typedef) = typesize(cindex.getTypeDeclaration(t))
typesize(t::Invalid) = begin warn("  incorrect typesize for Invalid field"); 0 end

function largestfield(cu::UnionDecl)
    maxsize,maxelem = 0,0
    fields = children(cu)
    for i in 1:length(fields)
        maxelem = ( (maxsize > (typesize(cu_type(fields[i])))) ? maxelem : i )
    end
    fields[maxelem]
end

function fieldsize(cu::FieldDecl)
    fieldsize(children(cu)[1])
end

################################################################################
# Handle function declarations
################################################################################

function wrap(context::WrapContext, buf::Array, func_decl::FunctionDecl, libname)
    func_type = cindex.cu_type(func_decl)
    if cindex.isFunctionTypeVariadic(func_type) == 1
        # skip vararg functions
        return
    end

    funcname = symbol(spelling(func_decl))
    ret_type = repr_jl(return_type(func_decl))

    args = cindex.function_args(func_decl)

    arg_types = [cindex.getArgType(func_type, uint32(i)) for i in 0:length(args)-1]
    arg_reps = [repr_jl(x) for x in arg_types]

    # check whether any argument types are blocked
    for arg_t in arg_types
        if spelling(arg_t) in reserved_argtypes
            warning("Skipping $(name(func_decl)) due to unsupported argument: $(name(arg_t))")
            return
        end
    end

    # Handle unnamed args and convert names to symbols
    arg_count = 0
    arg_names = convert(Vector{Symbol},
                        map(x-> symbol(begin
                            nm = name_safe(cindex.name(x))
                            nm != "" ? nm : "arg"*string(arg_count+=1)
                        end), args))

    sig = efunsig(funcname, arg_names, arg_reps)
    body = eccall(funcname, symbol(libname), ret_type, arg_names, arg_reps)
    e = Expr(:function, sig, Expr(:block, body))

    push!(buf, e)
end

################################################################################
# Handle all other declarations
################################################################################

function wrap(context::WrapContext, expr_buf::OrderedDict, cursor::EnumDecl; usename="")
    if (usename == "" && (usename = name(cursor)) == "")
        usename = name_anon()
    end
    enumname = usename

    buf = Any[]
    enum_exprs = ExprUnit(buf)
    expr_buf[symbol_safe(enumname)] = enum_exprs

    push!(buf, "# begin enum $enumname")
    enumtype = repr_jl(cindex.getEnumDeclIntegerType(cursor))
    _int = int_conversion[enumtype]
    push!(buf, :(typealias $(symbol(enumname)) $enumtype))
    for enumitem in children(cursor)
        cur_name = cindex.spelling(enumitem)
        if (length(cur_name) < 1) continue end
        cur_sym = symbol_safe(cur_name)
        push!(buf, :(const $cur_sym = $_int($(value(enumitem)))))
        expr_buf[cur_sym] = enum_exprs
    end
    push!(buf, "# end enum $enumname")

end

function wrap(context::WrapContext, expr_buf::OrderedDict, sd::StructDecl; usename = "")
    !context.options.wrap_structs && return

    if (usename == "" && (usename = name(sd)) == "")
        warn("Skipping unnamed StructDecl")
        return
    end
    usesym = symbol(usename)

    struct_fields = children(sd)

    # Generate type declaration
    b = Expr(:block)
    e = Expr(:type, !context.options.immutable_structs, usesym, b)
    deps = OrderedSet{Symbol}()
    for cu in struct_fields
        cur_name = spelling(cu)
        if (isa(cu, StructDecl) || isa(cu, UnionDecl))
            continue
        elseif !(isa(cu, FieldDecl) || isa(cu, TypeRef))
            expr_buf[usesym] = ExprUnit(Poisoned())
            warn("Skipping struct: \"$usename\" due to unsupported field: $cur_name")
            return
        elseif (length(cur_name) < 1)
            error("Unnamed struct member in: $usename ... cursor: ", string(cu)) 
        end

        repr = repr_jl(cu_type(cu))
        push!(b.args, Expr(:(::), symbol_safe(cur_name), repr))
        push!(deps, target_type(repr))
    end

    # Check for a previous forward ordering
    if !(usesym in keys(expr_buf)) || (expr_buf[usesym].state == :empty)
        if length(struct_fields) > 0
            expr_buf[usesym] = ExprUnit(e, deps)
        else
            # Possible forward definition
            expr_buf[usesym] = ExprUnit(e, deps, state=:empty)
        end
    end
    return
end

function wrap(context::WrapContext, expr_buf::OrderedDict, ud::UnionDecl; usename = "")
    if (usename == "" && (usename = name(ud)) == "")
        warn("Skipping unnamed UnionDecl")
        return
    end

    b = Expr(:block)
    e = Expr(:type, !context.options.immutable_structs, symbol(usename), b)
    max_cu = largestfield(ud)
    cur_sym = symbol("_"*usename)
    target = repr_jl(cu_type(max_cu))
    push!(b.args, Expr(:(::), cur_sym, target))

    # TODO: add other dependencies
    expr_buf[cur_sym] = ExprUnit(e, Any[target])

    return
end

function efunsig(name::Symbol, args::Vector{Symbol}, types)
    x = Any[ Expr(:(::), a, t) for (a,t) in zip(args,types) ]
    Expr(:call, name, x...)
end

function eccall(funcname::Symbol, libname::Symbol, rtype, args, types)
    Expr(:ccall,
         Expr(:tuple, QuoteNode(funcname), libname),
         rtype,
         Expr(:tuple, types...),
         args...)
end

function wrap(context::WrapContext, expr_buf::OrderedDict, tdecl::TypedefDecl; usename="")
    cursor_type = cindex.cu_type(tdecl)
    td_type = cindex.getTypedefDeclUnderlyingType(tdecl)

    if isa(td_type, Unexposed)
        tdunxp = children(tdecl)[1]
        if isa(tdunxp, TypeRef)
            td_type = tdunxp
        else
            wrap(context, expr_buf, tdunxp; usename=name(tdecl))
            return # TODO.. ugly flow
        end
    elseif isa(td_type, FunctionProto)
        return string("# Skipping Typedef: FunctionProto ", spelling(tdecl))
    end

    td_sym = symbol(spelling(tdecl))
    td_target = repr_jl(td_type)
    if !haskey(expr_buf, td_sym)
        expr_buf[td_sym] = ExprUnit(Expr(:typealias, td_sym, td_target), Any[td_target])
    end
end

################################################################################
# Handler for macro definitions
################################################################################
#
# For handling of #define'd constants, allows basic expressions
# but bails out quickly.

function handle_macro_exprn(tokens::TokenList, pos::Int)
    function trans(tok)
        ops = ["+" "-" "*" ">>" "<<" "/" "\\" "%" "|" "||" "^" "&" "&&"]
        if (isa(tok, cindex.Literal) || 
            (isa(tok,cindex.Identifier))) return 0
        elseif (isa(tok, cindex.Punctuation) && tok.text in ops) return 1
        else return -1
        end
    end

    # normalize literal with a size suffix
    function literally(tok)
        # note: put multi-character first, or it will break out too soon for those!
        literalsuffixes = ["ULL", "Ull", "uLL", "ull", "LLU", "LLu", "llU", "llu",
                           "LL", "ll", "UL", "Ul", "uL", "ul", "LU", "Lu", "lU", "lu",
                           "U", "u", "L", "l", "F", "f"]
        txt = tok.text
        if isa(tok,cindex.Identifier) || isa(tok,cindex.Punctuation)
            # pass
        elseif isa(tok,cindex.Literal)
            txt = strip(tok.text)
            for sfx in literalsuffixes
                if endswith(txt, sfx)
                    txt = txt[1:end-length(sfx)]
                    break
                end
            end
        end
        return txt
    end

    # check whether identifiers and literals alternate
    # with punctuation
    exprn = ""
    prev = 1 >> trans(tokens[pos])
    for pos = pos:length(tokens)
        tok = tokens[pos]
        state = trans(tok)
        if ( state $ prev  == 1)
            prev = state
        else
            break
        end 
        exprn = exprn * literally(tok)
    end
    return (exprn,pos)
end

# TODO: This really returns many more symbols than we want,
# Functionally, it shouldn't matter, but eventually, we
# might want something more sophisticated.
# (Check: Does this functionality already exist elsewhere?)
get_symbols(s) = Any[]
get_symbols(s::Symbol) = Any[s]
get_symbols(e::Expr) = vcat(get_symbols(e.head), get_symbols(e.args))
get_symbols(xs::Array) = reduce(vcat, [get_symbols(x) for x in xs])

function wrap(context::WrapContext, expr_buf::OrderedDict, md::cindex.MacroDefinition)
    tokens = tokenize(md)
    # Skip any empty definitions
    tokens.size < 2 && return
    startswith(name(md), "_") && return

    pos = 1; exprn = ""
    if tokens[2].text == "("
        exprn,pos = handle_macro_exprn(tokens, 3)
        if (pos != endof(tokens) || tokens[pos].text != ")")
            mdef_str = join([c.text for c in tokens], " ")
            expr_buf[symbol(mdef_str)] = ExprUnit(string("# Skipping MacroDefinition: ", mdef_str))
            return
        end
        exprn = "(" * exprn * ")"
    else
        (exprn,pos) = handle_macro_exprn(tokens, 2)
        if pos != endof(tokens)
            mdef_str = join([c.text for c in tokens], " ")
            expr_buf[symbol(mdef_str)] = ExprUnit(string("# Skipping MacroDefinition: ", mdef_str))
            return
        end
    end

    # Occasionally, skipped definitions slip through
    exprn == "" && return

    use_sym = symbol_safe(tokens[1].text)
    target = parse(exprn)
    e = Expr(:const, Expr(:(=), use_sym, target))

    deps = get_symbols(target)
    expr_buf[use_sym] = ExprUnit(e, deps)
end

# Does this actually occur in header files???
function wrap(context::WrapContext, expr_buf::OrderedDict, cursor::TypeRef; usename="")
    usename == "" && (usename = name(cursor))
    error("Found typeref: ", cursor)
    println("Printing typeref: ", cursor)
    usesym = symbol(usename)
    expr_buf[usesym] = ExprUnit(usesym)
end

function wrap(context::WrapContext, buf, cursor; usename="")
    warn("Not wrapping $(typeof(cursor))  $usename $(name(cursor))")
end


################################################################################
# Wrapping driver
################################################################################

# Any failed cursor in the loop below is put in this global for debugging
debug_cursors = CLCursor[]

function wrap_header(wc::WrapContext, topcu::CLCursor, top_hdr, obuf::Array)
    println("WRAPPING HEADER: $top_hdr")

    topcl = children(topcu)

    # Loop over all of the child cursors and wrap them, if appropriate.
    for i=1:topcl.size
        cursor = topcl[i]
        cursor_hdr = cu_file(cursor)
        cursor_name = name(cursor)

        # what should be wrapped:
        #    1. always wrap things in the current top header (ie not includes)
        #    2. wrap things that are in other includes
        #    3. wrap includes if wc.header_wrapped(header, cursor_name) == True
        if cursor_hdr == top_hdr
            # pass
        elseif !wc.header_wrapped(top_hdr, cursor_hdr)
           continue
        end

        if startswith(cursor_name, "__")                    ||      # skip compiler definitions
           (cursor_name in keys(wc.common_buf) &&
            !(cursor_name in keys(wc.empty_structs)))       ||      # already wrapped
           !(cursor_hdr in wc.headers)                      || 
           !wc.cursor_wrapped(cursor_name, cursor)                  # client callback

            continue
        end

        try
            if (isa(cursor, FunctionDecl))
                wrap(wc, obuf, cursor, wc.header_library(cu_file(cursor)))
            elseif !isa(cursor, TypeRef)
                wrap(wc, wc.common_buf, cursor)
            else
                continue
            end
        catch err
            push!(debug_cursors::Array{CLCursor,1}, cursor)
            info("Error thrown. Last cursor available in Clang.wrap_c.debug_cursors")
            rethrow(err)
        end
    end

    cindex.cl_dispose(topcl)
end

function parse_c_headers(wc::WrapContext)
    parsed = Dict{ASCIIString, CLCursor}()

    # Parse the headers
    for header in unique(wc.headers)
        topcu = cindex.parse_header(header; 
                                    index = wc.index,
                                    args  = wc.clang_args,
                                    includes = wc.clang_includes,
                                    flags = TranslationUnit_Flags.DetailedPreprocessingRecord |
                                    TranslationUnit_Flags.SkipFunctionBodies)
        parsed[header] = topcu
    end
    return parsed
end

function sort_includes(wc::WrapContext, parsed)
    includes = mapreduce(x->search(parsed[x], InclusionDirective), append!, keys(parsed))
    header_paths = unique(map(x->cindex.getIncludedFile(x), includes))
    return unique([filter(x -> x in header_paths, wc.headers), wc.headers])
end

################################################################################
# Wrapping driver
################################################################################

# Pretty-print a buffer of expressions (and comments) to an output stream
# Adds blank lines at appropriate places for readability
function print_buffer(ostrm, obuf)

    state = :comment
    in_enum = false

    for e in obuf
        isa(e, Poisoned) && continue
        prev_state = state
        if state != :enum
            state = (isa(e, String) ? :string :
                     isa(e, Expr)   ? e.head :
                     error("output: can't handle type $(typeof(e))"))
        end

        if state == :string
            if startswith(e, "# begin enum")
                state = :enum
                println(ostrm)
            elseif startswith(e, "# Skipping")
                state = :skipping
            end
        end

        if state != :enum
            if ((state != prev_state && prev_state != :string) ||
                (state == prev_state && (state == :function ||
                                         state == :type)))
                println(ostrm)
            end
        end

        println(ostrm, e)

        if state == :enum && isa(e, String) && startswith(e, "# end enum")
            state = :end_enum
        end
    end
end

function dump_to_buf!(buf::Array, expr_buf::OrderedDict{Symbol, ExprUnit}, item::ExprUnit)
    (item.state == :done || item.state == :processing) && return
    item.state = :processing

    for dep in item.deps
        (dep_expr = get(expr_buf, dep, nothing)) == nothing && continue
        dump_to_buf!(buf, expr_buf, dep_expr)
    end

    append!(buf, item.items)
    item.state = :done
end


function dump_to_buf(expr_buf::OrderedDict{Symbol, ExprUnit})
    buf = Any[]
    for item in values(expr_buf)
        item.state == :done && continue
        dump_to_buf!(buf, expr_buf, item)
    end
    buf
end

function Base.run(wc::WrapContext)
    # Parse headers
    parsed = parse_c_headers(wc)
    # Sort includes by requirement order
    wc.headers = sort_includes(wc, parsed)

    # Helper to store file handles 
    filehandles = Dict{ASCIIString,IOStream}()
    getfile(f) = (f in keys(filehandles)) ? filehandles[f] : (filehandles[f] = open(f, "w"))

    for hfile in wc.headers
        outfile = wc.header_outfile(hfile)
        obuf = wc.output_bufs[hfile]

        # Extract header to Expr[] array
        wrap_header(wc, parsed[hfile], hfile, obuf)

        # Apply user-supplied transformation
        wc.output_bufs[hfile] = wc.rewriter(obuf)

        # Debug
        println("writing $(outfile)")

        # Write output 
        ostrm = getfile(outfile)
        println(ostrm, "# Julia wrapper for header: $hfile")
        println(ostrm, "# Automatically generated using Clang.jl wrap_c, version $version\n")

        print_buffer(ostrm, wc.output_bufs[hfile])
    end

    common_buf = dump_to_buf(wc.common_buf)

    # Apply user-supplied transformation
    common_buf = wc.rewriter(common_buf)

    # Write "common" definitions: types, typealiases, etc.
    print_buffer(open(wc.common_file, "w"), common_buf)

    map(close, values(filehandles))
end

# Deprecated interface
@deprecate wrap_c_headers(wc::WrapContext, headers)   (wc.headers = headers; run(wc))

###############################################################################
# Utilities
###############################################################################

function name_anon()
    global context::WrapContext
    "ANONYMOUS_"*string(context.anon_count += 1)
end

function name_safe(cursor_name::String)
    return (cursor_name in reserved_words) ? "_"*cursor_name : cursor_name
end
symbol_safe(cursor_name::String) = symbol(name_safe(cursor_name))

###############################################################################

end # module wrap_c
