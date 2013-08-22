module wrap_cpp

using Clang.cindex

export @vcall, @scall, @mcall

function method_vt_index(cursor::cindex.CXCursor)
    if !(cindex.CXXMethod_isVirtual(cursor) == 1)
        return -1
    end
    ccall( ("wci_getCXXMethodVTableIndex", :libwrapclang), Int32, (Ptr{Uint8},), cursor.data)
end

function method_mangled_name(cursor::cindex.CXCursor)
    bufr = zeros(Uint8, 1024)
    ccall( ("wci_getCXXMethodMangledName", :libwrapclang), Int32, (Ptr{Uint8},Ptr{Uint8}), cursor.data, bufr)
    bytestring(convert(Ptr{Uint8},bufr))
end


function cxxclass_cb(cursor::Ptr{Uint8}, data::Ptr{Void})
    cu = CXCursor()
    ccall(:memcpy, Void, (Ptr{Void},Ptr{Void}, Uint), cu.data, cursor, cindex.CXCursor_size)    
    holder = unsafe_pointer_to_objref(data)
    push!(holder, cu)
    return int(0)
end

function base_class(cursor::cindex.CXCursor)
    cb = cfunction(cxxclass_cb, Int, (Ptr{Uint8},Ptr{Void}))
    temp = CXCursor[]
    ccall( ("wci_getCXXClassParents", :libwrapclang), Int32, (Ptr{Uint8}, Ptr{Void}, Ptr{Void}), cursor.data, cb, pointer_from_objref(temp))
    if (length(temp) < 1) return None end
    return temp[1] # TODO: don't assume single inheritance...
end

function find_sym(name,liblist)
    libs = {dlopen(l)=>l for l in liblist}
    found = false
    dl = C_NULL
    for dl in keys(libs)
        try
            dlsym_e(dl, name)
        catch
            continue
        end
        found = true
    end
    if found
        println("symbol $name found in ", libs[dl])
        return splitdir(libs[dl])[end]
    else
        return None
        println("NOT FOUND")
    end
end

end # module wrap_cpp
