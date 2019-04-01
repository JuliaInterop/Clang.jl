Base.:(==)(t1::CXType, t2::CXType) = clang_equalTypes(t1, t2) != 0

"""
    canonical(t::CXType) -> CXType
    canonical(t::CLType) -> CLType
Return the canonical type for a CXType.

Clang's type system explicitly models typedefs and all the ways a specific type can be
represented. The canonical type is the underlying type with all the "sugar" removed.
For example, if 'T' is a typedef for 'int', the canonical type for 'T' would be 'int'.
Wrapper for libclang's `clang_getCanonicalType`.
"""
canonical(t::CXType) = clang_getCanonicalType(t)
canonical(t::CLType)::CLType = clang_getCanonicalType(t)

"""
    isconst(t::Union{CXType,CLType}) -> Bool
Determine whether a CXType has the "const" qualifier set, without looking through typedefs
that may have added "const" at a different level.
Wrapper for libclang's `clang_isConstQualifiedType`.
"""
Base.isconst(t::Union{CXType,CLType})::Bool = clang_isConstQualifiedType(t)

"""
    isvolatile(t::Union{CXType,CLType}) -> Bool
Determine whether a CXType has the "volatile" qualifier set, without looking through typedefs
that may have added "volatile" at a different level.
Wrapper for libclang's `clang_isVolatileQualifiedType`.
"""
isvolatile(t::CXType)::Bool = clang_isVolatileQualifiedType(t)

"""
    isrestrict(t::Union{CXType,CLType}) -> Bool
Determine whether a CXType has the "restrict" qualifier set, without looking through typedefs
that may have added "restrict" at a different level.
Wrapper for libclang's `clang_isRestrictQualifiedType`.
"""
isrestrict(t::Union{CXType,CLType})::Bool = clang_isRestrictQualifiedType(t)

"""
    address_space(t::Union{CXType,CLType})
Returns the address space of the given type.
Wrapper for libclang's `clang_getAddressSpace`.
"""
address_space(t::Union{CXType,CLType}) = clang_getAddressSpace(t)

"""
    typedef_name(t::Union{CXType,CLType}) -> String
Return the typedef name of the given type.
Wrapper for libclang's `clang_getTypedefName`.
"""
function typedef_name(t::Union{CXType,CLType})
    cxstr = clang_getTypedefName(t)
    ptr = clang_getCString(cxstr)
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    return s
end

"""
    pointee_type(t::CXType) -> CXType
    pointee_type(t::CLType) -> CLType
Return the type of the pointee for pointer types.
Wrapper for libclang's `clang_getPointeeType`.
"""
pointee_type(t::CXType) = clang_getPointeeType(t)
pointee_type(t::CLType)::CLType = clang_getPointeeType(t)

"""
    typedecl(t::CXType) -> CXCursor
    typedecl(t::CLType) -> CLCursor
Return the cursor for the declaration of the given type. To get the type of the cursor,
see [`type`](@ref). Wrapper for libclang's `clang_getTypeDeclaration`.
"""
typedecl(t::CXType) = clang_getTypeDeclaration(t)
typedecl(t::CLType)::CLCursor = clang_getTypeDeclaration(t)

"""
    spelling(t::Union{CXType,CLType}) -> String
Pretty-print the underlying type using the rules of the language of the translation unit
from which it came. If the type is invalid, an empty string is returned.
Wrapper for libclang's `clang_getTypeSpelling`.
"""
function spelling(t::Union{CXType,CLType})
    cxstr = clang_getTypeSpelling(t)
    ptr = clang_getCString(cxstr)
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    return s
end

"""
    spelling(kind::CXTypeKind) -> String
Return the spelling of a given CXTypeKind.
"""
function spelling(kind::CXTypeKind)
    cxstr = clang_getTypeKindSpelling(kind)
    ptr = clang_getCString(cxstr)
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    return s
end

"""
    calling_conv(t::Union{CXType,CLFunctionNoProto,CLFunctionProto}) -> CXCallingConv
Return the calling convention associated with a function type.
Wrapper for libclang's `clang_getFunctionTypeCallingConv`.
"""
calling_conv(t::Union{CXType,CLFunctionNoProto,CLFunctionProto})::CXCallingConv = clang_getFunctionTypeCallingConv(t)

