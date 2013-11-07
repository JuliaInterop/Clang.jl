################################################################################
# Julia C wrapper generator using libclang from the LLVM project               #
################################################################################

module wrap_c
    version = v"0.0.0"

using Clang.cindex

export ctype_to_julia, wrap_c_headers
export WrapContext

### Wrappable type hierarchy

reserved_words = ["type", "end"]

### Execution context for wrap_c
typealias StringsArray Array{ASCIIString,1}
# InternalOptions
type InternalOptions
    wrap_structs::Bool
end
InternalOptions() = InternalOptions(false)

global context

# WrapContext object stores shared information about the wrapping session
type WrapContext
    index::cindex.CXIndex
    output_file::ASCIIString
    common_file::ASCIIString
    clang_includes::StringsArray                 # clang include paths
    clang_args::StringsArray               # additional {"-Arg", "value"} pairs for clang
    header_wrapped::Function                     # called to determine cursor inclusion status
    header_library::Function                     # called to determine shared library for given header
    header_outfile::Function                     # called to determine output file group for given header
    common_stream
    cache_wrapped::Set{ASCIIString}
    output_streams::Dict{ASCIIString, IO}
    options::InternalOptions
    anon_count::Int
end
WrapContext(idx,outfile,cmnfile,clanginc,clangextra,hwrap,hlib,hout) = 
    WrapContext(idx,outfile,cmnfile,convert(Array{ASCIIString,1},clanginc),convert(Array{ASCIIString,1}, clangextra),hwrap,hlib,hout,
                None,Set{ASCIIString}(), Dict{ASCIIString,IO}(), InternalOptions(),0)

#
# Initialize wrapping context
#
function init(;
            index                           = None,
            output_file::ASCIIString        = "",
            common_file::ASCIIString        = "",
            clang_args::StringsArray        = ASCIIString[],
            clang_includes::StringsArray    = ASCIIString[],
            clang_diagnostics::Bool         = false,
            header_wrapped                  = (header, cursorname) -> true,
            header_library                  = None,
            header_outputfile               = None)

    # Set up some optional args if they are not explicitly passed.

    (index == None)         && ( index = cindex.idx_create(0, (clang_diagnostics ? 1 : 0)) )

    if (output_file == "" && header_outputfile == None)
        header_outputfile = x->joinpath(strip(splitext(basename(x))[1]) * ".jl")
    end

    (common_file == "")    && ( common_file = output_file )
    
    if (header_library == None)
        error("Missing header_library argument: pass lib name, or (hdr)->lib::ASCIIString function")
    elseif(typeof(header_library) == ASCIIString)
        header_library = x->header_library
    end
    if (header_outputfile == None)
        header_outputfile = x->output_file
    end

    # Instantiate and return the WrapContext
    global context = WrapContext(index, output_file, common_file, clang_includes, clang_args, header_wrapped, header_library,header_outputfile)
    return context
end

### These helper macros will be written to the generated file
helper_macros = "macro c(ret_type, func, arg_types, lib)
    local args_in = Any[ symbol(string('a',x)) for x in 1:length(arg_types.args) ]
    quote
        \$(esc(func))(\$(args_in...)) = ccall( (\$(string(func)), \$(Expr(:quote, lib)) ), \$ret_type, \$arg_types, \$(args_in...) )
    end
end
"

###############################################################################
#
# Mapping from libclang types to Julia types
#
#   This is primarily used with CXTypeKind enums (aka: cindex.TypeKind)
#   but can also be used to map arbitrary type names to corresponding
#   Julia entities, for example "size_t" -> :Csize_t
#
##############################################################################

c_to_jl = {
    TypeKind.VoidType       => Void,
    TypeKind.BoolType       => Bool,
    TypeKind.Char_U         => Uint8,
    TypeKind.UChar          => :Cuchar,
    TypeKind.Char16         => Uint16,
    TypeKind.Char32         => Uint32,
    TypeKind.UShort         => Uint16,
    TypeKind.UInt           => Uint32,
    TypeKind.ULong          => :Culong,
    TypeKind.ULongLong      => :Culonglong,
    TypeKind.Char_S         => Uint8,
    TypeKind.SChar          => Uint8,
    TypeKind.WChar          => Char,
    TypeKind.Short          => Int16,
    TypeKind.IntType        => :Cint,
    TypeKind.Long           => :Clong,
    TypeKind.LongLong       => :Clonglong,
    TypeKind.Float          => :Cfloat,
    TypeKind.Double         => :Cdouble,
    TypeKind.LongDouble     => Float64,
    TypeKind.Enum           => :Cint,
    TypeKind.NullPtr        => C_NULL,
    TypeKind.UInt128        => Uint128,
    "size_t"                => :Csize_t,
    "ptrdiff_t"             => :Cptrdiff_t
    }

