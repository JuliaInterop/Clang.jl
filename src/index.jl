"""
    Index(exclude_decls_from_PCH, display_diagnostics)
Provide a shared context for creating translation units.

# Arguments
- `exclude_decls_from_PCH`: whether we only want to see "local" declarations (that did not come from a previous precompiled header). If false, we want to see all declarations.
- `display_diagnostics`: whether to display diagnostics.
"""
mutable struct Index
    ptr::CXIndex
    exclude_decls_from_PCH::Cint
    display_diagnostics::Cint
    function Index(exclude_decls_from_PCH, display_diagnostics)
        # LLVM's CrashRecoveryContext replaces all signal handlers and assumes that
        # a SIGSEGV signal is fatal, which is incompatible with language runtimes
        # like Julia / Java which use this signal as a hook for GC safepoints.
        #
        # This update to ENV is not thread-safe either. However, we don't have many
        # other options at this point, since libclang exposes no argument for this.
        if !in("LIBCLANG_DISABLE_CRASH_RECOVERY", keys(ENV))
            ENV["LIBCLANG_DISABLE_CRASH_RECOVERY"] = "1" # value doesn't matter
        end
        ptr = clang_createIndex(exclude_decls_from_PCH, display_diagnostics)
        @assert ptr != C_NULL
        obj = new(ptr, exclude_decls_from_PCH, display_diagnostics)
        finalizer(obj) do x
            if x.ptr != C_NULL
                clang_disposeIndex(x)
                x.ptr = C_NULL
            end
        end
        return obj
    end
end
Index(diagnostic::Bool) = Index(false, diagnostic)  #TODO: set `exclude_decls_from_PCH` on after adding PCH support
Index() = Index(true)

Base.unsafe_convert(::Type{CXIndex}, x::Index) = x.ptr

## TODO:
# clang_CXIndex_setGlobalOptions
# clang_CXIndex_getGlobalOptions
# clang_CXIndex_setInvocationEmissionPathOption
