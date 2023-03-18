struct CLModule 
    mod::CXModule
end

Base.convert(::Type{CLModule}, x::CXModule) = CLModule(x)
Base.cconvert(::Type{CXModule}, x::CLModule) = x
Base.unsafe_convert(::Type{CXModule}, x::CLModule) = x.mod

Base.show(io::IO, x::CLModule) = print(io, "CLModule ($(full_name(x)))")


function get_module(tu::TranslationUnit, file::CLFile)::CLModule
    return Clang.clang_getModuleForFile(tu, file)
end

function ast_file(mod::CLModule)::CLFile
    return Clang.clang_Module_getASTFile(mod)
end

function parent_module(mod::CLModule)::CLModule
    return Clang.clang_Module_getParent(mod)
end

function name(mod::CLModule)
    return Clang.clang_Module_getName(mod) |> _cxstring_to_string
end

function full_name(mod::CLModule)
    return Clang.clang_Module_getFullName(mod) |> _cxstring_to_string
end

function is_system(mod::CLModule)
    return Bool(Clang.clang_Module_isSystem(mod))
end

function toplevel_headers(tu::TranslationUnit, mod::CLModule)
    num = Clang.clang_Module_getNumTopLevelHeaders(tu, mod)
    headers = Vector{CLFile}(undef, num)
    for i=1:num
        headers[i] = Clang.clang_Module_getTopLevelHeader(tu, mod, i-1)  
    end
    return headers
end