# Convert libclang type to julia type
function ctype_to_julia(cutype::CLType)
    typkind = ty_kind(cutype)
    # Special cases: TYPEDEF, POINTER
    if (typkind == TypeKind.Pointer)
        ptr_ctype = cindex.getPointeeType(cutype)
        ptr_jltype = ctype_to_julia(ptr_ctype)
        return Ptr{ptr_jltype}
    elseif (typkind == TypeKind.Typedef || typkind == TypeKind.Record)
        basename = string( spelling( cindex.getTypeDeclaration(cutype) ) )
        return symbol( get(c_to_jl, basename, basename))
    else
        # TODO: missing mappings should generate a warning
        return symbol( string( get(c_to_jl, typkind, :Void) ))
    end
end

###############################################################################

### eliminate symbol from the final type representation
function rep_type(t)
    replace(string(t), ":", "")
end

### Tuple representation without quotes
function rep_args(v)
    o = IOBuffer()
    print(o, "(")
    s = first = start(v)
    r = (!done(v,s))
    while r
        x,s = next(v,s)
        print(o, x)
        done(v,s) && break
        print(o, ", ")
    end
    r && (s == next(v,first)[2]) && print(o, ",")
    print(o, ")")
    seek(o, 0)
    readall(o)
end

function wrap(buf::IO, cursor::EnumDecl; usename="")
    if (usename == "")
        return
    end
    enumname = usename
    println(buf, "# enum $enumname")
    println(buf, "typealias $enumname ", rep_type(ctype_to_julia(cindex.getEnumDeclIntegerType(cursor))))
    for enumitem in children(cursor)
        cur_name = cindex.spelling(enumitem)
        if (length(cur_name) < 1) continue end

        println(buf, "const ", cur_name, " = ", value(enumitem))
    end
    println(buf, "# end $enumname")
end

function name_anon(wc::WrapContext)
    "ANONYMOUS_"*string(wc.anon_count += 1)
end

function wrap (buf::IO, sd::StructDecl; usename = "")
    function ref_name(reftype::CLType)
        if isa(reftype, Typedef) || isa(reftype, Unexposed)
            refdecl = cindex.getTypeDeclaration(reftype)
            refname = spelling(refdecl)
        else
            refname = spelling(reftype)
        end
        refname
    end
    function help_type(t::ConstantArray, cu::CLCursor)
        global context::WrapContext
        arrsize = cindex.getArraySize(t)
        eltype = resolve_type(cindex.getArrayElementType(t))
        elname = ref_name(eltype)
        repname = string("Array_", arrsize, "_", elname)
        if (repname in context.cache_wrapped)
            helper = ""
        else
            helper = string("bitstype 32*sizeof(", rep_type(ctype_to_julia(eltype)), ")*", arrsize, " ", repname)
            push!(context.cache_wrapped, repname)
        end
        return (helper, repname)
    end
    function help_type(t::Pointer, cu::CLCursor)
        ptename = ref_name(pointee_type(t))
        return ("", string("Ptr{", ptename, "}"))
    end
    function help_type(t::CLType, cu::CLCursor)
        return None
    end

    ########################################################
    
    if (usename == "" && (usename = name(sd)) == "")
        warn("Skipping unnamed StructDecl")
        return
    end
    global context::WrapContext
    if (!context.options.wrap_structs)
        return
    end

    prebuf = IOBuffer()
    outbuf = IOBuffer()

    # Generate type declaration
    println(outbuf, "type $usename")
    ccl = children(sd)
    if (length(ccl) < 1)
        warn("Skipping empty struct: \"$usename\"")
        return
    end
    for cu in children(sd)
        cur_name = spelling(cu)
        if (isa(cu, StructDecl))
            continue
        elseif !(isa(cu, FieldDecl) || isa(cu, TypeRef))
            warn("Skipping struct: \"$usename\" due to unsupported field: $cur_name")
            return
        elseif (length(cur_name) < 1)
            error("Unnamed struct member in: $usename ... cursor: ", string(cu)) 
        end
        if ((cur_name in reserved_words)) cur_name = "_"*cur_name end

        ty = cu_type(cu)

        if ((hlp = help_type(ty,cu)) != None)
            (hlp[1] != "") && println(prebuf, hlp[1])
            println(outbuf, "    ", cur_name, "::", hlp[2])
        else
            println(outbuf, "    ", cur_name, "::", ctype_to_julia(resolve_type(ty)))
        end
    end
    println(outbuf, "end")

    # print the type helpers to real output
    print(buf, takebuf_string(prebuf))
    # print the type declaration to real output
    print(buf, takebuf_string(outbuf))
