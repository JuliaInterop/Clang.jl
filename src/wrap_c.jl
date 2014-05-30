################################################################################
# Julia C wrapper generator using libclang from the LLVM project               #
################################################################################

module wrap_c
    version = v"0.0.0"

using Clang.cindex
using DataStructures

export wrap_c_headers
export WrapContext

### Reserved Julia identifiers to prepend with "_"
reserved_words = ["abstract", "baremodule", "begin", "bitstype", "break", "catch", "ccall",
                   "const", "continue", "do", "else", "elseif", "end", "export", "finally",
                   "for", "function", "global", "if", "immutable", "import", "importall",
                   "let", "local", "macro", "module", "quote", "return", "try", "type",
                   "typealias", "using", "while"]

reserved_argtypes = ["va_list"]
untyped_argtypes = [IncompleteArray]

function name_safe(c::CLCursor)
    cur_name = name(c)
    return (cur_name in reserved_words) ? "_"*cur_name : cur_name
end
symbol_safe(c::CLCursor) = symbol(name_safe(c))

### InternalOptions
type InternalOptions
    wrap_structs::Bool
    immutable_structs::Bool
end
InternalOptions() = InternalOptions(true, false)

### WrapContext
# stores shared information about the wrapping session
type WrapContext
    index::cindex.CXIndex
    output_file::ASCIIString
    common_file::ASCIIString
    clang_includes::Array{ASCIIString,1}         # clang include paths
    clang_args::Array{ASCIIString,1}             # additional {"-Arg", "value"} pairs for clang
    header_wrapped::Function                     # called to determine header inclusion status
    header_library::Function                     # called to determine shared library for given header
    header_outfile::Function                     # called to determine output file group for given header
    cursor_wrapped::Function                     # called to determine cursor inclusion statusk
    common_buf::Array                            # output buffer for common items: typedefs, enums, etc.
    cache_wrapped::Set{ASCIIString}
    output_bufs::DefaultOrderedDict{ASCIIString, Array{Any}}
    options::InternalOptions
    anon_count::Int
    func_rewriter::Function
    type_rewriter::Function
end

### Convenience function to initialize wrapping context with defaults
function init(;
            index                           = None,
            output_file::ASCIIString        = "",
            common_file::ASCIIString        = "",
            clang_args::Array{ASCIIString,1}
                                            = ASCIIString[],
            clang_includes::Array{ASCIIString,1}
                                            = ASCIIString[],
            clang_diagnostics::Bool         = true,
            header_wrapped                  = (header, cursorname) -> true,
            header_library                  = None,
            header_outputfile               = None,
            cursor_wrapped                  = (cursorname, cursor) -> true,
            func_rewriter                   = x -> x,
            type_rewriter                   = x -> x)

    # Set up some optional args if they are not explicitly passed.

    (index == None)         && ( index = cindex.idx_create(0, (clang_diagnostics ? 1 : 0)) )

    if (output_file == "" && header_outputfile == None)
        header_outputfile = x->joinpath(strip(splitext(basename(x))[1]) * ".jl")
    end

    (common_file == "")    && ( common_file = output_file )
    
    if (header_library == None)
        header_library = x->strip(splitext(basename(x))[1])
    elseif isa(header_library, ASCIIString)
        header_library = x->header_library
    end
    if (header_outputfile == None)
        header_outputfile = x->output_file
    end

    # Instantiate and return the WrapContext
    global context = WrapContext(index,
                                 output_file,
                                 common_file,
                                 clang_includes,
                                 clang_args,
                                 header_wrapped,
                                 header_library,
                                 header_outputfile,
                                 cursor_wrapped,
                                 {},
                                 Set{ASCIIString}(),
                                 DefaultOrderedDict(ASCIIString, Array{Any}, ()->{}),
                                 InternalOptions(),
                                 0,
                                 func_rewriter,
                                 type_rewriter)
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
cl_to_jl = {
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
    }

################################################################################
#
# libclang objects to Julia representation
#
# each repr_jl function takes one or more CLCursor or CLType objects,
# and returns the appropriate string representation.
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
    buf = context.common_buf

    arrsize = cindex.getArraySize(t)
    eltype = cindex.getArrayElementType(t)
    typename = string("Array_", arrsize, "_", repr_short(eltype))
    if !(typename in context.cache_wrapped)
        b = Expr(:block)
        e = Expr(:type, false, symbol(typename), b)
        repr = repr_jl(eltype)
        for i = 1:arrsize
            push!(b.args, Expr(:(::), symbol("d$i"), repr))
        end
        push!(buf, e)
    end
    push!(context.cache_wrapped, typename)
    return symbol(typename)
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
# Handle declarations
################################################################################

