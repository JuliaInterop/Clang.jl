# for manipulating CXTypes

Base.:(==)(t1::CXType, t2::CXType) = clang_equalTypes(t1, t2) != 0

"""
    canonical(t::CXType) -> CXType
Return the canonical type for a CXType.

Clang's type system explicitly models typedefs and all the ways a specific type can be
represented. The canonical type is the underlying type with all the "sugar" removed.
For example, if 'T' is a typedef for 'int', the canonical type for 'T' would be 'int'.
"""
canonical(t::CXType) = clang_getCanonicalType(t)

"""
    isconst(t::CXType) -> Bool
Determine whether a CXType has the "const" qualifier set, without looking through typedefs
that may have added "const" at a different level.
"""
Base.isconst(t::CXType)::Bool = clang_isConstQualifiedType(t)

"""
    isvolatile(t::CXType) -> Bool
Determine whether a CXType has the "volatile" qualifier set, without looking through typedefs
that may have added "volatile" at a different level.
"""
isvolatile(t::CXType)::Bool = clang_isVolatileQualifiedType(t)

"""
    isrestrict(t::CXType) -> Bool
Determine whether a CXType has the "restrict" qualifier set, without looking through typedefs
that may have added "restrict" at a different level.
"""
isrestrict(t::CXType)::Bool = clang_isRestrictQualifiedType(t)

"""
    address_space(t::CXType)
Returns the address space of the given type.
"""
address_space(t::CXType) = clang_getAddressSpace(t)

"""
    typedef_name(t::CXType) -> String
Return the typedef name of the given type.
"""
function typedef_name(t::CXType)
    GC.@preserve t begin
        cxstr = clang_getTypedefName(t)
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end

"""
    pointee_type(t::CXType) -> CXType
Return the type of the pointee for pointer types.
"""
pointee_type(t::CXType) = clang_getPointeeType(t)

"""
    typedecl(t::CXType) -> CXCursor
Return the cursor for the declaration of the given type. To get the type of the cursor,
see [`type`](@ref).
"""
typedecl(t::CXType) = clang_getTypeDeclaration(t)

"""
    spelling(t::CXType) -> String
Pretty-print the underlying type using the rules of the language of the translation unit
from which it came. If the type is invalid, an empty string is returned.
"""
function spelling(t::CXType)
    GC.@preserve t begin
        cxstr = clang_getTypeSpelling(t)
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end

"""
    spelling(kind::CXTypeKind) -> String
Return the spelling of a given CXTypeKind.
"""
function spelling(kind::CXTypeKind)
    GC.@preserve kind begin
        cxstr = clang_getTypeKindSpelling(kind)
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end

"""
    calling_conv(t::CXType) -> CXCallingConv
Return the calling convention associated with a function type.
"""
calling_conv(t::CXType)::CXCallingConv = _calling_conv(Val(kind(t)), t)
_calling_conv(::Val{CXType_FunctionNoProto}, t::CXType) = clang_getFunctionTypeCallingConv(t)
_calling_conv(::Val{CXType_FunctionProto}, t::CXType) = clang_getFunctionTypeCallingConv(t)

"""
    result_type(t::CXType) -> CXType
Return the return type associated with a function type.
"""
result_type(t::CXType) = _result_type(Val(kind(t)), t)
_result_type(::Val{CXType_FunctionNoProto}, t::CXType) = clang_getResultType(t)
_result_type(::Val{CXType_FunctionProto}, t::CXType) = clang_getResultType(t)

## TODO:
# clang_getExceptionSpecificationType

"""
    argnum(t::CXType) -> Int
Return the number of non-variadic parameters associated with a function type.
"""
argnum(t::CXType)::Int = _argnum(Val(kind(t)), t)
_argnum(::Val{CXType_FunctionNoProto}, t::CXType) = clang_getNumArgTypes(t)
_argnum(::Val{CXType_FunctionProto}, t::CXType) = clang_getNumArgTypes(t)

