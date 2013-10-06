# module wrap_cpp

using Clang.cindex
using Clang.wrap_base

################################################################################
# Generation of C wrapper
################################################################################

emitc(out::IO, arg::ArgProxy) = emitc(out, arg.cltype)

function emit(out::IO, t::CLType)
    print(out, cl_to_c[typeof(t)])
end

function emit(out::IO, t::Union(Record, Typedef))
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

function emit(out::IO, parm::cindex.ParmDecl)
    emit(out, cu_type(parm))
end

function check_args(args)
    check = true
    for arg in args
        argt = cu_type(arg)
        check &= isa(argt, cindex.LValueReference)
        check &= isa(argt, cindex.FirstBuiltin)
    end
    return check
end

function get_args(method::cindex.CXXMethod)
    args = CLCursor[]
    for c in children(method)
        isa(c,cindex.ParmDecl) ? push!(args, c) : break
    end
    return args
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

function returns_value(rtype::CLType)
    hasret = true
    hasret &= ~isa(rtype, VoidType)
    return hasret
end

function wrap(out::IO, method::cindex.CXXMethod, nameid::Int)
    buf = IOBuffer()

    # bail out if any argument is not supported
    args = get_args(method)
    if (!check_args(args)) return end
 
    methodname = spelling(method)
    parentdecl = cindex.getCursorLexicalParent(method)
    parentname = spelling(parentdecl)

    # emit return type and name
    rettype = return_type(method)
    emit(buf, rettype)
    space(buf)
    print(buf, parentname, "_", methodname, nameid)
    
    # check for a return value
    hasreturn = returns_value(rettype)
   
    # emit arguments
    openparen(buf)
        print(buf, parentname, "* this")
        length(args) > 0 && comma(buf)
        space(buf)
        emit_args(buf, args)
    closeparen(buf)
    space(buf)
    
    opencurly(buf)
    newline(buf)
    print(buf, "  ")

    # emit method call
    if(hasreturn)
        print(buf, "return")
        space(buf)
    end    
    print(buf, "this->", methodname)
    openparen(buf)
        emit_args(buf, args)
    closeparen(buf)
    
    # close
    newline(buf)
    closecurly(buf)
    newline(buf)

    # print the buffer to the output
    print(out, takebuf_string(buf))
    # TODO: return information about the thing we wrapped?
end

function wrap(out::IO, top::cindex.ClassDecl)
    println("Wrapping class: ", name(top))
    MethodCount = Dict{ASCIIString, Int}()

    for decl in [c for c in children(top)]
        declname = spelling(decl)
        if isa(decl, cindex.CXXMethod)
            id = (MethodCount[declname] = get(MethodCount, declname, 0) + 1)
            wrap(out, decl, id)
        end 
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

# TODO: FIXME
function wrapjl(out::IO, t::cindex.ConstantArray)
    print(out, "FIXEDARRAY")
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

function wrapjl(out::IO, method::cindex.CXXMethod, id::Int)
    buf = IOBuffer()

    methodname = spelling(method)
    parentdecl = cindex.getCursorLexicalParent(method)
    parentname = spelling(parentdecl)
    
    args = get_args(method)
    if (!check_args(args)) return end                       # TODO: warning?

    print(buf, "@method")                                   # emit Julia call
    space(buf)
    print(buf, parentname)                                  # parent class
    space(buf)
    print(buf, methodname)
    space(buf)
    wrapjl(buf, return_type(method))                        # return type
    space(buf)
    openparen(buf)
    wrapjl_args(buf, args)                                  # arguments
    closeparen(buf)
    space(buf)
    print(buf, methodname, id)             # C name
    newline(buf)
    print(out, takebuf_string(buf))
end

function wrapjl(out::IO, class::cindex.ClassDecl)
    MethodCount = Dict{ASCIIString, Int}()

    for decl in [c for c in children(class)]
        declname = spelling(decl)
        if isa(decl, cindex.CXXMethod)
            id = (MethodCount[declname] = get(MethodCount, declname, 0) + 1)
            wrapjl(out, decl, id)
        end 
    end
end

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
# Utility functions
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


function base_classes(class::cindex.ClassDecl)
    return [cindex.getCursorReferenced(c)
            for c in cindex.search(class, cindex.CXXBaseSpecifier)]
end


# end # module wrap_cpp
