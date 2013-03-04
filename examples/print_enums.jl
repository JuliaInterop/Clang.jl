#error("Running this file will overwrite existing CIndex_h.jl")
# Uncomment below to run
require("CIndex.jl")

const ENUM_DECL = 5
const TYPEDEF_DECL = 20

enum_remaps = {
  "CXCursor_" => ("", uppercase)
  "CXType_" => ("", uppercase)
}


function wrap_enums(io::IOStream, cu::CIndex.CXCursor, typedef::Any)
  enum = CIndex.name(cu)
  enum_typedef = if (typeof(typedef) == CIndex.CXCursor)
    CIndex.name(typedef)
  else
    ""
  end
  if enum != ""
    println(io, "# enum ENUM_", enum)
  elseif enum_typedef != ""
    println(io, "# enum ", enum_typedef)
  else
    println(io, "# enum (ANONYMOUS)")
  end
  
  cl = CIndex.children(cu)

  remap_name = 1
  remap_f = identity
  for k in keys(enum_remaps)
    if (ismatch(Regex("$k*"), CIndex.name(CIndex.ref(cl,1))) )
      remap_name = length(k)
      remap_f = enum_remaps[k][2]
      break
    end
  end
  for i=1:cl.size
    cur_cu = CIndex.ref(cl,i)
    name = CIndex.spelling(cur_cu)
    if (length(name) < 1) continue end
    if (remap_name>1) name = remap_f(name[remap_name+1:end]) end

    println(io, "const ", name, " = ", CIndex.value(cur_cu))
  end
  CIndex.cl_dispose(cl)
  println(io, "# end")
  if enum != "" && enum_typedef != ""
      println(io, "# const $(enum_typedef) == ENUM_$(enum)")
  end
  println(io)
end

index_fn = "Index.h"
tu = CIndex.tu_init(index_fn)
topcu = CIndex.tu_cursor(tu)
topcl = CIndex.children(topcu)
f_out = open("test_enums.jl", "w")
println(f_out, "# Automatically generated from ", index_fn)
println(f_out, "#   using dumpenums.jl")
for i = 1:topcl.size
  cu = CIndex.ref(topcl,i)
  fn = CIndex.cu_file(cu)
  fn = "Index.h"
  if (fn != index_fn) continue end
  if (CIndex.cu_kind(cu) == ENUM_DECL)
    tdcu = CIndex.ref(topcl,i+1)
    tdcu = ((CIndex.cu_kind(tdcu) == TYPEDEF_DECL) ? tdcu : None)
    wrap_enums(f_out, cu, tdcu)
  end
end
close(f_out)
