Base.:(==)(t1::CXType, t2::CXType) = clang_equalTypes(t1, t2) != 0

"""
    getCanonicalType(t::CXType) -> CXType
    getCanonicalType(t::CLType) -> CLType
Return the canonical type for a CXType.

Clang's type system explicitly models typedefs and all the ways a specific type can be
represented. The canonical type is the underlying type with all the "sugar" removed.
For example, if 'T' is a typedef for 'int', the canonical type for 'T' would be 'int'.
Wrapper for libclang's [`clang_getCanonicalType`](@ref).
"""
getCanonicalType(t::CXType) = clang_getCanonicalType(t)
getCanonicalType(t::CLType)::CLType = clang_getCanonicalType(t)

"""
    isConstQualifiedType(t::Union{CXType,CLType}) -> Bool
Determine whether a CXType has the "const" qualifier set, without looking through typedefs
that may have added "const" at a different level.
Wrapper for libclang's [`clang_isConstQualifiedType`](@ref).
"""
isConstQualifiedType(t::Union{CXType,CLType})::Bool = clang_isConstQualifiedType(t)

"""
    isVolatileQualifiedType(t::Union{CXType,CLType}) -> Bool
Determine whether a CXType has the "volatile" qualifier set, without looking through typedefs
that may have added "volatile" at a different level.
Wrapper for libclang's [`clang_isVolatileQualifiedType`](@ref).
"""
isVolatileQualifiedType(t::CXType)::Bool = clang_isVolatileQualifiedType(t)

"""
    isRestrictQualifiedType(t::Union{CXType,CLType}) -> Bool
Determine whether a CXType has the "restrict" qualifier set, without looking through typedefs
that may have added "restrict" at a different level.
Wrapper for libclang's [`clang_isRestrictQualifiedType`](@ref).
"""
isRestrictQualifiedType(t::Union{CXType,CLType})::Bool = clang_isRestrictQualifiedType(t)

"""
    getAddressSpace(t::Union{CXType,CLType})
Returns the address space of the given type.
Wrapper for libclang's [`clang_getAddressSpace`](@ref).
"""
getAddressSpace(t::Union{CXType,CLType}) = clang_getAddressSpace(t)

"""
    getTypedefName(t::Union{CXType,CLType}) -> String
Return the typedef name of the given type.
Wrapper for libclang's [`clang_getTypedefName`](@ref).
"""
function getTypedefName(t::Union{CXType,CLType})
    cxstr = clang_getTypedefName(t)
    ptr = clang_getCString(cxstr)
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    return s
end

"""
    getPointeeType(t::CXType) -> CXType
    getPointeeType(t::CLType) -> CLType
Return the type of the pointee for pointer types.
Wrapper for libclang's [`clang_getPointeeType`](@ref).
"""
getPointeeType(t::CXType) = clang_getPointeeType(t)
getPointeeType(t::CLType)::CLType = clang_getPointeeType(t)

"""
    getObjCObjectBaseType(T::CXType) -> CXType
    getObjCObjectBaseType(T::CLType) -> CLType
Retrieves the base type of the ObjCObjectType.
If the type is not an ObjC object, an invalid type is returned.
Wrapper for libclang's [`clang_Type_getObjCObjectBaseType`](@ref).
"""
getObjCObjectBaseType(t::CXType) = clang_Type_getObjCObjectBaseType(t)
getObjCObjectBaseType(t::CLType)::CLType = clang_Type_getObjCObjectBaseType(t)

"""
    getDeclObjCTypeEncoding(C::CXCursor)::CXString
    getDeclObjCTypeEncoding(C::CLCursor)::String
Returns the Objective-C type encoding for the specified declaration.
Wrapper for libclang's [`clang_getDeclObjCTypeEncoding`](@ref).
"""
getDeclObjCTypeEncoding(c::CXCursor) = clang_getDeclObjCTypeEncoding(c)
function getDeclObjCTypeEncoding(c::CLCursor)::String
        cxstr = clang_getDeclObjCTypeEncoding(c)
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
        return s
end

"""
    getNumObjCProtocolRefs(T::Union{CXType, CLType})::Cuint

Retrieve the number of protocol references associated with an ObjC object/id.

If the type is not an ObjC object, 0 is returned.
"""
function getNumObjCProtocolRefs(T::Union{CXType, CLType})
    clang_Type_getNumObjCProtocolRefs(T)::Cuint
end

