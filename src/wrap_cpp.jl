module wrap_cpp
# module wt

using Clang.cindex

export
    CustomArg,
    ArgProxy,
    WrMethod
    #emitc_init,
    #emitc_post

using Compat
import Compat.String

################################################################################
# Method entry point
################################################################################

immutable WrappedMethod
    name::Compat.ASCIIString
    method::CXXMethod
    parent::ClassDecl
    args::Array{Any,1}
    hasretval::Bool
end

###
# Parse a C++ method and build a collection of
# argument types, possibly with proxy implementation.
###
function analyze_method(method::CXXMethod)
    arg_list = get_args(method)

    hasreturn = returns_value(method)

    args = Any[]
    for arg in arg_list
        proxy = get_proxy(spelling(cu_type(arg)))
        (proxy == Union{}) ? push!(args, arg) : push!(args, proxy)
    end
    return WrappedMethod(spelling(method),
                         method,
                         cindex.getCursorLexicalParent(method),
                         args,
                         hasreturn)
end

################################################################################
# Extensible type-proxy interface
################################################################################
# Usage:
#   - create custom handler ArgType <: ArgProxy
#   - write emitc_init and emitc_post for that type
#   - set TypeProxies[type_spelling] = ArgType

abstract TypeProxy <: CLType

typealias __TypeProxiesType Dict{AbstractString, Type}
const TypeProxies = Dict{AbstractString, Type}()

function get_proxy(typename::AbstractString)
    get(TypeProxies::__TypeProxiesType, typename, Union{})
end

################################################################################
# Generation of C wrapper
################################################################################

#emitc(out::IO, arg::ArgProxy) = emitc(out, arg.cltype)

function emit(out::IO, t::CLType)
    if haskey(cl_to_c, typeof(t))
        print(out, cl_to_c[typeof(t)])
    else
        warn("no C type defined for $t")
    end
end

function emit(out::IO, t::Union{Record, Typedef})
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
    modifs = function_arg_modifiers(parm)
    print(out, join(map(x->x.text, modifs), " "))
    space(out)
    emit(out, cu_type(parm))
end

function check_args(args)
    check = true
    for arg in args
        argt = cu_type(arg)
        check = check && !isa(argt, cindex.LValueReference)
        #check &= isa(argt, cindex.FirstBuiltin)
    end
    return check
end

function emit_args(out::IO, args)
    emit_arg(out,arg,docomma=false) = begin
        emit(out,arg)
        space(out)
        print(out,spelling(arg))
        docomma && (comma(out); space(out))
    end
    for i = 1:length(args)
        emit_arg(out, args[i], i < length(args))
    end
end

function emit_args_vals(out::IO, args)
    print(out, join(map(spelling, args), ", "))
end

# function wrap(out::IO, method::cindex.Constructor, nameid::Int)
#     wrap(out, convert(cindex.CXXMethod, method), nameid)
# end


function wrap(out::IO, method::cindex.CXXMethod, nameid::Int=0)
    buf = IOBuffer()

    # bail out if any argument is not supported
    args = get_args(method)
    if (!check_args(args))
        warn("could not wrap $(spelling(method)) because of arguments")
        return false
    end

    methodname = spelling(method)
    parentdecl = cindex.getCursorLexicalParent(method)
    parentname = spelling(parentdecl)
    #println("$parentname::$methodname", args)

    # emit return type and name
    rettype = return_type(method)
    modifs = function_return_modifiers(method)

    print(buf, join(map(x->x.text, modifs), " "))
    space(buf)

    emit(buf, rettype)
    space(buf)
    print(buf, parentname, "_", methodname, nameid)

    # check for a return value
    hasreturn = returns_value(rettype)

    # emit arguments
    openparen(buf)
        print(buf, parentname, "* __obj")
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
    print(buf, "__obj->", methodname)
    openparen(buf)
        #emit_args(buf, args)
        emit_args_vals(buf, args)
    closeparen(buf)
    print(buf, ";")

    # close
    newline(buf)
    closecurly(buf)
    newline(buf)

    # print the buffer to the output
    print(out, takebuf_string(buf))
    # TODO: return information about the thing we wrapped?
end


