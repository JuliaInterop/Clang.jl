require("../src/cindex")
using cindex
import cindex.CurKind
import cindex.TypKind

function full_name(t::CXType)
  
  # Get the real return type through
  # typedefs and pointers. Some of this
  # is not fully exposed by libclang so
  # some extra steps are needed.

  fn = {}
  tdecl = cindex.getTypeDeclaration(t)
  if ty_kind(t) == TypKind.ENUM
    push!(fn, string(spelling(tdecl)) )
  elseif ty_kind(t) == TypKind.TYPEDEF
    td = cindex.getTypedefDeclUnderlyingType(tdecl)
    if (ty_kind(td) == TypKind.UNEXPOSED) td=resolve_type(td) end
    push!(fn, string(spelling(td), " ", name(tdecl)))
  elseif ty_kind(t) == TypKind.POINTER
    pt = cindex.getPointeeType(t)
    push!(fn, string( spelling(pt) ))
    if ty_kind(pt) == TypKind.TYPEDEF
      tdecl = cindex.getTypeDeclaration(pt)
      td = cindex.getTypedefDeclUnderlyingType(tdecl)
      if (ty_kind(td) == TypKind.UNEXPOSED) td=resolve_type(td) end
      push!(fn, full_name(td) )
      push!(fn, spelling(tdecl) )
    end
  end
  return string( spelling(t), (length(fn) > 0 ? fn : "") )
end

function dump_functions(cl::CursorList, restrict_hdr::Any)
  for i=1:cl.size
    cu = cl[i]
    if (restrict_hdr != None && cu_file(cu) != restrict_hdr)
      continue
    end
    if cu_kind(cu) == CurKind.FUNCTIONDECL
      rt = return_type(cu)
      println(i, " ", full_name(rt), " ", name(cu))
    end
  end
end

function dump_functions(hdr::String)
  tu = tu_init(hdr)
  topcu = tu_cursor(tu)
  topcl = children(topcu)
  dump_functions(topcl, hdr)
end
dump_functions(cl::CursorList) = dump_functions(cl, None)
