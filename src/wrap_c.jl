################################################################################
# Julia C wrapper generator using libclang from the LLVM project               #
################################################################################

module wrap_c
    version = v"0.0.0"

using Clang.cindex

export wrap_c_headers
export WrapContext

### Reserved Julia identifiers to prepend with "_"
reserved_words = ["type", "end"]
function name_safe(c::CLCursor)
    cur_name = name(c)
    return (cur_name in reserved_words) ? "_"*cur_name : cur_name
end

### InternalOptions
type InternalOptions
    wrap_structs::Bool
end
InternalOptions() = InternalOptions(true)

### WrapContext
# stores shared information about the wrapping session
type WrapContext
    index::cindex.CXIndex
    output_file::ASCIIString
    common_file::ASCIIString
    clang_includes::Array{ASCIIString,1}         # clang include paths
    clang_args::Array{ASCIIString,1}             # additional {"-Arg", "value"} pairs for clang
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

### Convenience function to initialize wrapping context with defaults
function init(;
            index                           = None,
            output_file::ASCIIString        = "",
            common_file::ASCIIString        = "",
            clang_args::Array{ASCIIString,1}
                                            = ASCIIString[],
            clang_includes::Array{ASCIIString,1}
                                            = ASCIIString[],
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
        header_library = x->strip(splitext(basename(x))[1])
    elseif isa(header_library, ASCIIString)
        header_library = x->header_library
    end
    if (header_outputfile == None)
        header_outputfile = x->output_file
    end

    # Instantiate and return the WrapContext
    global context = WrapContext(index, output_file, common_file, clang_includes, clang_args, header_wrapped, header_library,header_outputfile)
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
    cindex.VoidType         => Void,
    cindex.BoolType         => Bool,
    cindex.Char_U           => Uint8,
    cindex.UChar            => :Cuchar,
    cindex.Char16           => Uint16,
    cindex.Char32           => Uint32,
    cindex.UShort           => Uint16,
    cindex.UInt             => Uint32,
    cindex.ULong            => :Culong,
    cindex.ULongLong        => :Culonglong,
    cindex.Char_S           => Uint8,
    cindex.SChar            => Uint8,
    cindex.WChar            => Char,
    cindex.Short            => Int16,
    cindex.IntType          => :Cint,
    cindex.Long             => :Clong,
    cindex.LongLong         => :Clonglong,
    cindex.Float            => :Cfloat,
    cindex.Double           => :Cdouble,
    cindex.LongDouble       => Float64,
    cindex.Enum             => :Cint,
    cindex.NullPtr          => C_NULL,
    cindex.UInt128          => Uint128,
    cindex.FirstBuiltin     => Void,
    "size_t"                => :Csize_t,
    "ptrdiff_t"             => :Cptrdiff_t
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
    return spelling(cindex.getTypeDeclaration(t))
end

function repr_jl(ptr::cindex.Pointer)
    ptee = pointee_type(ptr)
    return string("Ptr{", ((r = repr_jl(ptee)) == "" ? "Void" : r), "}")
end

function repr_jl(parm::cindex.ParmDecl)
    return repr_jl(cu_type(parm))
end

function repr_jl(unxp::Unexposed)
    return spelling(cindex.getTypeDeclaration(unxp))
end

function repr_jl(arg::cindex.CLType)
    return string(cl_to_jl[typeof(arg)])
end
function repr_jl(t::ConstantArray)
    # For ConstantArray declarations, we make an immutable
    # array with that many members of the appropriate type.

    # Override pointer representation so pointee type is not written
    repr_short(t::CLType) = isa(t, Pointer) ? "Ptr" : repr_jl(t)
    
    # Grab the WrapContext in order to add bitstype
    global context::WrapContext
    buf = context.common_stream

    arrsize = cindex.getArraySize(t)
    eltype = cindex.getArrayElementType(t)
    typename = string("Array_", arrsize, "_", repr_short(eltype))
    if !(typename in context.cache_wrapped)
        println(buf, "immutable ", typename)
        for i = 1:arrsize
            println(buf, "    d", i, "::", repr_jl(eltype))
        end
        println(buf, "end")
    end
    push!(context.cache_wrapped, typename)
    return typename
end

function repr_jl(t::UnionType)
    tdecl = cindex.getTypeDeclaration(t)
    maxelem = largestfield(tdecl)
    return repr_jl(maxelem)
end

###############################################################################
# Get field decl sizes
#   - used for hacky union inclusion: we find the largest union field and
#     declare a block of bytes to match.
###############################################################################
 
typesize(cu::CLCursor)     = typesize(cu_type(cu))
typesize(t::ConstantArray) = cindex.getArraySize(t)
    
function largestfield(cu::UnionDecl)
    maxsize,maxelem = 0
    fields = children(cu)
    for i in 1:length(fields)
        maxelem = ( (maxsize > (typesize(fields[i]))) ? maxelem : i )
    end
    fields[maxelem]
end

function fieldsize(cu::FieldDecl)
    fieldsize(children(cu)[1])    
end

################################################################################
# Handle declarations
################################################################################

function wrap(buf::IO, cursor::EnumDecl; usename="")
    if (usename == "" && (usename = name(cursor)) == "")
        usename = name_anon()
    end
    enumname = usename
    println(buf, "# begin enum $enumname")
    println(buf, "typealias $enumname ", repr_jl(cindex.getEnumDeclIntegerType(cursor)))
    for enumitem in children(cursor)
        cur_name = cindex.spelling(enumitem)
        if (length(cur_name) < 1) continue end

        println(buf, "const ", cur_name, " = ", value(enumitem))
    end
    println(buf, "# end enum $enumname")
end

function wrap (buf::IO, sd::StructDecl; usename = "")
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
        if (isa(cu, StructDecl) || isa(cu, UnionDecl))
            continue
        elseif !(isa(cu, FieldDecl) || isa(cu, TypeRef))
            warn("Skipping struct: \"$usename\" due to unsupported field: $cur_name")
            return
        elseif (length(cur_name) < 1)
            error("Unnamed struct member in: $usename ... cursor: ", string(cu)) 
        end
        if ((cur_name in reserved_words)) cur_name = "_"*cur_name end

        println(outbuf, "    ", cur_name, "::", repr_jl(cu_type(cu)))
        #if ((hlp = help_type(ty,cu)) != None)
        #    (hlp[1] != "") && println(prebuf, hlp[1])
        #    println(outbuf, "    ", cur_name, "::", hlp[2])
        #else
        #    println(outbuf, "    ", cur_name, "::", repr_jl(ty))
        #end
    end
    println(outbuf, "end")

    # print the type helpers to real output
    print(buf, takebuf_string(prebuf))
    # print the type declaration to real output
    print(buf, takebuf_string(outbuf))
end   

function wrap(buf::IO, funcdecl::FunctionDecl, libname::ASCIIString)
    function print_args(buf::IO, cursors, types)
        i = 1
        for (c,t) in zip(cursors,types)
            print(buf, name_safe(c), "::", t)
            (i < length(cursors)) && print(buf, ", ")
            i += 1
        end
    end

    cu_spelling = spelling(funcdecl)
    
    funcname = spelling(funcdecl)
    arg_types = cindex.function_args(funcdecl)
    args = [x for x in search(funcdecl, ParmDecl)]
    arg_list = tuple( [repr_jl(x) for x in arg_types]... )
    ret_type = repr_jl(return_type(funcdecl))

    print(buf, "function ")
    print(buf, spelling(funcdecl))
    print(buf, "(")
    print_args(buf, args, [repr_jl(x) for x in arg_types])
    println(buf, ")")
    print(buf, "  ")
    print(buf, "ccall( (:", funcname, ", ", libname, "), ")
    print(buf, rep_type(ret_type))
    print(buf, ", ")
    print(buf, rep_args(arg_list), ", ")
    for (i,arg) in enumerate(args)
        print(buf, name_safe(arg))
        (i < length(args)) && print(buf, ", ")
    end
    println(buf, ")")
    println(buf, "end")
end

function wrap(buf::IO, tref::TypeRef; usename="")
    println("Wrap: ", tref)
end

function wrap(buf::IO, tdecl::TypedefDecl; usename="")
    function wrap_td(out::IO, t::CLType)
        println(buf, "typealias ",    spelling(t), " ", repr_jl(t)) 
    end

    cursor_type = cindex.cu_type(tdecl)
    td_type = cindex.getTypedefDeclUnderlyingType(tdecl)
    
    if isa(td_type, Unexposed)
        tdunxp = children(tdecl)[1]
        wrap(buf, tdunxp; usename=name(tdecl))
        return
    elseif isa(td_type, FunctionProto)
        return string("# Skipping Typedef: FunctionProto", spelling(tdecl))
    end

    println(buf, "typealias ",    spelling(tdecl), " ", repr_jl(td_type) )
end

################################################################################
# Handler for macro definitions
################################################################################
#
# For handling of #define'd constants, allows basic expressions
# but bails out quickly.

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
            print(strm, "# Skipping MacroDefinition: ", join([c.text for c in tokens]), "\n")
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
            wrap(wc.common_stream,cursor)
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

################################################################################
# Wrapping driver
################################################################################

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
        [print(strm, l) for l in incl_lines]
    end
    
    close(wc.common_stream)
end

###############################################################################
# Utilities
###############################################################################

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

# eliminate symbol from the final type representation
function rep_type(t)
    replace(string(t), ":", "")
end

# Tuple representation without quotes
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

function name_anon()
    global context::WrapContext
    "ANONYMOUS_"*string(context.anon_count += 1)
end

###############################################################################

end # module wrap_c