function wrap(out::IO, method::cindex.Constructor, nameid::Int=0)
    buf = IOBuffer()

    # bail out if any argument is not supported
    args = get_args(method)
    if (!check_args(args))
        warn("could not wrap $(spelling(method)) because of arguments")
        return false
    end

    methodname = spelling(method)
    parentdecl = cindex.getCursorLexicalParent(method)
    parentname = spelling(parentdecl)

    # emit return type and name
    print(buf, parentname)
    print(buf, "*")

    space(buf)
    print(buf, parentname, "_", methodname, nameid)

    # emit arguments
    openparen(buf)
        emit_args(buf, args)
    closeparen(buf)
    space(buf)

    opencurly(buf)
    newline(buf)
    print(buf, "  ")


    print(buf, "return")
    space(buf)
    print(buf, "new ", parentname)
    openparen(buf)
        emit_args_vals(buf, args)
    closeparen(buf)
    print(buf, ";")

    # close
    newline(buf)
    closecurly(buf)
    newline(buf)

    # print the buffer to the output
    print(out, takebuf_string(buf))
end

function wrap(out::IO, top::cindex.ClassDecl)
    println("Wrapping class: ", name(top))
    MethodCount = Dict{String, Int}()

    println(out, "extern \"C\" {")
    for decl in [c for c in children(top)]
        declname = spelling(decl)
        if isa(decl, cindex.CXXMethod) && cindex.getCXXAccessSpecifier(decl)==1
            id = (MethodCount[declname] = get(MethodCount, declname, 0) + 1)
            wrap(out, decl, id)
        end
    end
    println(out, "}//extern C")
end

cl_to_c = Dict{Any,Any}(
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
    cindex.Enum           => "unsigned int",
    cindex.NullPtr        => "NULL",
    cindex.UInt128        => "uint128_t",
    cindex.LValueReference=> "LVAL"
    )

################################################################################
# Construction of Julia wrapper
################################################################################


function class_supers(cl::ClassDecl)
    toks = tokenize(cl)
    a = findfirst(x->x.text==":", toks)
    b = findfirst(x->x.text=="{", toks)
    supers = collect(toks)[a+1:b-1]
    return collect(filter(x->isa(x, cindex.Identifier), supers))
end

# TODO: FIXME
function wrapjl(out::IO, t::cindex.ConstantArray)
    print(out, "FIXEDARRAY")
end

function wrapjl(out::IO, t::Union{cindex.Record, cindex.Typedef})
    print(out, spelling(cindex.getTypeDeclaration(t)))
end

function wrapjl(out::IO, arg::cindex.CLType)
    if haskey(cl_to_jl, typeof(arg))
        print(out, string(cl_to_jl[typeof(arg)]))
    else
        warn("no cl_to_jl for $arg")
    end
end

function wrapjl(out::IO, ptr::cindex.Pointer)
    pointee = pointee_type(ptr)
    print(out, "Ptr")
    opencurly(out)
    wrapjl(out, pointee)
    closecurly(out)

    # if !haskey(cl_to_jl, typeof(pointee))
    #     # print(out, "Ptr")
    #     # opencurly(out)
    #     # print(out, "Void")
    #     wrapjl(out, pointee)
    #     # closecurly(out)
    # else
    #     print(out, "Ptr")
    #     opencurly(out)
    #     wrapjl(out, pointee)
    #     closecurly(out)
    # end
end

function wrapjl(out::IO, parm::cindex.ParmDecl)
    #println(name(parm), " ", cu_type(parm))
    wrapjl(out, cu_type(parm))
end

function wrapjl_args(out::IO, args, defs=Any[])
    emit_arg(out,arg,docomma=true) = begin
        print(out,spelling(arg))
        print(out,"::")
        wrapjl(out,arg)
        docomma && (comma(out); space(out))
    end
    for i = 1:length(args)
        emit_arg(out, args[i]) #, i < length(args))
    end
end

function wrapjl(out::IO, libname::String, method::cindex.CXXMethod, id::Int)
    buf = IOBuffer()

    methodname = spelling(method)
    parentdecl = cindex.getCursorLexicalParent(method)
    parentname = spelling(parentdecl)

    args = get_args(method)
    defs = cindex.function_arg_defaults(method)
    #println("wrapjl: args=", join(args, ","))
    if (!check_args(args)) return end                       # TODO: warning?

    print(buf, "@method")                                   # emit Julia call
    space(buf)
    print(buf, libname)                                  # parent class
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
    space(buf)
    if length(defs)>0
        s = ", "
    else
        s = ""
    end
    print(buf, string("(", join(defs, ", "), "$s )"))
    newline(buf)
    print(out, takebuf_string(buf))