"""
    getObjCProtocolDecl(T::CXType, i) -> CLCursor
    getObjCProtocolDecl(T::CLType, i) -> CXCursor

Retrieve the decl for a protocol reference for an ObjC object/id.

If the type is not an ObjC object or there are not enough protocol references, an invalid cursor is returned.
"""
getObjCProtocolDecl(T::CXType, i) = clang_Type_getObjCProtocolDecl(T, i)
getObjCProtocolDecl(T::CLType, i)::CLCursor = clang_Type_getObjCProtocolDecl(T, i)

function getObjCProtocolDecls(T::CLType)::Vector{CLCursor}
    n_refs = getNumObjCProtocolRefs(T)
    return [getObjCProtocolDecl(T,i-1) for i in 1:n_refs]
end

"""
    getNumObjCTypeArgs(T::Union{CXType, CLType})::Cuint

Retrieve the number of type arguments associated with an ObjC object.

If the type is not an ObjC object, 0 is returned.
"""
getNumObjCTypeArgs(T::Union{CXType, CLType}) = clang_Type_getNumObjCTypeArgs(T)

"""
    getObjCTypeArg(T::CXType, i) -> CXType
    getObjCTypeArg(T::CLType, i) -> CLType

Retrieve a type argument associated with an ObjC object.

If the type is not an ObjC or the index is not valid, an invalid type is returned.
"""
getObjCTypeArg(T::CXType, i) = clang_Type_getObjCTypeArg(T, i)
getObjCTypeArg(T::CLType, i)::CLType = clang_Type_getObjCTypeArg(T, i)

function getObjCTypeArgs(T::CLType)::Vector{CLType}
    n_refs = getNumObjCTypeArgs(T)
    return [getObjCTypeArg(T,i-1) for i in 1:n_refs]
end

"""
    getObjCEncoding(T::CXType) -> String
    getObjCEncoding(T::CLType) -> String
Returns the Objective-C type encoding for the specified `Type`.
Wrapper for libclang's [`clang_Type_getObjCEncoding`](@ref).
"""
function getObjCEncoding(c::CLType)
    cxstr = clang_Type_getObjCEncoding(c)
    ptr = clang_getCString(cxstr)
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    return s
end

"""
    getTypeDeclaration(t::CXType) -> CXCursor
    getTypeDeclaration(t::CLType) -> CLCursor
Return the cursor for the declaration of the given type. To get the type of the cursor,
see [`getCursorType`](@ref). Wrapper for libclang's [`clang_getTypeDeclaration`](@ref).
"""
getTypeDeclaration(t::CXType) = clang_getTypeDeclaration(t)
getTypeDeclaration(t::CLType)::CLCursor = clang_getTypeDeclaration(t)

"""
    getFunctionTypeCallingConv(t::Union{CXType,CLFunctionNoProto,CLFunctionProto}) -> CXCallingConv
Return the calling convention associated with a function type.
Wrapper for libclang's [`clang_getFunctionTypeCallingConv`](@ref).
"""
getFunctionTypeCallingConv(t::Union{CXType,CLFunctionNoProto,CLFunctionProto})::CXCallingConv = clang_getFunctionTypeCallingConv(t)

"""
    getCursorResultType(t::CXType) -> CXType
    getCursorResultType(t::Union{CLFunctionNoProto,CLFunctionProto}) -> CLType
Return the return type associated with a function type.
Wrapper for libclang's [`clang_getResultType`](@ref).
"""
getCursorResultType(t::CXType) = clang_getResultType(t)
getCursorResultType(t::Union{CLFunctionNoProto,CLFunctionProto})::CLType = clang_getResultType(t)

## TODO:
# clang_getExceptionSpecificationType

"""
    getNumArguments(t::Union{CXType,CLFunctionNoProto,CLFunctionProto}) -> Int
Return the number of non-variadic parameters associated with a function type.
Wrapper for libclang's [`clang_getNumArgTypes`](@ref).
"""
getNumArguments(t::Union{CXType,CLFunctionNoProto,CLFunctionProto,CLUnexposed})::Int = clang_getNumArgTypes(t)

"""
    getArgType(t::CXType, i::Unsigned) -> CXType
    getArgType(t::Union{CLFunctionNoProto,CLFunctionProto}, i::Integer) -> CLType
Return the type of a parameter of a function type.
Wrapper for libclang's [`clang_getArgType`](@ref).
"""
getArgType(t::CXType, i::Unsigned) = clang_getArgType(t, Unsigned(i))
getArgType(t::Union{CLFunctionNoProto,CLFunctionProto,CLUnexposed}, i::Integer)::CLType = getArgType(t.type, Unsigned(i))