function wrap(context::WrapContext, buf::Array, cursor::EnumDecl; usename="")
    if (usename == "" && (usename = name(cursor)) == "")
        usename = name_anon()
    end
    enumname = usename
    push!(buf, "# begin enum $enumname")
    push!(buf, Expr(:typealias, symbol(enumname), repr_jl(cindex.getEnumDeclIntegerType(cursor))))
    for enumitem in children(cursor)
        cur_name = cindex.spelling(enumitem)
        if (length(cur_name) < 1) continue end
        push!(buf, Expr(:const, Expr(:(=), symbol(cur_name), value(enumitem))))
    end
    push!(buf, "# end enum $enumname")
end

function wrap(context::WrapContext, buf::Array, sd::StructDecl; usename = "")
    !context.options.wrap_structs && return

    if (usename == "" && (usename = name(sd)) == "")
        warn("Skipping unnamed StructDecl")
        return
    end

    ccl = children(sd)
    if (length(ccl) < 1)
        warn("Skipping empty struct: \"$usename\"")
        return
    end

    # Generate type declaration
    b = Expr(:block)
    e = Expr(:type, !context.options.immutable_structs, symbol(usename), b)
    for cu in ccl
        cur_name = spelling(cu)
        if (isa(cu, StructDecl) || isa(cu, UnionDecl))
            continue
        elseif !(isa(cu, FieldDecl) || isa(cu, TypeRef))
            warn("Skipping struct: \"$usename\" due to unsupported field: $cur_name")
            return
        elseif (length(cur_name) < 1)
            error("Unnamed struct member in: $usename ... cursor: ", string(cu)) 
        end
        if ((cur_name in reserved_words)) cur_name = "_"*cur_name end

        repr = repr_jl(cu_type(cu))
        push!(b.args, Expr(:(::), symbol(cur_name), repr))
    end

    # apply user transformation
    e = context.type_rewriter(e)

    push!(buf, e)

    push!(context.cache_wrapped, usename)
end

function wrap(context::WrapContext, buf::Array, ud::UnionDecl; usename = "")
    if (usename == "" && (usename = name(ud)) == "")
        warn("Skipping unnamed UnionDecl")
        return
    end
    
    b = Expr(:block)
    e = Expr(:type, !context.options.immutable_structs, symbol(usename), b)
    max_cu = largestfield(ud)
    push!(b.args, Expr(:(::), symbol("_"*usename), repr_jl(cu_type(max_cu))))
    
    push!(buf, e)

    push!(context.cache_wrapped, usename)
end

function efunsig(name::Symbol, args::Vector{Symbol}, types)
    x = { Expr(:(::), a, t) for (a,t) in zip(args,types) }
    Expr(:call, name, x...)
end

function eccall(funcname::Symbol, libname::Symbol, rtype, types, args)
    Expr(:ccall,
         Expr(:tuple, QuoteNode(funcname), QuoteNode(libname)),
         rtype,
         Expr(:tuple, types...),
         args...)
end

function wrap(context::WrapContext, buf::Array, funcdecl::FunctionDecl, libname)
    ftype = cindex.cu_type(funcdecl)
    if cindex.isFunctionTypeVariadic(ftype) == 1
        # skip vararg functions
        return
    end

    funcname = symbol(spelling(funcdecl))
    ret_type = repr_jl(return_type(funcdecl))

    args = cindex.function_args(funcdecl)
   
    functy = cu_type(funcdecl)
    arg_types = [cindex.getArgType(functy, uint32(i)) for i in 0:length(args)-1]
    arg_reps = [repr_jl(x) for x in arg_types]

    # check whether any argument types are blocked
    for arg in arg_types
        if spelling(arg) in reserved_argtypes
            return
        end
    end

    args = convert(Array{Symbol,1}, map(symbol_safe, args))
    sig = efunsig(funcname, args, arg_reps)
    body = eccall(funcname, symbol(libname), ret_type, arg_reps, args)
    e = Expr(:function, sig, Expr(:block, body))

    # apply user transformation
    e = context.func_rewriter(e)

    push!(buf, e)
end