end

# function return_type(method::cindex.Constructor)
#     return cindex.getCursorLexicalParent(method)
# end

function wrapjl(out::IO, libname::String, method::cindex.Constructor, id::Int)
    buf = IOBuffer()

    methodname = spelling(method)
    parentdecl = cindex.getCursorLexicalParent(method)
    parentname = spelling(parentdecl)

    args = get_args(method)
    defs = cindex.function_arg_defaults(method)
    if (!check_args(args)) return end                       # TODO: warning?

    print(buf, "@constructor")                                   # emit Julia call
    space(buf)
    print(buf, libname)                                  # parent class
    space(buf)
    print(buf, parentname)                                  # parent class
    space(buf)
    openparen(buf)
    wrapjl_args(buf, args)                                  # arguments
    closeparen(buf)
    space(buf)
    print(buf, methodname, id)             # C name
    space(buf)
    if length(defs)>0
        s = ", "
    else
        s = ""
    end
    print(buf, string("(", join(defs, ", "), "$s )"))
    newline(buf)
    print(out, takebuf_string(buf))
end

function wrapjl(out::IO, libname::String, class::cindex.ClassDecl)
    MethodCount = Dict{String, Int}()

    for decl in [c for c in children(class)]
        declname = spelling(decl)
        if isa(decl, cindex.CXXMethod)
            id = (MethodCount[declname] = get(MethodCount, declname, 0) + 1)
            wrapjl(out, libname, decl, id)
        end
    end

    for sup in class_supers(class)
        println(out, "@subclass $(spelling(class)) $(sup.text)")
    end
end

cl_to_jl = Dict{Any,Any}(
    cindex.VoidType         => Void,
    cindex.BoolType         => Bool,
    cindex.Char_U           => UInt8,
    cindex.UChar            => :Cuchar,
    cindex.Char16           => UInt16,
    cindex.Char32           => UInt32,
    cindex.UShort           => UInt16,
    cindex.UInt             => UInt32,
    cindex.ULong            => :Culong,
    cindex.ULongLong        => :Culonglong,
    cindex.Char_S           => UInt8,
    cindex.SChar            => UInt8,
    cindex.WChar            => Char,
    cindex.Short            => Int16,
    cindex.IntType          => :Cint,
    cindex.Long             => :Clong,
    cindex.LongLong         => :Clonglong,
    cindex.Float            => :Cfloat,
    cindex.Double           => :Cdouble,
    cindex.LongDouble       => Float64,
    cindex.Enum             => :Cuint,
    cindex.NullPtr          => C_NULL,
    cindex.UInt128          => UInt128,
    cindex.FirstBuiltin     => Void,
    "size_t"                => :Csize_t,
    "ptrdiff_t"             => :Cptrdiff_t
    )


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

returns_value(m::CXXMethod) = returns_value(cu_type(m))
function returns_value(rtype::CLType)
    hasret = true
    hasret &= ~isa(rtype, VoidType)
    return hasret
end

function get_args(method::Union{cindex.CXXMethod, cindex.Constructor})
    args = CLCursor[]
    for c in children(method)
        if isa(c,cindex.ParmDecl)
            push!(args, c)
        end
    end
    return args
end

#enums are passed through the C wrapper with no special sauce
function wrap(buf::IO, cursor::EnumDecl, id::Int64=0; usename="")
end

#copy-pasted from wrap_c. TODO: unify
function wrapjl(buf::IO, libname, cursor::EnumDecl, id::Int64=0; usename="")
    if (usename == "" && (usename = get_name_namespace(cursor)) == "")
        usename = name_anon()
    end
    enumname = usename
    println(buf, "# begin enum $enumname")
    print(buf, "typealias $enumname ")
    wrapjl(buf, cindex.getEnumDeclIntegerType(cursor))
    println(buf)
    for enumitem in children(cursor)
        #cur_name = string(enumname, "_", cindex.spelling(enumitem))
        cur_name = cindex.spelling(enumitem)
        if (length(cur_name) < 1) continue end

        println(buf, "const ", cur_name, " = ", value(enumitem))
    end
    println(buf, "# end enum $enumname")
end


end # module wrap_cpp
