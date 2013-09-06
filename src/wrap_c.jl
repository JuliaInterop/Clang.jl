################################################################################
# Julia C wrapper generator using libclang from the LLVM project               #
################################################################################

module wrap_c
    version = v"0.0.0"

using Clang.cindex
import ..cindex.TypKind, ..cindex.CurKind
import ..cindex.TypedefDecl, ..cindex.FunctionDecl, ..cindex.StructDecl
import ..cindex.EnumDecl, ..cindex.CLType, ..cindex.FieldDecl

export ctype_to_julia, wrap_c_headers
export WrapContext

### Wrappable type hierarchy

abstract CArg

type StructArg <: CArg
    cursor::cindex.CLNode
    typedef::Any
end

type EnumArg <: CArg
    cursor::cindex.CLNode
    typedef::Any
end

reserved_words = ["type", "end"]

### Execution context for wrap_c
typealias StringsArray Array{ASCIIString,1}

# InternalOptions
type InternalOptions
    wrap_structs::Bool
end
InternalOptions() = InternalOptions(false)

# WrapContext object stores shared information about the wrapping session
type WrapContext
    index::cindex.CXIndex
    output_file::ASCIIString
    common_file::ASCIIString
    clang_includes::StringsArray             # clang include paths
    clang_extra_args::StringsArray         # additional {"-Arg", "value"} pairs for clang
    header_wrapped::Function                     # called to determine cursor inclusion status
    header_library::Function                     # called to determine shared library for given header
    header_outfile::Function                     # called to determine output file group for given header
    common_stream
    cache_wrapped::Set{ASCIIString}
    output_streams::Dict{ASCIIString, IOStream}
    options::InternalOptions
end
WrapContext(idx,outfile,cmnfile,clanginc,clangextra,hwrap,hlib,hout) = 
    WrapContext(idx,outfile,cmnfile,clanginc,clangextra,hwrap,hlib,hout,
                None,Set{ASCIIString}(), Dict{ASCIIString,IOStream}(), InternalOptions())

#
# Initialize wrapping context
#
function init(;
            Index                           = None,
            OutputFile::ASCIIString         = ".",
            CommonFile::ASCIIString         = None,
            ClangArgs::StringsArray         = [""],
            ClangIncludes::StringsArray     = [""],
            ClangDiagnostics::Bool          = false,
            header_wrapped                  = (header, cursorname) -> true,
            header_library                  = None,
            header_outputfile               = None)

    # Set up some optional args if they are not explicitly passed.

    (Index == None)         && ( Index = cindex.idx_create(0, (ClangDiagnostics ? 0 : 1)) )
    (CommonFile == None)    && ( CommonFile = OutputFile )
    
    if (header_library == None)
        error("Missing header_library argument: pass lib name, or (hdr)->lib::ASCIIString function")
    elseif(typeof(header_library) == ASCIIString)
        header_library = x->header_library
    end
    if (header_outputfile == None)
        header_outputfile = x->OutputFile
    end

    # Instantiate and return the WrapContext    
    return WrapContext(Index, OutputFile, CommonFile, ClangIncludes, ClangArgs, header_wrapped, header_library,header_outputfile)
end

### These helper macros will be written to the generated file
helper_macros = "macro c(ret_type, func, arg_types, lib)
    local args_in = Any[ symbol(string('a',x)) for x in 1:length(arg_types.args) ]
    quote
        \$(esc(func))(\$(args_in...)) = ccall( (\$(string(func)), \$(Expr(:quote, lib)) ), \$ret_type, \$arg_types, \$(args_in...) )
    end
end

macro ctypedef(fake_t,real_t)
    quote
        typealias \$fake_t \$real_t
    end
end"

###############################################################################
#
# Mapping from libclang types to Julia types
#
#   This is primarily used with CXTypeKind enums (aka: cindex.TypKind)
#   but can also be used to map arbitrary type names to corresponding
#   Julia entities, for example "size_t" -> :Csize_t
#
##############################################################################

