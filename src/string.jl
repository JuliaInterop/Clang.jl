"Free and convert a CXString to String. Note this function will free the given CXString so ensure it is not called twice."
function _cxstring_to_string(cxstr::CXString)
    ptr = clang_getCString(cxstr)
    ptr == C_NULL && return ""
    s = unsafe_string(ptr)
    clang_disposeString(cxstr)
    return s
end