"""
    isVariadic(t::Union{CXType,CLType}) -> Bool
Return true if the CXType is a variadic function type.
Wrapper for libclang's [`clang_isFunctionTypeVariadic`](@ref).
"""
isVariadic(t::Union{CXType,CLType})::Bool = clang_isFunctionTypeVariadic(t)

"""
    isPODType(t::Union{CXType,CLType}) -> Bool
Return true if the CXType is a plain old data type.
Wrapper for libclang's [`clang_isPODType`](@ref).
"""
isPODType(t::CXType)::Bool = clang_isPODType(t)

"""
    getElementType(t::CXType) -> CXType
    getElementType(t::Union{CLVector,CLConstantArray,CLIncompleteArray,CLVariableArray,CLDependentSizedArray,CLComplex}) -> CLType
Return the element type of an array, complex, or vector type.
Wrapper for libclang's [`clang_getElementType`](@ref).
"""
getElementType(t::CXType) = clang_getElementType(t)
getElementType(t::Union{CLVector,CLConstantArray,CLIncompleteArray,CLVariableArray,CLDependentSizedArray,CLComplex})::CLType = clang_getElementType(t)
# old API: clang_getArrayElementType

"""
    getNumElements(t::Union{CXType,CLVector,CLConstantArray,CLIncompleteArray,CLVariableArray,CLDependentSizedArray}) -> Int
Return the number of elements of an array or vector type.
Wrapper for libclang's [`clang_getNumElements`](@ref).
"""
getNumElements(t::Union{CXType,CLVector,CLConstantArray,CLIncompleteArray,CLVariableArray,CLDependentSizedArray})::Int = clang_getNumElements(t)
# old API: clang_getArraySize

"""
    getNamedType(t::CXType) -> CXType
    getNamedType(t::CLElaborated) -> CLType
Return the type named by the qualified-id.
Wrapper for libclang's [`clang_Type_getNamedType`](@ref).
"""
getNamedType(t::CXType) = clang_Type_getNamedType(t)
getNamedType(t::CLElaborated)::CLType = clang_Type_getNamedType(t)

"""
    getSizeOf(t::CXType) -> Int
    getSizeOf(t::CLType) -> Int
Return the size of a type in bytes as per C++[expr.sizeof] standard,

It returns a minus number for layout errors, please convert the result to
a [`CXTypeLayoutError`](@ref) to see what the error is.
"""
getSizeOf(t::CXType)::Int = clang_Type_getSizeOf(t)
getSizeOf(t::CLType) = getSizeOf(t.type)

"""
    getAlignOf(t::CXType) -> Int
    getAlignOf(t::CLType) -> Int
Return the alignment of a type in bytes as per C++[expr.alignof] standard.

It returns a minus number for layout errors, please convert the result to
a [`CXTypeLayoutError`](@ref) to see what the error is.
"""
getAlignOf(t::CXType)::Int = clang_Type_getAlignOf(t)
getAlignOf(t::CLType) = getAlignOf(t.type)

"""
    getOffsetOf(t::CXType, s) -> Int
    getOffsetOf(t::CLType, s::AbstractString) -> Int
Return the offset of a field named S in a record of type T in bits as it
would be returned by __offsetof__ as per C++11[18.2p4].

It returns a minus number for layout errors, please convert the result to
a [`CXTypeLayoutError`](@ref) to see what the error is.
"""
getOffsetOf(t::CXType, s)::Int = clang_Type_getOffsetOf(t, s)
getOffsetOf(t::CLType, s::AbstractString) = getOffsetOf(t.type, s)

"""
    isInvalid(t::CXType) -> Bool
    isInvalid(t::CLType) -> Bool
Return true if the type is a valid type.
"""
isInvalid(t::CXType) = kind(t) != CXType_Invalid
isInvalid(t::CLType) = isInvalid(t.type)

## TODO:
# clang_Type_isTransparentTagTypedef (ObjectiveC)
# clang_Type_getClassType (C++)
# clang_Type_getNumTemplateArguments (C++)
# clang_Type_getTemplateArgumentAsType (C++)
# clang_Type_getCXXRefQualifier (C++)
#

# helper
"""
    kind(t::CXType) -> CXTypeKind
    kind(t::CLType) -> CXTypeKind
Return the kind of the given type.
"""
kind(t::CXType) = t.kind
kind(t::CLType) = kind(t.type)

"""
    spelling(t::Union{CXType,CLType}) -> String
Pretty-print the underlying type using the rules of the language of the translation unit
from which it came. If the type is invalid, an empty string is returned.
Wrapper for libclang's [`clang_getTypeSpelling`](@ref).
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

# visitor
function ct_field_visitor(cursor::CXCursor, list)::CXVisitorResult
    push!(list, cursor)
    return CXVisit_Continue
end

"""
    fields(ty::CXType) -> Vector{CXCursor}
    fields(ty::CLType) -> Vector{CLCursor}