c_to_jl = {
    TypKind.VOID            => Void,
    TypKind.BOOL            => Bool,
    TypKind.CHAR_U          => Uint8,
    TypKind.UCHAR           => Cuchar,
    TypKind.CHAR16          => Uint16,
    TypKind.CHAR32          => Uint32,
    TypKind.USHORT          => Uint16,
    TypKind.UINT            => Uint32,
    TypKind.ULONG           => Culong,
    TypKind.ULONGLONG       => Culonglong,
    TypKind.CHAR_S          => Uint8,           # TODO check
    TypKind.SCHAR           => Uint8,           # TODO check
    TypKind.WCHAR           => Char,
    TypKind.SHORT           => Int16,
    TypKind.INT             => Cint,
    TypKind.LONG            => Clong,
    TypKind.LONGLONG        => Clonglong,
    TypKind.FLOAT           => Cfloat,
    TypKind.DOUBLE          => Cdouble,
    TypKind.LONGDOUBLE      => Float64,         # TODO detect?
    TypKind.ENUM            => Cint,            # TODO arch check?
    TypKind.NULLPTR         => C_NULL,
    TypKind.UINT128         => Uint128,
    "size_t"                        => :Csize_t,
    "ptrdiff_t"                 => :Cptrdiff_t
    
    }

# Convert libclang type to julia type
function ctype_to_julia(cutype::CLType)
    typkind = ty_kind(cutype)
    # Special cases: TYPEDEF, POINTER
    if (typkind == TypKind.POINTER)
        ptr_ctype = cindex.getPointeeType(cutype)
        ptr_jltype = ctype_to_julia(ptr_ctype)
        return Ptr{ptr_jltype}
    elseif (typkind == TypKind.TYPEDEF || typkind == TypKind.RECORD)
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

### Build array of include definitions: ["-I", "incpath",...] plus extra args
function build_clang_args(includes, extras)
    reduce(vcat, [], vcat([["-I",x] for x in includes], extras))
end

### Retrieve function arguments for a given cursor
function function_args(cursor::FunctionDecl)
    cursor_type = cindex.cu_type(cursor)
    [cindex.getArgType(cursor_type, uint32(arg_i)) for arg_i in 0:cindex.getNumArgTypes(cursor_type)-1]
end

### Wrap enum. NOTE: we write this to wc.common_stream
function wrap(wc::WrapContext, argt::EnumArg, strm::IOStream)
    enum = cindex.name(argt.cursor)
    enum_typedef = if (typeof(argt.typedef) == cindex.CXCursor)
            cindex.name(argt.typedef)
        else
            ""
        end
    enum_name = 
        if (enum != "") enum
        elseif (enum_typedef != "") enum_typedef
        else "ANONYMOUS"
        end

    if (enum_name in wc.cache_wrapped)
        return
    elseif(argt.typedef == None)
        push!(wc.cache_wrapped, enum_name)
    end

    println(wc.common_stream, "# enum $enum_name")
    cl = cindex.children(argt.cursor)

    for i=1:cl.size
        cur_cu = cindex.ref(cl,i)
        cur_name = cindex.spelling(cur_cu)
        if (length(cur_name) < 1) continue end

        println(wc.common_stream, "const ", cur_name, " = ", cindex.value(cur_cu))
    end
    cindex.cl_dispose(cl)
    println(wc.common_stream, "# end")
end

function wrap(wc::WrapContext, arg::StructArg, strm::IOStream)
    @assert isa(arg.cursor, StructDecl)
    cursor = arg.cursor
    typedef = arg.typedef

    st = cindex.name(cursor)
    st_typedef = if (typeof(typedef) == cindex.CXCursor)
            cindex.name(typedef)
        else
            ""
        end
    st_name = 
        if (st != "") st
        elseif (st_typedef != "") st_typedef
        else
            # TODO: come up with a better idea
            "ANONYMOUS_"*string(round(rand()*10000,5))
        end

    if (st_name in wc.cache_wrapped)
        return
    else
        # Cache this regardless of typedef
        push!(wc.cache_wrapped, st_name)
    end

    cl = cindex.children(cursor)
    if (cl.size == 0)
        # Probably a forward declaration.
        # TODO: check on this. any nesting that we need to handle?
        return
    end

    println(wc.common_stream, "type $st_name")

    for i=1:cl.size
        cur_cu = cindex.ref(cl,i)
        cur_name = cindex.spelling(cur_cu)

        if (!isa(cur_cu, FieldDecl))
            warn("STRUCT: Skipping non-field declaration: $cur_name in: $st_name")
            continue
        end
        if (length(cur_name) < 1) 
            warn("STRUCT: Skipping unnamed struct member in: $st_name")
            continue 
        end
        if ((cur_name in reserved_words)) cur_name = "_"*cur_name end

        ty = resolve_type(cindex.cu_type(cur_cu))

        println(wc.common_stream, "    ", cur_name, "::", rep_type(ctype_to_julia(ty)))
    end
    cindex.cl_dispose(cl)
    println(wc.common_stream, "end")
