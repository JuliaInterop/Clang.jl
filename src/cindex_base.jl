libwci = "./libwrapcindex.so"
function getCursorType(a1::CXCursor,)
  c = CXType()
  ccall( (:wci_getCursorType, libwci), Void, (Ptr{Void},Ptr{Void}), a1.data, c.data,)
  return c
end
function getCursorKind(a1::CXCursor,)
  ccall( (:wci_getCursorKind, libwci), Int32, (Ptr{Void},), a1.data, )
end
function isPODType(a1::CXType,)
  ccall( (:wci_isPODType, libwci), Int32, (Ptr{Void},), a1.data, )
end
function getTypeKindSpelling(a1::CXTypeKind,)
  c = CXString()
  ccall( (:wci_getTypeKindSpelling, libwci), Void, (CXTypeKind,Ptr{Void}), a1, c.data,)
  return get_string(c)
end
function CXXMethod_isStatic(a1::CXCursor,)
  ccall( (:wci_CXXMethod_isStatic, libwci), Uint32, (Ptr{Void},), a1.data, )
end
function Cursor_getArgument(a1::CXCursor,a2::Int32,)
  c = CXCursor()
  ccall( (:wci_Cursor_getArgument, libwci), Void, (Ptr{Void},Int32,Ptr{Void}), a1.data,a2, c.data,)
  return c
end
function getTypedefDeclUnderlyingType(a1::CXCursor,)
  c = CXType()
  ccall( (:wci_getTypedefDeclUnderlyingType, libwci), Void, (Ptr{Void},Ptr{Void}), a1.data, c.data,)
  return c
end
function getCursorLexicalParent(a1::CXCursor,)
  c = CXCursor()
  ccall( (:wci_getCursorLexicalParent, libwci), Void, (Ptr{Void},Ptr{Void}), a1.data, c.data,)
  return c
end
function getEnumDeclIntegerType(a1::CXCursor,)
  c = CXType()
  ccall( (:wci_getEnumDeclIntegerType, libwci), Void, (Ptr{Void},Ptr{Void}), a1.data, c.data,)
  return c
end
function getEnumConstantDeclValue(a1::CXCursor,)
  ccall( (:wci_getEnumConstantDeclValue, libwci), Int64, (Ptr{Void},), a1.data, )
end
function getEnumConstantDeclUnsignedValue(a1::CXCursor,)
  ccall( (:wci_getEnumConstantDeclUnsignedValue, libwci), Uint64, (Ptr{Void},), a1.data, )
end
function Cursor_getNumArguments(a1::CXCursor,)
  ccall( (:wci_Cursor_getNumArguments, libwci), Int32, (Ptr{Void},), a1.data, )
end
function getCursorSpelling(a1::CXCursor,)
  c = CXString()
  ccall( (:wci_getCursorSpelling, libwci), Void, (Ptr{Void},Ptr{Void}), a1.data, c.data,)
  return get_string(c)
end
function getCursorDisplayName(a1::CXCursor,)
  c = CXString()
  ccall( (:wci_getCursorDisplayName, libwci), Void, (Ptr{Void},Ptr{Void}), a1.data, c.data,)
  return get_string(c)
end
function getCursorReferenced(a1::CXCursor,)
  c = CXCursor()
  ccall( (:wci_getCursorReferenced, libwci), Void, (Ptr{Void},Ptr{Void}), a1.data, c.data,)
  return c
end
function getCursorDefinition(a1::CXCursor,)
  c = CXCursor()
  ccall( (:wci_getCursorDefinition, libwci), Void, (Ptr{Void},Ptr{Void}), a1.data, c.data,)
  return c
end
function isCursorDefinition(a1::CXCursor,)
  ccall( (:wci_isCursorDefinition, libwci), Uint32, (Ptr{Void},), a1.data, )
end
function getCanonicalCursor(a1::CXCursor,)
  c = CXCursor()
  ccall( (:wci_getCanonicalCursor, libwci), Void, (Ptr{Void},Ptr{Void}), a1.data, c.data,)
  return c
end
function CXXMethod_isVirtual(a1::CXCursor,)
  ccall( (:wci_CXXMethod_isVirtual, libwci), Uint32, (Ptr{Void},), a1.data, )
end
function getTemplateCursorKind(a1::CXCursor,)
  ccall( (:wci_getTemplateCursorKind, libwci), Uint32, (Ptr{Void},), a1.data, )
end
function getSpecializedCursorTemplate(a1::CXCursor,)
  c = CXCursor()
  ccall( (:wci_getSpecializedCursorTemplate, libwci), Void, (Ptr{Void},Ptr{Void}), a1.data, c.data,)
  return c
end
