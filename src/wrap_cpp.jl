module wrap_cpp

using Clang.cindex

function base_classes(c)
	search(c, isa(c, CurKind.CXXBaseSpecifier))
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

###############################################################################
# Extra helpers
#	These functions require libwrapclang to be compiled with
#	-DUSE_CLANG_CPP. They provide some extra information directly
#	from the Clang C++ API.
###############################################################################

function method_vt_index(cursor::cindex.CXCursor)
    if !(cindex.CXXMethod_isVirtual(cursor) == 1)
        return -1
    end
    ccall(("wci_getCXXMethodVTableIndex", :libwrapclang), Int32,
		  (Ptr{Uint8},), cursor.data)
end

function method_mangled_name(cursor::cindex.CXCursor)
    bufr = zeros(Uint8, 1024)
    ccall(("wci_getCXXMethodMangledName", :libwrapclang), Int32,
		 (Ptr{Uint8},Ptr{Uint8}), cursor.data, bufr)
    bytestring(convert(Ptr{Uint8},bufr))
end

end # module wrap_cpp
