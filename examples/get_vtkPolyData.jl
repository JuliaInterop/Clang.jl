using Clang.cindex

idx = cindex.idx_create(0,1)
tu = cindex.tu_parse(idx, "/cmn/git/VTK-include/vtkPolyData.h", ["-x", "c++","-I/cmn/git/VTK-include", "-I/cmn/git/julia/deps/llvm-3.1/Release/lib/clang/3.1/include", "-v", "-c"])

topcu = cindex.getTranslationUnitCursor(tu); topcl = children(topcu)

cu = topcl[447]
println(name(cu))

cl = children(cu); cm = cl[79]

bufr = ones(Uint8,1024)