"""
    argtype(t::CXType, i::Integer) -> CXType
Return the type of a parameter of a function type.
"""
argtype(t::CXType, i::Integer) = _argtype(Val(kind(t)), t, Unsigned(i))
_argtype(::Val{CXType_FunctionNoProto}, t::CXType, i::Unsigned) = clang_getArgType(t, i)
_argtype(::Val{CXType_FunctionProto}, t::CXType, i::Unsigned) = clang_getArgType(t, i)

"""
    isvariadic(t::CXType) -> Bool
Return true if the CXType is a variadic function type.
"""
isvariadic(t::CXType)::Bool = clang_isFunctionTypeVariadic(t)

"""
    is_plain_old_data(t::CXType) -> Bool
Return true if the CXType is a plain old data type.
"""
is_plain_old_data(t::CXType)::Bool = clang_isPODType(t)

"""
    element_type(t::CXType) -> CXType
Return the element type of an array, complex, or vector type.
"""
element_type(t::CXType) = _element_type(Val(kind(t)), t)
_element_type(::Val{CXType_Vector}, t::CXType) = clang_getElementType(t)
_element_type(::Val{CXType_ConstantArray}, t::CXType) = clang_getElementType(t)
_element_type(::Val{CXType_IncompleteArray}, t::CXType) = clang_getElementType(t)
_element_type(::Val{CXType_VariableArray}, t::CXType) = clang_getElementType(t)
_element_type(::Val{CXType_DependentSizedArray}, t::CXType) = clang_getElementType(t)
_element_type(::Val{CXType_Complex}, t::CXType) = clang_getElementType(t)
# old API: clang_getArrayElementType

"""
    element_num(t::CXType) -> Int
Return the number of elements of an array or vector type.
"""
element_num(t::CXType)::Int = _element_num(Val(kind(t)), t)
_element_num(::Val{CXType_Vector}, t::CXType) = clang_getNumElements(t)
_element_num(::Val{CXType_ConstantArray}, t::CXType) = clang_getNumElements(t)
_element_num(::Val{CXType_IncompleteArray}, t::CXType) = clang_getNumElements(t)
_element_num(::Val{CXType_VariableArray}, t::CXType) = clang_getNumElements(t)
_element_num(::Val{CXType_DependentSizedArray}, t::CXType) = clang_getNumElements(t)
# old API: clang_getArraySize

"""
    get_named_type(t::CXType) -> CXType
Return the type named by the qualified-id.
"""
get_named_type(t::CXType) = _get_named_type(Val(kind(t)), t)
_get_named_type(::Val{CXType_Elaborated}, t::CXType) = clang_Type_getNamedType(t)


## TODO:
# clang_Type_isTransparentTagTypedef
# clang_Type_getAlignOf
# clang_Type_getClassType
# clang_Type_getSizeOf
# clang_Type_getOffsetOf
# clang_Type_getNumTemplateArguments
# clang_Type_getTemplateArgumentAsType
# clang_Type_getCXXRefQualifier
#


# helper
"""
    kind(t::CXType) -> CXTypeKind
Return the kind of the given type.
"""
kind(t::CXType) = CXTypeKind(t.kind)

"""
    isvalid(t::CXType) -> Bool
Return true if the type is a valid type.
"""
isvalid(t::CXType) = kind(t) != CXType_Invalid

"""
    resolve_type(t::CXType) -> CXType
This function attempts to work around some limitations of the current libclang API.
"""
function resolve_type(t::CXType)
    if kind(t) == CXType_Unexposed
        # try to resolve Unexposed type to cursor definition.
        cursor = typedecl(t)
        if !isnull(cursor) && kind(cursor) != CXCursor_NoDeclFound
            return type(cursor)
        end
    end
    # otherwise, this will either be a builtin or unexposed client needs to sort out.
    return t
end
