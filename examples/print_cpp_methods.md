```julia
julia> using Clang.cindex

julia> idx = cindex.idx_create(0,1)

julia> tu = cindex.tu_parse(idx, "vtkPolyData.h", ["-x", "c++","-I/cmn/git/VTK-include", "-I/cmn/git/julia/deps/llvm-3.1/Release/lib/clang/3.1/include", "-v", "-c"])

julia> topcu = cindex.getTranslationUnitCursor(tu); topcl = children(topcu)

julia> for i=1:topcl.size
         cu = topcl[i]
         println(i, " ", cu_kind(cu), "  ", name(cu), " ", cu_file(cu))
       end

(... omitted ...)

450 0x00000004  vtkEmptyCell /cmn/git/VTK-include/vtkPolyData.h
451 0x00000004  vtkPolyData /cmn/git/VTK-include/vtkPolyData.h
452 0x00000015  GetPointCells /cmn/git/VTK-include/vtkPolyData.h

julia> cu = topcl[451] 

julia> name(cu)
"vtkPolyData"

julia> cu = topcl[451]

CXCursor([0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  …  0x00, 0xa0, 0x5f, 0x62, 0x01, 0x00, 0x00, 0x00, 0x00])

julia> name(cu)
"vtkPolyData"

julia> cl = children(cu)
CursorList(Ptr{Void} @0x00000000038fffc0,111)

julia> for i=1:cl.size
         cu = cl[i]
         println(i, " ", cu_kind(cu), "  ", name(cu), " ", cu_file(cu))
       end
```
```text
1 0x00000190   
2 0x0000002c  class vtkPointSet /cmn/git/VTK-include/vtkPolyData.h
3 0x00000027   /cmn/git/VTK-include/vtkPolyData.h
4 0x00000015  New() /cmn/git/VTK-include/vtkPolyData.h
5 0x00000014  Superclass /cmn/git/VTK-include/vtkPolyData.h
6 0x00000027   /cmn/git/VTK-include/vtkPolyData.h
7 0x00000015  GetClassNameInternal() /cmn/git/VTK-include/vtkPolyData.h
8 0x00000027   /cmn/git/VTK-include/vtkPolyData.h
9 0x00000015  IsTypeOf(const char *) /cmn/git/VTK-include/vtkPolyData.h
10 0x00000015  IsA(const char *) /cmn/git/VTK-include/vtkPolyData.h
11 0x00000015  SafeDownCast(vtkObjectBase *) /cmn/git/VTK-include/vtkPolyData.h
12 0x00000027   /cmn/git/VTK-include/vtkPolyData.h
13 0x00000015  NewInstanceInternal() /cmn/git/VTK-include/vtkPolyData.h
14 0x00000027   /cmn/git/VTK-include/vtkPolyData.h
15 0x00000015  NewInstance() /cmn/git/VTK-include/vtkPolyData.h
16 0x00000015  PrintSelf(ostream &, vtkIndent) /cmn/git/VTK-include/vtkPolyData.h
17 0x00000015  GetDataObjectType() /cmn/git/VTK-include/vtkPolyData.h
18 0x00000015  CopyStructure(vtkDataSet *) /cmn/git/VTK-include/vtkPolyData.h
19 0x00000015  GetNumberOfCells() /cmn/git/VTK-include/vtkPolyData.h
20 0x00000015  GetCell(vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
21 0x00000015  GetCell(vtkIdType, vtkGenericCell *) /cmn/git/VTK-include/vtkPolyData.h
22 0x00000015  GetCellType(vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
23 0x00000015  GetCellBounds(vtkIdType, double *) /cmn/git/VTK-include/vtkPolyData.h
24 0x00000015  GetCellNeighbors(vtkIdType, vtkIdList *, vtkIdList *) /cmn/git/VTK-include/vtkPolyData.h
25 0x00000015  CopyCells(vtkPolyData *, vtkIdList *, vtkPointLocator *) /cmn/git/VTK-include/vtkPolyData.h
26 0x00000015  GetCellPoints(vtkIdType, vtkIdList *) /cmn/git/VTK-include/vtkPolyData.h
27 0x00000015  GetPointCells(vtkIdType, vtkIdList *) /cmn/git/VTK-include/vtkPolyData.h
28 0x00000015  ComputeBounds() /cmn/git/VTK-include/vtkPolyData.h
29 0x00000015  Squeeze() /cmn/git/VTK-include/vtkPolyData.h
30 0x00000015  GetMaxCellSize() /cmn/git/VTK-include/vtkPolyData.h
31 0x00000015  SetVerts(vtkCellArray *) /cmn/git/VTK-include/vtkPolyData.h
32 0x00000015  GetVerts() /cmn/git/VTK-include/vtkPolyData.h
33 0x00000015  SetLines(vtkCellArray *) /cmn/git/VTK-include/vtkPolyData.h
34 0x00000015  GetLines() /cmn/git/VTK-include/vtkPolyData.h
35 0x00000015  SetPolys(vtkCellArray *) /cmn/git/VTK-include/vtkPolyData.h
36 0x00000015  GetPolys() /cmn/git/VTK-include/vtkPolyData.h
37 0x00000015  SetStrips(vtkCellArray *) /cmn/git/VTK-include/vtkPolyData.h
38 0x00000015  GetStrips() /cmn/git/VTK-include/vtkPolyData.h
39 0x00000015  GetNumberOfVerts() /cmn/git/VTK-include/vtkPolyData.h
40 0x00000015  GetNumberOfLines() /cmn/git/VTK-include/vtkPolyData.h
41 0x00000015  GetNumberOfPolys() /cmn/git/VTK-include/vtkPolyData.h
42 0x00000015  GetNumberOfStrips() /cmn/git/VTK-include/vtkPolyData.h
43 0x00000015  Allocate(vtkIdType, int) /cmn/git/VTK-include/vtkPolyData.h
44 0x00000015  Allocate(vtkPolyData *, vtkIdType, int) /cmn/git/VTK-include/vtkPolyData.h
45 0x00000015  InsertNextCell(int, int, vtkIdType *) /cmn/git/VTK-include/vtkPolyData.h
46 0x00000015  InsertNextCell(int, vtkIdList *) /cmn/git/VTK-include/vtkPolyData.h
47 0x00000015  Reset() /cmn/git/VTK-include/vtkPolyData.h
48 0x00000015  BuildCells() /cmn/git/VTK-include/vtkPolyData.h
49 0x00000015  BuildLinks(int) /cmn/git/VTK-include/vtkPolyData.h
50 0x00000015  DeleteCells() /cmn/git/VTK-include/vtkPolyData.h
51 0x00000015  DeleteLinks() /cmn/git/VTK-include/vtkPolyData.h
52 0x00000015  GetPointCells(vtkIdType, unsigned short &, vtkIdType *&) /cmn/git/VTK-include/vtkPolyData.h
53 0x00000015  GetCellEdgeNeighbors(vtkIdType, vtkIdType, vtkIdType, vtkIdList *) /cmn/git/VTK-include/vtkPolyData.h
54 0x00000015  GetCellPoints(vtkIdType, vtkIdType &, vtkIdType *&) /cmn/git/VTK-include/vtkPolyData.h
55 0x00000015  IsTriangle(int, int, int) /cmn/git/VTK-include/vtkPolyData.h
56 0x00000015  IsEdge(vtkIdType, vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
57 0x00000015  IsPointUsedByCell(vtkIdType, vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
58 0x00000015  ReplaceCell(vtkIdType, int, vtkIdType *) /cmn/git/VTK-include/vtkPolyData.h
59 0x00000015  ReplaceCellPoint(vtkIdType, vtkIdType, vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
60 0x00000015  ReverseCell(vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
61 0x00000015  DeletePoint(vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
62 0x00000015  DeleteCell(vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
63 0x00000015  RemoveDeletedCells() /cmn/git/VTK-include/vtkPolyData.h
64 0x00000015  InsertNextLinkedPoint(int) /cmn/git/VTK-include/vtkPolyData.h
65 0x00000015  InsertNextLinkedPoint(double *, int) /cmn/git/VTK-include/vtkPolyData.h
66 0x00000015  InsertNextLinkedCell(int, int, vtkIdType *) /cmn/git/VTK-include/vtkPolyData.h
67 0x00000015  ReplaceLinkedCell(vtkIdType, int, vtkIdType *) /cmn/git/VTK-include/vtkPolyData.h
68 0x00000015  RemoveCellReference(vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
69 0x00000015  AddCellReference(vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
70 0x00000015  RemoveReferenceToCell(vtkIdType, vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
71 0x00000015  AddReferenceToCell(vtkIdType, vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
72 0x00000015  ResizeCellList(vtkIdType, int) /cmn/git/VTK-include/vtkPolyData.h
73 0x00000015  Initialize() /cmn/git/VTK-include/vtkPolyData.h
74 0x00000015  GetPiece() /cmn/git/VTK-include/vtkPolyData.h
75 0x00000015  GetNumberOfPieces() /cmn/git/VTK-include/vtkPolyData.h
76 0x00000015  GetGhostLevel() /cmn/git/VTK-include/vtkPolyData.h
77 0x00000015  GetActualMemorySize() /cmn/git/VTK-include/vtkPolyData.h
78 0x00000015  ShallowCopy(vtkDataObject *) /cmn/git/VTK-include/vtkPolyData.h
79 0x00000015  DeepCopy(vtkDataObject *) /cmn/git/VTK-include/vtkPolyData.h
80 0x00000015  RemoveGhostCells(int) /cmn/git/VTK-include/vtkPolyData.h
81 0x00000015  GetData(vtkInformation *) /cmn/git/VTK-include/vtkPolyData.h
82 0x00000015  GetData(vtkInformationVector *, int) /cmn/git/VTK-include/vtkPolyData.h
83 0x00000005   /cmn/git/VTK-include/vtkPolyData.h
84 0x00000015  GetScalarFieldCriticalIndex(vtkIdType, vtkDataArray *) /cmn/git/VTK-include/vtkPolyData.h
85 0x00000015  GetScalarFieldCriticalIndex(vtkIdType, int) /cmn/git/VTK-include/vtkPolyData.h
86 0x00000015  GetScalarFieldCriticalIndex(vtkIdType, const char *) /cmn/git/VTK-include/vtkPolyData.h
87 0x00000027   /cmn/git/VTK-include/vtkPolyData.h
88 0x00000018  vtkPolyData() /cmn/git/VTK-include/vtkPolyData.h
89 0x00000019  ~vtkPolyData() /cmn/git/VTK-include/vtkPolyData.h
90 0x00000006  Vertex /cmn/git/VTK-include/vtkPolyData.h
91 0x00000006  PolyVertex /cmn/git/VTK-include/vtkPolyData.h
92 0x00000006  Line /cmn/git/VTK-include/vtkPolyData.h
93 0x00000006  PolyLine /cmn/git/VTK-include/vtkPolyData.h
94 0x00000006  Triangle /cmn/git/VTK-include/vtkPolyData.h
95 0x00000006  Quad /cmn/git/VTK-include/vtkPolyData.h
96 0x00000006  Polygon /cmn/git/VTK-include/vtkPolyData.h
97 0x00000006  TriangleStrip /cmn/git/VTK-include/vtkPolyData.h
98 0x00000006  EmptyCell /cmn/git/VTK-include/vtkPolyData.h
99 0x00000006  Verts /cmn/git/VTK-include/vtkPolyData.h
100 0x00000006  Lines /cmn/git/VTK-include/vtkPolyData.h
101 0x00000006  Polys /cmn/git/VTK-include/vtkPolyData.h
102 0x00000006  Strips /cmn/git/VTK-include/vtkPolyData.h
103 0x00000009  Dummy /cmn/git/VTK-include/vtkPolyData.h
104 0x00000006  Cells /cmn/git/VTK-include/vtkPolyData.h
105 0x00000006  Links /cmn/git/VTK-include/vtkPolyData.h
106 0x00000027   /cmn/git/VTK-include/vtkPolyData.h
107 0x00000015  GetCellNeighbors(vtkIdType, vtkIdList &, vtkIdList &) /cmn/git/VTK-include/vtkPolyData.h
108 0x00000015  Cleanup() /cmn/git/VTK-include/vtkPolyData.h
109 0x00000027   /cmn/git/VTK-include/vtkPolyData.h
110 0x00000018  vtkPolyData(const vtkPolyData &) /cmn/git/VTK-include/vtkPolyData.h
111 0x00000015  operator=(const vtkPolyData &) /cmn/git/VTK-include/vtkPolyData.h
```