function wrap(context::WrapContext, buf::Array, tdecl::TypedefDecl; usename="")
    cursor_type = cindex.cu_type(tdecl)
    td_type = cindex.getTypedefDeclUnderlyingType(tdecl)
    
    if isa(td_type, Unexposed)
        tdunxp = children(tdecl)[1]
        if isa(tdunxp, TypeRef)
            td_type = tdunxp
        else
            wrap(context, buf, tdunxp; usename=name(tdecl))
            return # TODO.. ugly flow
        end
    elseif isa(td_type, FunctionProto)
        return string("# Skipping Typedef: FunctionProto", spelling(tdecl))
    end

    push!(buf, Expr(:typealias, symbol(spelling(tdecl)), repr_jl(td_type)))
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

function wrap(context::WrapContext, buf::Array, md::cindex.MacroDefinition)
    tokens = tokenize(md)
    # Skip any empty definitions
    if(tokens.size < 2) return end
    if(beginswith(name(md), "_")) return end

    pos = 1; exprn = ""
    if(tokens[2].text == "(")
        exprn,pos = handle_macro_exprn(tokens, 3)
        if (pos != endof(tokens) || tokens[pos].text != ")")
            push!(buf, string("# Skipping MacroDefinition: ", join([c.text for c in tokens], " ")))
            return
        end
        exprn = "(" * exprn * ")"
    else
        (exprn,pos) = handle_macro_exprn(tokens, 2)
        if (pos != endof(tokens))
            push!(buf, string("# Skipping MacroDefinition: ", join([c.text for c in tokens], " ")))
            return
        end
    end
    e = Expr(:const, Expr(:(=), symbol(tokens[1].text), parse(exprn)))
    push!(buf, e)
end

# Does this actually occur in header files???
function wrap(context::WrapContext, buf::Array, cursor::TypeRef; usename="")
    usename == "" && (usename = name(cursor))
    println("Printing typeref: ", cursor)
    push!(buf, symbol(usename))
end

function wrap(context::WrapContext, buf::Array, cursor; usename="")
    warn("Not wrapping $(typeof(cursor))  $usename $(name(cursor))")
end


################################################################################
# Wrapping driver
################################################################################

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
        #    2. wrap includes if wc.header_wrapped(header, cursor_name) == True
        if cursor_hdr == top_hdr
            # pass
        elseif !wc.header_wrapped(top_hdr, cursor_hdr)
           continue
        end

        if beginswith(cursor_name, "__") || # skip compiler definitions
           cursor_name in wc.cache_wrapped || # already been wrapped
           !wc.cursor_wrapped(cursor_name, cursor)
            continue
        end

        if (isa(cursor, FunctionDecl))
            wrap(wc, obuf, cursor, wc.header_library(cu_file(cursor)))
        elseif !isa(cursor, TypeRef)
            wrap(wc, wc.common_buf, cursor)
        else
            continue
        end
    end

    cindex.cl_dispose(topcl)
end


################################################################################
# Wrapping driver
################################################################################

function wrap_c_headers(wc::WrapContext, headers)
    extract_c_headers(wc, headers)
    for hfile in headers
        outfile = wc.header_outfile(hfile)
        println("writing $outfile")
        open(outfile, "w") do ostrm
            println(ostrm, "# Julia wrapper for header: $hfile")
            println(ostrm, "# Automatically generated using Clang.jl wrap_c, version $version\n")
            println(ostrm)
            for e in wc.output_bufs[hfile]
                println(ostrm, e)
            end
        end 
    end

    buf = IOBuffer()
    for e in wc.common_buf
        println(buf, e)
    end

    open(wc.common_file, "w") do strm
        print(strm, takebuf_string(buf))
    end
end

function extract_c_headers(wc::WrapContext, headers)
    # Check headers!
    for h in headers
        if !isfile(h)
            error("Header file: ", h, " cannot be found")
        end
    end
    for d in wc.clang_includes
        if !isdir(d)
            error("Include file: ", d, " cannot be found")
        end
    end

    # Generate the wrappings
    for hfile in headers
        obuf = wc.output_bufs[hfile]
        topcu = cindex.parse_header(hfile; 
                                    index = wc.index,
                                    args  = wc.clang_args,
                                    includes = wc.clang_includes,
                                    flags = TranslationUnit_Flags.DetailedPreprocessingRecord |
                                    TranslationUnit_Flags.SkipFunctionBodies)
        wrap_header(wc, topcu, hfile, obuf)
    end
end

###############################################################################
# Utilities
###############################################################################

function name_anon()
    global context::WrapContext
    "ANONYMOUS_"*string(context.anon_count += 1)
end

###############################################################################

end # module wrap_c