"""
    result_type(t::CXType) -> CXType
    result_type(t::Union{CLFunctionNoProto,CLFunctionProto}) -> CLType
Return the return type associated with a function type.
Wrapper for libclang's `clang_getResultType`.
"""
result_type(t::CXType) = clang_getResultType(t)
result_type(t::Union{CLFunctionNoProto,CLFunctionProto})::CLType = clang_getResultType(t)

## TODO:
# clang_getExceptionSpecificationType

"""
    argnum(t::Union{CXType,CLFunctionNoProto,CLFunctionProto}) -> Int
Return the number of non-variadic parameters associated with a function type.
Wrapper for libclang's `clang_getNumArgTypes`.
"""
argnum(t::Union{CXType,CLFunctionNoProto,CLFunctionProto})::Int = clang_getNumArgTypes(t)

"""
    argtype(t::CXType, i::Unsigned) -> CXType
    argtype(t::Union{CLFunctionNoProto,CLFunctionProto}, i::Integer) -> CLType
Return the type of a parameter of a function type.
Wrapper for libclang's `clang_getArgType`.
"""
argtype(t::CXType, i::Unsigned) = clang_getArgType(t, Unsigned(i))
argtype(t::Union{CLFunctionNoProto,CLFunctionProto}, i::Integer)::CLType = argtype(t.type, Unsigned(i))

"""
    isvariadic(t::Union{CXType,CLType}) -> Bool
Return true if the CXType is a variadic function type.
Wrapper for libclang's `clang_isFunctionTypeVariadic`.
"""
isvariadic(t::Union{CXType,CLType})::Bool = clang_isFunctionTypeVariadic(t)

"""
    is_plain_old_data(t::Union{CXType,CLType}) -> Bool
Return true if the CXType is a plain old data type.
Wrapper for libclang's `clang_isPODType`.
"""
is_plain_old_data(t::CXType)::Bool = clang_isPODType(t)

"""
    element_type(t::CXType) -> CXType
    element_type(t::Union{CLVector,CLConstantArray,CLIncompleteArray,CLVariableArray,CLDependentSizedArray,CLComplex}) -> CLType
Return the element type of an array, complex, or vector type.
Wrapper for libclang's `clang_getElementType`.
"""
element_type(t::CXType) = clang_getElementType(t)
element_type(t::Union{CLVector,CLConstantArray,CLIncompleteArray,CLVariableArray,CLDependentSizedArray,CLComplex})::CLType = clang_getElementType(t)
# old API: clang_getArrayElementType

"""
    element_num(t::Union{CXType,CLVector,CLConstantArray,CLIncompleteArray,CLVariableArray,CLDependentSizedArray}) -> Int
Return the number of elements of an array or vector type.
Wrapper for libclang's `clang_getNumElements`.
"""
element_num(t::Union{CXType,CLVector,CLConstantArray,CLIncompleteArray,CLVariableArray,CLDependentSizedArray})::Int = clang_getNumElements(t)
# old API: clang_getArraySize

"""
    get_named_type(t::CXType) -> CXType
    get_named_type(t::CLElaborated) -> CLType
Return the type named by the qualified-id.
Wrapper for libclang's `clang_Type_getNamedType`.
"""
get_named_type(t::CXType) = clang_Type_getNamedType(t)
get_named_type(t::CLElaborated)::CLType = clang_Type_getNamedType(t)


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
    kind(t::CLType) -> CXTypeKind
Return the kind of the given type.
"""
kind(t::CXType) = CXTypeKind(t.kind)
kind(t::CLType) = kind(t.type)

"""
    isvalid(t::CXType) -> Bool
    isvalid(t::CLType) -> Bool
Return true if the type is a valid type.
"""
isvalid(t::CXType) = kind(t) != CXType_Invalid
isvalid(t::CLType) = isvalid(t.type)

"""
    resolve_type(t::CLType) -> CLType
This function attempts to work around some limitations of the current libclang API.
"""
function resolve_type(t::CLType)::CLType
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
