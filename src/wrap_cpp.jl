module wrap_cpp

using Clang.cindex

export @vcall, @scall, @mcall

function method_vt_index(cursor::cindex.CXCursor)
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

# Get function pointer from vtable at given offset
#derefptr(thisptr::Ptr{Void}, vtidx) = unsafe_ref(unsafe_ref(pointer(Ptr{Ptr{Void}},thisptr)), vtidx)

# Static method call
macro scall(ret_type, func, arg_types, sym, lib)
  local _args_in = Any[ symbol(string('a',x)) for x in 1:length(arg_types.args) ]
  hdl = dlopen(string(lib))
  fptr = dlsym_e(hdl, sym)
  if (fptr==C_NULL) return end
  quote
    function $(esc(func))($(_args_in...))
      ccall( $(esc(fptr)), $(esc(ret_type)), $(esc(arg_types)), $(_args_in...) )
    end
  end
end

# Member function call (takes this* but is not virtual)
macro mcall(ret_type, func, arg_types, sym, lib)
  local _args_in = Any[ symbol(string('a',x)) for x in 1:length(arg_types.args) ]
  larg_types = :((Ptr{Void}, $(arg_types.args...)))
  hdl = dlopen(string(lib))
  fptr = dlsym_e(hdl,sym)
  quote
    function $(esc(func))(thisptr, $(_args_in...))
      ccall( $(fptr), thiscall, $(esc(ret_type)), $(esc(larg_types)), thisptr, $(_args_in...) )
    end
  end
end

# Virtual table call
macro vcall(vtidx, ret_type, func, arg_types, classname)
  local _args_in = Any[ symbol(string('a',x)) for x in 1:length(arg_types.args) ]
  larg_types = :((Ptr{$(classname)}, $(arg_types.args...)))
  quote
    function $(esc(func)){T <: $(esc(classname))}(thisptr::Ptr{T}, $(_args_in...))
      local fptr =  unsafe_ref(unsafe_ref(pointer(Ptr{Ptr{Void}},thisptr)), $(vtidx)+1)
      println("fptr: ", fptr, "\n")
      ccall( fptr, thiscall, $(esc(ret_type)), $(esc(larg_types)), thisptr, $(_args_in...) )
    end
  end
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
