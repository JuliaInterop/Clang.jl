load("cindex")
using cindex
import cindex.CurKind
import cindex.TypKind

tu = tu_init("Index.h")
topcu = tu_cursor(tu)
topcl = children(topcu)

function full_name(t::CXType)
  fn = {}
  tdecl = cindex.getTypeDeclaration(t)
  if kind(t) == TypKind.ENUM
    push(fn, string(spelling(tdecl)) )
  elseif kind(t) == TypKind.TYPEDEF
    td = cindex.getTypedefDeclUnderlyingType(tdecl)
    if (kind(td) == TypKind.UNEXPOSED) td=resolve_type(td) end
    push(fn, string(spelling(td), " ", name(tdecl)))
  end
  return string( spelling(t), (length(fn) > 0 ? fn : "") )
end

function dump_functions(cl::CursorList, restrict_hdr::Any)
  for i=1:cl.size
    cu = cl[i]
    if (restrict_hdr != None && cu_file(cu) != restrict_hdr)
      continue
    end
    if kind(cu) == CurKind.FUNCTIONDECL
      rt = return_type(cu)
      println(i, " ", full_name(rt), " ", name(cu))
    end
  end
end
dump_functions(cl::CursorList) = dump_functions(cl, None)