end   

function wrap(buf::IO, funcdecl::FunctionDecl, libname::ASCIIString)
    cu_spelling = spelling(funcdecl)
    
    arg_types = cindex.function_args(funcdecl)
    arg_list = tuple( [rep_type(ctype_to_julia(x)) for x in arg_types]... )
    ret_type = ctype_to_julia(return_type(funcdecl))
    println(buf, "@c ", rep_type(ret_type), " ",
                    symbol(spelling(funcdecl)), " ",
                    rep_args(arg_list), " ", libname )
end

function wrap(buf::IO, tdecl::TypedefDecl)
    function wrap_td(out::IO, t::CLType)
        println(buf, "typealias ",    spelling(t), " ", rep_type(ctype_to_julia(t)) )
    end

    cursor_type = cindex.cu_type(tdecl)
    td_type = cindex.getTypedefDeclUnderlyingType(tdecl)
    
    if isa(td_type, Unexposed)
        tdunxp = children(tdecl)[1]
        wrap(buf, tdunxp; usename=name(tdecl))
        return
    end

    println(buf, "typealias ",    spelling(tdecl), " ", rep_type(ctype_to_julia(td_type)) )
end

function lex_exprn(tokens::TokenList, pos::Int)
    function trans(tok)
        ops = ["+" "-" ">>" "<<" "/" "\\" "%"]
        if (isa(tok, cindex.Literal) || 
            (isa(tok,cindex.Identifier) && isupper(tok.text))) return 0
        elseif (isa(tok, cindex.Punctuation) && tok.text in ops) return 1
        else return -1
        end
    end

    exprn = ""
    prev = 1 >> trans(tokens[pos])
    for pos = pos:tokens.size
        tok = tokens[pos]
        state = trans(tok)
        if ( state $ prev  == 1)
            prev = state
        else
            break
        end 
        exprn = exprn * tok.text
    end
    return (exprn,pos)
end 

function wrap(strm::IO, md::cindex.MacroDefinition)
    tokens = tokenize(md)
    
    # Skip any empty definitions
    if(tokens.size < 2) return end
    if(beginswith(name(md), "_")) return end 

    pos = 0; exprn = ""
    if(tokens[2].text == "(")
        exprn,pos = lex_exprn(tokens, 3)
        if (pos != tokens.size || tokens[pos].text != ")")
            print(strm, "# Skipping MacroDefinition: ", join([c.text*" " for c in tokens]), "\n")
            return
        end
        exprn = "(" * exprn * ")"
    else
        (exprn,pos) = lex_exprn(tokens, 2)
    end
    print(strm, "const " * string(tokens[1].text) * " = " * exprn * "\n")
end

function wrap(buf::IO, cursor::TypeRef)
    println("Printing typeref: ", cursor)
    print(buf, name(cursor))
end

################################################################################
# Wrapping driver
################################################################################

