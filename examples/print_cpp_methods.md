```julia
julia> using CIndex

julia> idx = CIndex.idx_create(0,1)

julia> tu = CIndex.tu_parse(idx, "vtkPolyData.h", ["-x", "c++","-I/cmn/git/VTK-include", "-I/cmn/git/julia/deps/llvm-3.1/Release/lib/clang/3.1/include", "-v", "-c"])

julia> topcu = CIndex.getTranslationUnitCursor(tu); topcl = children(topcu)

julia> for i=1:462                                                                  cu = topcl[i]
         println(i, " ", cu_kind(cu), "  ", name(cu), " ", cu_file(cu))
       end

(... omitted ...)

452 0x00000004  vtkEmptyCell vtkPolyData.h
453 0x00000004  vtkPolyData vtkPolyData.h
454 0x00000015  GetPointCells(vtkIdType, unsigned short &, vtkIdType *&) vtkPolyData.h

julia> cu = topcl[453] 

julia> name(cu)
"vtkPolyData"

julia> cu = topcl[453]

CXCursor([0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  …  0x00, 0xa0, 0x5f, 0x62, 0x01, 0x00, 0x00, 0x00, 0x00])

julia> name(cu)
"vtkPolyData"

julia> cl = children(cu)
CursorList(Ptr{Void} @0x00000000038fffc0,111)

julia> for i=1:111
         cu = cl[i]
         println(i, " ", cu_kind(cu), "  ", name(cu), " ", cu_file(cu))
       end
```
```text
1 0x00000190   
2 0x0000002c  class vtkPointSet vtkPolyData.h
3 0x00000027   vtkPolyData.h
4 0x00000015  New() vtkPolyData.h
5 0x00000014  Superclass vtkPolyData.h
6 0x00000027   vtkPolyData.h
7 0x00000015  GetClassNameInternal() vtkPolyData.h
8 0x00000027   vtkPolyData.h
9 0x00000015  IsTypeOf(const char *) vtkPolyData.h
10 0x00000015  IsA(const char *) vtkPolyData.h
11 0x00000015  SafeDownCast(vtkObjectBase *) vtkPolyData.h
12 0x00000027   vtkPolyData.h
13 0x00000015  NewInstanceInternal() vtkPolyData.h
14 0x00000027   vtkPolyData.h
15 0x00000015  NewInstance() vtkPolyData.h
16 0x00000015  PrintSelf(ostream &, vtkIndent) vtkPolyData.h
17 0x00000015  GetDataObjectType() vtkPolyData.h
18 0x00000015  CopyStructure(vtkDataSet *) vtkPolyData.h
19 0x00000015  GetNumberOfCells() vtkPolyData.h
20 0x00000015  GetCell(vtkIdType) vtkPolyData.h
21 0x00000015  GetCell(vtkIdType, vtkGenericCell *) vtkPolyData.h
22 0x00000015  GetCellType(vtkIdType) vtkPolyData.h
23 0x00000015  GetCellBounds(vtkIdType, double *) vtkPolyData.h
24 0x00000015  GetCellNeighbors(vtkIdType, vtkIdList *, vtkIdList *) vtkPolyData.h
25 0x00000015  CopyCells(vtkPolyData *, vtkIdList *, vtkPointLocator *) vtkPolyData.h
26 0x00000015  GetCellPoints(vtkIdType, vtkIdList *) vtkPolyData.h
27 0x00000015  GetPointCells(vtkIdType, vtkIdList *) vtkPolyData.h
28 0x00000015  ComputeBounds() vtkPolyData.h
29 0x00000015  Squeeze() vtkPolyData.h
30 0x00000015  GetMaxCellSize() vtkPolyData.h
31 0x00000015  SetVerts(vtkCellArray *) vtkPolyData.h
32 0x00000015  GetVerts() vtkPolyData.h
33 0x00000015  SetLines(vtkCellArray *) vtkPolyData.h
34 0x00000015  GetLines() vtkPolyData.h
35 0x00000015  SetPolys(vtkCellArray *) vtkPolyData.h
36 0x00000015  GetPolys() vtkPolyData.h
37 0x00000015  SetStrips(vtkCellArray *) vtkPolyData.h
38 0x00000015  GetStrips() vtkPolyData.h
39 0x00000015  GetNumberOfVerts() vtkPolyData.h
40 0x00000015  GetNumberOfLines() vtkPolyData.h
41 0x00000015  GetNumberOfPolys() vtkPolyData.h
42 0x00000015  GetNumberOfStrips() vtkPolyData.h
43 0x00000015  Allocate(vtkIdType, int) vtkPolyData.h
44 0x00000015  Allocate(vtkPolyData *, vtkIdType, int) vtkPolyData.h
45 0x00000015  InsertNextCell(int, int, vtkIdType *) vtkPolyData.h
46 0x00000015  InsertNextCell(int, vtkIdList *) vtkPolyData.h
47 0x00000015  Reset() vtkPolyData.h
48 0x00000015  BuildCells() vtkPolyData.h
49 0x00000015  BuildLinks(int) vtkPolyData.h
50 0x00000015  DeleteCells() vtkPolyData.h
51 0x00000015  DeleteLinks() vtkPolyData.h
52 0x00000015  GetPointCells(vtkIdType, unsigned short &, vtkIdType *&) vtkPolyData.h
53 0x00000015  GetCellEdgeNeighbors(vtkIdType, vtkIdType, vtkIdType, vtkIdList *) vtkPolyData.h
54 0x00000015  GetCellPoints(vtkIdType, vtkIdType &, vtkIdType *&) vtkPolyData.h
55 0x00000015  IsTriangle(int, int, int) vtkPolyData.h
56 0x00000015  IsEdge(vtkIdType, vtkIdType) vtkPolyData.h
57 0x00000015  IsPointUsedByCell(vtkIdType, vtkIdType) vtkPolyData.h
58 0x00000015  ReplaceCell(vtkIdType, int, vtkIdType *) vtkPolyData.h
59 0x00000015  ReplaceCellPoint(vtkIdType, vtkIdType, vtkIdType) vtkPolyData.h
60 0x00000015  ReverseCell(vtkIdType) vtkPolyData.h
61 0x00000015  DeletePoint(vtkIdType) vtkPolyData.h
62 0x00000015  DeleteCell(vtkIdType) vtkPolyData.h
63 0x00000015  RemoveDeletedCells() vtkPolyData.h
64 0x00000015  InsertNextLinkedPoint(int) vtkPolyData.h
65 0x00000015  InsertNextLinkedPoint(double *, int) vtkPolyData.h
66 0x00000015  InsertNextLinkedCell(int, int, vtkIdType *) vtkPolyData.h
67 0x00000015  ReplaceLinkedCell(vtkIdType, int, vtkIdType *) vtkPolyData.h
68 0x00000015  RemoveCellReference(vtkIdType) vtkPolyData.h
69 0x00000015  AddCellReference(vtkIdType) vtkPolyData.h
70 0x00000015  RemoveReferenceToCell(vtkIdType, vtkIdType) vtkPolyData.h
71 0x00000015  AddReferenceToCell(vtkIdType, vtkIdType) vtkPolyData.h
72 0x00000015  ResizeCellList(vtkIdType, int) vtkPolyData.h
73 0x00000015  Initialize() vtkPolyData.h
74 0x00000015  GetPiece() vtkPolyData.h
75 0x00000015  GetNumberOfPieces() vtkPolyData.h
76 0x00000015  GetGhostLevel() vtkPolyData.h
77 0x00000015  GetActualMemorySize() vtkPolyData.h
78 0x00000015  ShallowCopy(vtkDataObject *) vtkPolyData.h
79 0x00000015  DeepCopy(vtkDataObject *) vtkPolyData.h
80 0x00000015  RemoveGhostCells(int) vtkPolyData.h
81 0x00000015  GetData(vtkInformation *) vtkPolyData.h
82 0x00000015  GetData(vtkInformationVector *, int) vtkPolyData.h
83 0x00000005   vtkPolyData.h
84 0x00000015  GetScalarFieldCriticalIndex(vtkIdType, vtkDataArray *) vtkPolyData.h
85 0x00000015  GetScalarFieldCriticalIndex(vtkIdType, int) vtkPolyData.h
86 0x00000015  GetScalarFieldCriticalIndex(vtkIdType, const char *) vtkPolyData.h
87 0x00000027   vtkPolyData.h
88 0x00000018  vtkPolyData() vtkPolyData.h
89 0x00000019  ~vtkPolyData() vtkPolyData.h
90 0x00000006  Vertex vtkPolyData.h
91 0x00000006  PolyVertex vtkPolyData.h
92 0x00000006  Line vtkPolyData.h
93 0x00000006  PolyLine vtkPolyData.h
94 0x00000006  Triangle vtkPolyData.h
95 0x00000006  Quad vtkPolyData.h
96 0x00000006  Polygon vtkPolyData.h
97 0x00000006  TriangleStrip vtkPolyData.h
98 0x00000006  EmptyCell vtkPolyData.h
99 0x00000006  Verts vtkPolyData.h
100 0x00000006  Lines vtkPolyData.h
101 0x00000006  Polys vtkPolyData.h
102 0x00000006  Strips vtkPolyData.h
103 0x00000009  Dummy vtkPolyData.h
104 0x00000006  Cells vtkPolyData.h
105 0x00000006  Links vtkPolyData.h
106 0x00000027   vtkPolyData.h
107 0x00000015  GetCellNeighbors(vtkIdType, vtkIdList &, vtkIdList &) vtkPolyData.h
108 0x00000015  Cleanup() vtkPolyData.h
109 0x00000027   vtkPolyData.h
110 0x00000018  vtkPolyData(const vtkPolyData &) vtkPolyData.h
111 0x00000015  operator=(const vtkPolyData &) vtkPolyData.h
```
