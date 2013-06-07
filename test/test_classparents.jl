# Expected output:
#  calling callback with: Base1
#  callback with: Base1
#  calling callback with: Base2
#  callback with: Base2

using Clang.cindex, Clang.wrap_c, Clang.wrap_cpp

hpath = "test_classparents.h"
clsname = "Derived"

  idx = cindex.idx_create(0,1)
  tu = cindex.tu_parse(idx, hpath,
    ["-x", "c++",
     "-I./",
     "-I/cmn/git/julia/deps/llvm-3.2/build/Release/lib/clang/3.2/include",
     "-v", "-c"])

  topcu = cindex.getTranslationUnitCursor(tu)
  topcl = children(topcu)

  clscu = cindex.CXCursor()
  found = false
  for i=1:topcl.size
    clscu = topcl[i]
    if(cu_kind(clscu) == cindex.CurKind.CLASSDECL && name(clscu) == clsname)
      found = true
      println("found at idx: $i")
      break
    end
  end

function cxxclass_cb(cursor::Ptr{Uint8}, data::Ptr{Void})
         cu = CXCursor()
         ccall(:memcpy, Void, (Ptr{Void},Ptr{Void}, Uint), cu.data, cursor, cindex.CXCursor_size)
         println("callback with: ", name(cu))
         return int(0)
       end

_cb = cfunction(cxxclass_cb, Int, (Ptr{Uint8},Ptr{Void}))

ccall( (:wci_getCXXClassParents, :libwrapclang), Int, (Ptr{Uint8}, Ptr{Void}), clscu.data, _cb)
