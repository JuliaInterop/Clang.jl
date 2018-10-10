"""
    Index(excludeDeclsFromPCH, displayDiagnostics)
Provide a shared context for creating translation units.

# Arguments
- `excludeDeclsFromPCH`: whether to allow enumeration of "local" declarations.
- `displayDiagnostics`: whether to display diagnostics.
"""
mutable struct Index
    ptr::CXIndex
    excludeDeclsFromPCH::Cint
    displayDiagnostics::Cint
    function Index(excludeDeclsFromPCH, displayDiagnostics)
        ptr = clang_createIndex(excludeDeclsFromPCH, displayDiagnostics)
        @assert ptr != C_NULL
        obj = new(ptr, excludeDeclsFromPCH, displayDiagnostics)
        finalizer(obj) do x
            if x.ptr != C_NULL
                clang_disposeIndex(x.ptr)
                x.ptr = C_NULL
            end
        end
        return obj
    end
end
Index() = Index(false, true)


## TODO:
# clang_CXIndex_setGlobalOptions
# clang_CXIndex_getGlobalOptions
# clang_CXIndex_setInvocationEmissionPathOption
