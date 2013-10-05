# module wrap_cpp

using Clang.cindex

function base_classes(c)
	search(c, isa(c, cindex.CXXBaseSpecifier))
end

################################################################################
# Output helpers
################################################################################

space(io::IO)      = print(io, " ")
openparen(io::IO)  = print(io, "(")
closeparen(io::IO) = print(io, ")")
opencurly(io::IO)  = print(io, "{")
closecurly(io::IO) = print(io, "}")
opensquare(io::IO) = print(io, "[")
closesquare(io::IO)= print(io, "]")
comma(io::IO)      = print(io, ",")
newline(io::IO)    = print(io, "\n")

function emit(out::IO, t::cindex.CLType)
    print(out, cl_to_c[typeof(t)])
end

function emit(out::IO, t::Union(cindex.Record, cindex.Typedef))
    print(out, spelling(cindex.getTypeDeclaration(t)))
end

function emit(out::IO, t::cindex.ConstantArray)
    arrtype = cindex.getArrayElementType(t)
    arrsize = cindex.getArraySize(t)
    emit(out, arrtype)
    opensquare(out); print(out, arrsize); closesquare(out)
end    

function emit(out::IO, t::cindex.Pointer)
    pointee = cindex.pointee_type(t)
    emit(out, pointee)
    print(out, "*")
end

function base_classes(c)
	cindex.search(c, x->isa(x, cindex.CXXBaseSpecifier))
end

function emit(out::IO, parm::cindex.ParmDecl)
    emit(out, cu_type(parm))
end

function check_args(args)
    for arg in args
        argt = cu_type(arg)
        if isa(argt, cindex.LValueReference)  ||
               isa(argt, cindex.FirstBuiltin)
            return false
        end
    end
    return true
end

function get_args(method::cindex.CXXMethod)
    args = CLCursor[]
    for c in children(method) isa(c,cindex.ParmDecl) ? push!(args, c) : break end
    args
end

function emit_args(out::IO, args)
    emit_arg(out,arg,docomma=false) = begin
        emit(out,arg)
        space(out)
        print(out,spelling(arg))
        docomma && (comma(out); space(out))
    end
    for i = 1:length(args)
        emit_arg(out,args[i], i < length(args))
    end
end

function emit_name(out::IO, method::cindex.CXXMethod, parent::cindex.CLCursor)
    buf = IOBuffer()
    print(buf, spelling(method))
    args = get_args(method)
    for a in args
        print(buf, "_")
        print(buf, spelling(cu_type(a)))
    end
    print(out, takebuf_string(buf))
end

function wrap(out::IO, method::cindex.CXXMethod)
    buf = IOBuffer()
    parentdecl = cindex.getCursorLexicalParent(method)
    parentname = spelling(parentdecl)

    # emit return type and name
    ret_type = return_type(method)    
    emit(buf, ret_type)
    space(buf)
    emit_name(buf, method, parentdecl)

    # emit arguments
    openparen(buf)
    print(buf, parentname, "* this")
    args = get_args(method)
    
    # bail out if any argument is not supported
    if (!check_args(args)) return end
    
    length(args) > 0 && (comma(buf); space(buf))
    emit_args(buf, args)
    closeparen(buf)
    space(buf); opencurly(buf)
    newline(buf)
    
    # emit method call
    print(buf, "  this->", spelling(method))
    openparen(buf)
    emit_args(buf, args)
    closeparen(buf)
    
    # close
    newline(buf)
    closecurly(buf)
    newline(buf)

    # print the buffer to the outpur
    print(STDOUT, takebuf_string(buf))
    # TODO: return information about the thing we wrapped?
end

function wrap(out::IO, top::cindex.ClassDecl)
    println("Wrapping class: ", name(top))
    for decl in [c for c in children(top)] #[1:30] # TODO: remove this
        isa(decl, cindex.CXXMethod) && wrap(out, decl)
    end
end

