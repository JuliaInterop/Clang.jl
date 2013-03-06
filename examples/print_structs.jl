using Clang.cindex
import cindex.CurKind
import cindex.TypKind

is_struct(cu::CXCursor) = (cu_kind(cu) == CurKind.STRUCTDECL)
is_struct(ct::CXType) = (ty_kind(cu) == TypKind.RECORD)

#function get_td_struct(cu::CXCursor)


function get_struct(cu::CXCursor)
  if cu_kind(cu) == CurKind.STRUCTDECL
    # Stupid hack because libclang doesn't expose enough information
    # to determine whether a declaration is anonymous.
    if name(cu) != "" return cu end
  elseif cu_kind(cu) == CurKind.TYPEDEFDECL
    td = cindex.getTypedefDeclUnderlyingType(cu)
    tdcu = cindex.getTypeDeclaration(td)
    if cu_kind(tdcu) == CurKind.STRUCTDECL
      return cu
    end
  end
  return None
end

function dump_structs(cl::CursorList, restrict_hdr::Any)
  for i=1:cl.size
    cu = cl[i]
    if (restrict_hdr != None && cu_file(cu) != restrict_hdr)
      continue
    end
    cur = get_struct(cu)
    if (cur != None)
      println(i, " ", name(cur))
    end
  end
end
function dump_structs(hdr::String)
  tu = tu_init(hdr)
  topcu = tu_cursor(tu)
  topcl = children(topcu)
  dump_structs(topcl, hdr)
end
dump_structs(cl::CursorList) = dump_structs(cl, None)