end

function wrap(wc::WrapContext, arg::FunctionDecl, strm::IOStream)
    @assert isa(arg, FunctionDecl)

    cu_spelling = spelling(arg)
    push!(wc.cache_wrapped, name(arg))
    
    arg_types = function_args(arg)
    arg_list = tuple( [rep_type(ctype_to_julia(x)) for x in arg_types]... )
    ret_type = ctype_to_julia(cindex.return_type(arg))
    println(strm, "@c ", rep_type(ret_type), " ",
                    symbol(spelling(arg)), " ",
                    rep_args(arg_list), " ", wc.header_library(cu_file(arg)) )
end

function wrap(wc::WrapContext, arg::TypedefDecl, strm::IOStream)
    @assert isa(arg, TypedefDecl)

    typedef_spelling = spelling(arg)
    if((typedef_spelling in wc.cache_wrapped))
        return
    else
        push!(wc.cache_wrapped, typedef_spelling)
    end

    cursor_type = cindex.cu_type(arg)
    td_type = cindex.resolve_type(cindex.getTypedefDeclUnderlyingType(arg))
    # initialize typealias in current context to avoid error TODO delete
    #:(typealias $typedef_spelling ctype_to_julia($td_type))
    
    println(wc.common_stream, "@ctypedef ",    typedef_spelling, " ", rep_type(ctype_to_julia(td_type)) )
end

function wrap_header(wc::WrapContext, topcu::CLNode, top_hdr, ostrm::IOStream)
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
        end

        if (isa(cursor, FunctionDecl) || isa(cursor, FieldDecl) || isa(cursor, TypedefDecl))
            towrap = cursor 
        elseif (isa(cursor, EnumDecl))
            # TODO: need a better solution for this
            #    libclang does not provide xref between each cursor for typedef'd enum
            #    right now, if a typedef follows enum then we just assume it is
            #    for the enum declaration. this might not be true for anonymous enums.
            
            tdcu = None
            if (i<topcl.size)
                tdcu = getindex(topcl, i+1)
                tdcu = (isa(tdcu, TypedefDecl) ? tdcu : None)
            end
            towrap = EnumArg(cursor, tdcu)
        elseif (wc.options.wrap_structs && isa(cursor, StructDecl))
            tdcu = None
            if (i<topcl.size)
                tdcu = getindex(topcl, i+1)
                (isa(tdcu, TypedefDecl) ? tdcu : None)
            end
            towrap = StructArg(cursor, tdcu)
        else
            continue
        end
        wrap(wc, towrap, ostrm)
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
function wrap_c_headers(
        wc::WrapContext,                    # wrapping context
        headers)                            # header files to wrap

    println(wc.clang_includes)

    # Check headers!
    for h in headers
        if !isfile(h)
            error(h, " cannot be found")
        end
    end
    for d in wc.clang_includes
        if !isdir(d)
            error(d, " cannot be found")
        end
    end

    clang_args = build_clang_args(wc.clang_includes, wc.clang_extra_args)

    # Output stream for common items: typedefs, enums, etc.
    wc.common_stream = IOBuffer()

    # Generate the wrappings
    try
        for hfile in headers
            ostrm = header_output_stream(wc, hfile)
            println(ostrm, "# Julia wrapper for header: $hfile")
            println(ostrm, "# Automatically generated using Clang.jl wrap_c, version $version\n")

            topcu = cindex.parse(hfile; ClangIndex = wc.index, ClangArgs = clang_args)
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

function get_top_cursor(wc::WrapContext, header)
    tunit = cindex.tu_parse(wc.index, header,
                                    build_clang_args(wc.clang_includes, wc.clang_extra_args),
                                    cindex.TranslationUnit_Flags.None)
    topcu = cindex.getTranslationUnitCursor(tunit)
end

end # module wrap_c
