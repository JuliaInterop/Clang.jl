module wrap_cpp

using Clang.cindex

export @vcall, @scall

function method_vt_index(cursor::cindex.CXCursor)
  ccall( ("wci_getCXXMethodVTableIndex", :libwrapclang), Int32, (Ptr{Uint8},), cursor.data)
end

function method_mangled_name(cursor::cindex.CXCursor)
  bufr = zeros(Uint8, 1024)
  ccall( ("wci_getCXXMethodMangledName", :libwrapclang), Int32, (Ptr{Uint8},Ptr{Uint8}), cursor.data, bufr)
  bytestring(convert(Ptr{Uint8},bufr))
end

# Get function pointer from vtable at given offset
vtblfunc(p::Ptr{Void}, offset) = pointer(Void, unsafe_ref(pointer(Uint64, unsafe_ref(pointer(Uint64,p))))+offset )

macro vcall(vtidx, ret_type, func, arg_types)
  local _args_in = Any[ symbol(string('a',x)) for x in 1:length(arg_types.args) ]
  local _arg_types = tuple(:(Ptr{Void}), arg_types.args...)
  quote
    function $(esc(func))(thisptr, $(_args_in...))
      fptr = vtblfunc(thisptr, $(vtidx))
      ccall( fptr, thiscall, $ret_type, $arg_types, $(_args_in...) )
    end
  end
end

macro scall(ret_type, func, arg_types, sym, lib)
  local _args_in = Any[ symbol(string('a',x)) for x in 1:length(arg_types.args) ]
  hdl = dlopen(string(lib))
  fptr = dlsym(hdl, sym)
  quote
    function $(esc(func))($(_args_in...))
      ccall( $(esc(fptr)), $ret_type, $arg_types, $(_args_in...) )
    end
  end
end


end # module wrap_cpp
