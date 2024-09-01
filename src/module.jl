struct CLModule
    mod::CXModule
end

Base.convert(::Type{CLModule}, x::CXModule) = CLModule(x)
Base.cconvert(::Type{CXModule}, x::CLModule) = x
Base.unsafe_convert(::Type{CXModule}, x::CLModule) = x.mod

Base.show(io::IO, x::CLModule) = print(io, "CLModule ($(full_name(x)))")

"""
    get_module(tu::TranslationUnit, file::CLFile) -> CLModule
Given a CLFile header file, return the module that contains it, if one exists.
"""
function get_module(tu::TranslationUnit, file::CLFile)::CLModule
    return Clang.clang_getModuleForFile(tu, file)
end

"""
    ast_file(mod::CLModule) -> CLFile
Given a module, return the module file where the provided module object came from.
"""
function ast_file(mod::CLModule)::CLFile
    return Clang.clang_Module_getASTFile(mod)
end

"""
    parent_module(mod::CLModule) -> CLModule
Given a module, return the parent of a sub-module or NULL if the given module is top-level,
e.g. for 'std.vector' it will return the 'std' module.
"""
function parent_module(mod::CLModule)::CLModule
    return Clang.clang_Module_getParent(mod)
end

"""
    name(mod::CLModule)
Given a module, return the name of the module,
e.g. for the 'std.vector' sub-module it will return "vector".
"""
function name(mod::CLModule)
    return Clang.clang_Module_getName(mod) |> _cxstring_to_string
end

"""
    full_name(mod::CLModule)
Given a module, return the full name of the module, e.g. "std.vector".
"""
function full_name(mod::CLModule)
    return Clang.clang_Module_getFullName(mod) |> _cxstring_to_string
end

"""
    is_system(mod::CLModule)
Given a module, return whether it is a system one.
"""
function is_system(mod::CLModule)
    return Bool(Clang.clang_Module_isSystem(mod))
end

"""
    toplevel_headers(tu::TranslationUnit, mod::CLModule)
Given a module, return all top level headers associated with the module.
"""
function toplevel_headers(tu::TranslationUnit, mod::CLModule)
    num = Clang.clang_Module_getNumTopLevelHeaders(tu, mod)
    headers = Vector{CLFile}(undef, num)
    for i=1:num
        headers[i] = Clang.clang_Module_getTopLevelHeader(tu, mod, i-1)
    end
    return headers
end