cl_to_c = {
    cindex.VoidType       => "void",
    cindex.FirstBuiltin   => "void",
    cindex.BoolType       => "bool",
    cindex.Char_U         => "unsigned char",
    cindex.UChar          => "unsigned char",
    cindex.Char16         => "char16_t",
    cindex.Char32         => "char32_t",
    cindex.UShort         => "unsigned short",
    cindex.UInt           => "unsigned int",
    cindex.ULong          => "unsigned long",
    cindex.ULongLong      => "unsigned long long",
    cindex.Char_S         => "char",
    cindex.SChar          => "char",
    cindex.WChar          => "wchar_t",
    cindex.Short          => "short",
    cindex.IntType        => "int",
    cindex.Long           => "long",
    cindex.LongLong       => "long long",
    cindex.Float          => "float",
    cindex.Double         => "double",
    cindex.LongDouble     => "long double",
    cindex.Enum           => "enum",
    cindex.NullPtr        => "NULL",
    cindex.UInt128        => "uint128_t"
    }

################################################################################
# Construction of Julia wrapper
################################################################################

function wrapjl(out::IO, t::cindex.ConstantArray)
    print(out, "FIXEDARRAY") # TODO: FIXME
end

function wrapjl(out::IO, t::Union(cindex.Record, cindex.Typedef))
    print(out, spelling(cindex.getTypeDeclaration(t)))
end

function wrapjl(out::IO, arg::cindex.CLType)
    print(out, string(cl_to_jl[typeof(arg)]))
end

function wrapjl(out::IO, ptr::cindex.Pointer)
    pointee = pointee_type(ptr)
    
    print(out, "Ptr")
    opencurly(out)
    wrapjl(out, pointee)
    closecurly(out)
end

function wrapjl(out::IO, parm::cindex.ParmDecl)
    wrapjl(out, cu_type(parm))
end

function wrapjl_args(out::IO, args)
    emit_arg(out,arg,docomma=false) = begin
        print(out,spelling(arg))
        print(out,"::")
        wrapjl(out,arg)
        docomma && (comma(out); space(out))
    end
    for i = 1:length(args)
        emit_arg(out,args[i], i < length(args))
    end
end

function wrapjl(out::IO, method::cindex.CXXMethod)
    buf = IOBuffer()
    parentdecl = cindex.getCursorLexicalParent(method)
    parentname = spelling(parentdecl)
    
    args = get_args(method)
    if (!check_args(args)) return end # TODO: warn?

    # emit Julia call
    print(buf, "@method")
    space(buf)
    print(buf, parentname)
    space(buf)
    print(buf, spelling(method))
    space(buf)
    openparen(buf)
    wrapjl_args(buf, args)
    closeparen(buf)
    newline(buf)
    print(out, takebuf_string(buf))
end

function wrapjl(out::IO, class::cindex.ClassDecl)
    println("in class")
    for c in children(class)
        if(isa(c, cindex.CXXMethod))
            wrapjl(out, c)
        end
    end
end

cl_to_jl = {
    cindex.VoidType        => Void,
    cindex.BoolType        => Bool,
    cindex.Char_U          => Uint8,
    cindex.UChar           => :Cuchar,
    cindex.Char16          => Uint16,
    cindex.Char32          => Uint32,
    cindex.UShort          => Uint16,
    cindex.UInt            => Uint32,
    cindex.ULong           => :Culong,
    cindex.ULongLong       => :Culonglong,
    cindex.Char_S          => Uint8,           # TODO check
    cindex.SChar           => Uint8,           # TODO check
    cindex.WChar           => Char,
    cindex.Short           => Int16,
    cindex.IntType         => :Cint,
    cindex.Long            => :Clong,
    cindex.LongLong        => :Clonglong,
    cindex.Float           => :Cfloat,
    cindex.Double          => :Cdouble,
    cindex.LongDouble      => Float64,         # TODO detect?
    cindex.Enum            => :Cint,            # TODO arch check?
    cindex.NullPtr         => C_NULL,
    cindex.UInt128         => Uint128,
    "size_t"        => :Csize_t,
    "ptrdiff_t"     => :Cptrdiff_t
    }

# end # module wrap_cpp