Return a child cursor vector of the given cursor.
"""
function fields(ty::CXType)
    list = CXCursor[]
    ct_visitor_cb = @cfunction(
        ct_field_visitor, CXVisitorResult, (CXCursor, Ref{Vector{CXCursor}})
    )
    GC.@preserve list ccall(
        (:clang_Type_visitFields, LibClang.libclang),
        UInt32,
        (CXType, CXFieldVisitor, Any),
        ty,
        ct_visitor_cb,
        list,
    )
    return list
end
fields(ty::CLType)::Vector{CLCursor} = fields(ty.type)

is_elaborated(ty::CXType) = kind(ty) == CXType_Elaborated
is_elaborated(ty::CLType) = is_elaborated(ty.type)

"""
    has_elaborated_reference(ty::CLType) -> Bool
    has_elaborated_reference(ty::CXType) -> Bool
Return true if the type is an elaborated type or the type indirectly refers to an
elaborated type.
"""
function has_elaborated_reference(ty::CXType)
    if kind(ty) == CXType_Pointer
        ptreety = getPointeeType(ty)
        return has_elaborated_reference(ptreety)
    elseif kind(ty) == CXType_ConstantArray || kind(ty) == CXType_IncompleteArray
        elty = getElementType(ty)
        return has_elaborated_reference(elty)
    else
        return is_elaborated(ty)
    end
end
has_elaborated_reference(ty::CLType) = has_elaborated_reference(ty.type)


"""
    has_elaborated_tag_reference(ty::CLType) -> Bool
    has_elaborated_tag_reference(ty::CXType) -> Bool
Return true if the type is an elaborated tag type or the type indirectly refers to an
elaborated tag type.
"""
function has_elaborated_tag_reference(ty::CXType)
    if kind(ty) == CXType_Pointer
        ptreety = getPointeeType(ty)
        return has_elaborated_tag_reference(ptreety)
    elseif kind(ty) == CXType_ConstantArray || kind(ty) == CXType_IncompleteArray
        elty = getElementType(ty)
        return has_elaborated_tag_reference(elty)
    elseif is_elaborated(ty)
        nty = getNamedType(ty)
        if kind(nty) == CXType_Enum || kind(nty) == CXType_Record
            return true
        else
            return has_elaborated_tag_reference(nty)
        end
    else
        return false
    end
end
has_elaborated_tag_reference(ty::CLType) = has_elaborated_tag_reference(ty.type)



"""
    get_elaborated_cursor(ty::CLType) -> CLCursor
    get_elaborated_cursor(ty::CXType) -> CXCursor
Return the cursor of the elaborated type that is referenced by the input type.
The input type can be a pointer/array.
This function returns [`clang_getNullCursor`](@ref) if the input type is not refer to an
elaborated type.
"""
function get_elaborated_cursor(ty::CXType)
    if kind(ty) == CXType_Pointer
        ptreety = getPointeeType(ty)
        return get_elaborated_cursor(ptreety)
    elseif kind(ty) == CXType_ConstantArray || kind(ty) == CXType_IncompleteArray
        elty = getElementType(ty)
        return get_elaborated_cursor(elty)
    elseif is_elaborated(ty)
        return getTypeDeclaration(ty)
    else
        return getNullCursor()
    end
end
get_elaborated_cursor(ty::CLType)::CLCursor = get_elaborated_cursor(ty.type)

function is_function(ty::CXType)
    canonical_ty = kind(ty) == CXType_Typedef ? getCanonicalType(ty) : ty
    k = kind(canonical_ty)
    return k == CXType_FunctionProto || k == CXType_FunctionNoProto
end
is_function(ty::CLType) = is_function(ty.type)

"""
    has_function_reference(ty::CLType) -> Bool
    has_function_reference(ty::CXType) -> Bool
Return true if the type is a function or the type indirectly refers to a function.
"""
function has_function_reference(ty::CXType)
    if kind(ty) == CXType_Pointer
        ptreety = getPointeeType(ty)
        return has_function_reference(ptreety)
    elseif kind(ty) == CXType_ConstantArray || kind(ty) == CXType_IncompleteArray
        elty = getElementType(ty)
        return has_function_reference(elty)
    else
        return is_function(ty)
    end
end
has_function_reference(ty::CLType) = has_function_reference(ty.type)