function wrap_header(wc::WrapContext, topcu::CLCursor, top_hdr, ostrm::IO)
    println("WRAPPING HEADER: $top_hdr")
    
    topcl = children(topcu)

    # Loop over all of the child cursors and wrap them, if appropriate.
    for i=1:topcl.size
        cursor = topcl[i]
        cursor_hdr = cu_file(cursor)
        cursor_name = name(cursor)

        # Heuristic to decide what should be wrapped:
        #    1. always wrap things in the current top header (ie not includes)
        #    2. everything else is from includes, wrap if:
        #         - the client wants it wc.header_wrapped == True
        #         - the item has not already been wrapped (ie not in wc.cache_wrapped)
        if (cursor_hdr == top_hdr)
            # pass
        elseif (!wc.header_wrapped(top_hdr, cu_file(cursor)) ||
                        (cursor_name in wc.cache_wrapped) )
            continue
        elseif (beginswith(cursor_name, "__"))
            # skip compiler definitions
            continue
        end

        if (isa(cursor, FunctionDecl))
            wrap(ostrm, cursor, wc.header_library(cu_file(cursor)))
        elseif (isa(cursor, EnumDecl))
            wrap(wc.common_stream, cursor)
        elseif (isa(cursor, TypedefDecl))
            wrap(wc.common_stream,cursor)
        elseif (isa(cursor, MacroDefinition))
            wrap(wc.common_stream,cursor)
        elseif (wc.options.wrap_structs && isa(cursor, StructDecl))
            wrap(wc.common_stream, cursor)
        else
            continue
        end
    end
    cindex.cl_dispose(topcl)
end

function header_output_stream(wc::WrapContext, hfile)
    jloutfile = wc.header_outfile(hfile)
    if (_x = get(wc.output_streams, jloutfile, None)) != None
        return _x
    else
        strm = IOStream("")
        try strm = open(jloutfile, "w")
        catch error("Unable to create output: $jloutfile for header: $hfile") end
        wc.output_streams[jloutfile] = strm
    end
    return strm
end        

function sort_common_includes(strm::IOBuffer)
    # TODO: too many temporaries
    seek(strm,0)
    col1 = Dict{ASCIIString,Int}() 
    col2 = Dict{ASCIIString,Int}()
    tmp = Dict{Int,ASCIIString}()
    pos = Int[]
    fnl = ASCIIString[]

    for (i,ln) in enumerate(readlines(strm))
        tmp[i] = ln
        if (m = match(r"@ctypedef (\w+) (?:Ptr{)?(\w+)(?:}?)", ln)) != nothing
            col1[m.captures[1]] = i
            col2[m.captures[2]] = i
        elseif ((m = match(r"bitstype (.*) (.*)", ln)) != nothing)
            col1[m.captures[2]] = i
            col2[m.captures[1]] = i
        end
    end
    for s in sort(collect(keys(col2)))
        if( (m = get(col1, s, None))!=None)
            push!(fnl, tmp[m])
            push!(pos, m)
        end
    end
 
    kj = setdiff(1:length(keys(tmp)), pos)
    vcat(fnl,[tmp[i] for i in kj])
end

### wrap_c_headers: main entry point
#     TODO: use dict for mapping from h file to wrapper file (or module?)
function wrap_c_headers(wc::WrapContext, headers)

    println(wc.clang_includes)

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

    # Output stream for common items: typedefs, enums, etc.
    wc.common_stream = IOBuffer()

    # Generate the wrappings
    try
        for hfile in headers
            ostrm = header_output_stream(wc, hfile)
            println(ostrm, "# Julia wrapper for header: $hfile")
            println(ostrm, "# Automatically generated using Clang.jl wrap_c, version $version\n")

            topcu = cindex.parse_header(hfile; 
                                 index = wc.index,
                                 args  = wc.clang_args,
                                 includes = wc.clang_includes,
                                 flags = TranslationUnit_Flags.DetailedPreprocessingRecord |
                                              TranslationUnit_Flags.SkipFunctionBodies)
            wrap_header(wc, topcu, hfile, ostrm)

            println(ostrm)
        end 
    finally
        [close(os) for os in values(wc.output_streams)]
    end

    # Sort the common includes so that things aren't used out-of-order
    incl_lines = sort_common_includes(wc.common_stream)
    open(wc.common_file, "w") do strm
        # Write the helper macros
        println(strm, helper_macros, "\n")
        [print(strm, l) for l in incl_lines]
    end
    
    close(wc.common_stream)
end

###############################################################################

end # module wrap_c
