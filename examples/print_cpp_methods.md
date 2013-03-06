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
272 0x00000014  vtkTypeUInt8 /cmn/git/VTK-include/vtkType.h
273 0x00000014  vtkTypeInt8 /cmn/git/VTK-include/vtkType.h
274 0x00000014  vtkTypeUInt16 /cmn/git/VTK-include/vtkType.h
275 0x00000014  vtkTypeInt16 /cmn/git/VTK-include/vtkType.h
276 0x00000014  vtkTypeUInt32 /cmn/git/VTK-include/vtkType.h
277 0x00000014  vtkTypeInt32 /cmn/git/VTK-include/vtkType.h
278 0x00000014  vtkTypeUInt64 /cmn/git/VTK-include/vtkType.h
279 0x00000014  vtkTypeInt64 /cmn/git/VTK-include/vtkType.h
280 0x00000014  vtkTypeFloat32 /cmn/git/VTK-include/vtkType.h
281 0x00000014  vtkTypeFloat64 /cmn/git/VTK-include/vtkType.h
282 0x00000014  vtkIdType /cmn/git/VTK-include/vtkType.h
283 0x00000004  vtkIndent /cmn/git/VTK-include/vtkOStreamWrapper.h
284 0x00000004  vtkObjectBase /cmn/git/VTK-include/vtkOStreamWrapper.h
285 0x00000004  vtkLargeInteger /cmn/git/VTK-include/vtkOStreamWrapper.h
286 0x00000004  vtkSmartPointerBase /cmn/git/VTK-include/vtkOStreamWrapper.h
287 0x00000004  vtkStdString /cmn/git/VTK-include/vtkOStreamWrapper.h
288 0x00000004  vtkOStreamWrapper /cmn/git/VTK-include/vtkOStreamWrapper.h
289 0x00000004  vtkOStrStreamWrapper /cmn/git/VTK-include/vtkOStrStreamWrapper.h
290 0x00000001   /usr/include/stdlib.h
291 0x00000001   /usr/include/string.h
292 0x00000004  vtkIndent /cmn/git/VTK-include/vtkIndent.h
293 0x00000008  operator<<(ostream &, const vtkIndent &) /cmn/git/VTK-include/vtkIndent.h
294 0x00000004  vtkIndent /cmn/git/VTK-include/vtkIndent.h
295 0x00000004  vtkGarbageCollector /cmn/git/VTK-include/vtkObjectBase.h
296 0x00000004  vtkGarbageCollectorToObjectBaseFriendship /cmn/git/VTK-include/vtkObjectBase.h
297 0x00000004  vtkWeakPointerBase /cmn/git/VTK-include/vtkObjectBase.h
298 0x00000004  vtkWeakPointerBaseToObjectBaseFriendship /cmn/git/VTK-include/vtkObjectBase.h
299 0x00000004  vtkObjectBase /cmn/git/VTK-include/vtkObjectBase.h
300 0x00000001   /usr/include/math.h
301 0x00000008  vtkOutputWindowDisplayText(const char *) /cmn/git/VTK-include/vtkSetGet.h
302 0x00000008  vtkOutputWindowDisplayErrorText(const char *) /cmn/git/VTK-include/vtkSetGet.h
303 0x00000008  vtkOutputWindowDisplayWarningText(const char *) /cmn/git/VTK-include/vtkSetGet.h
304 0x00000008  vtkOutputWindowDisplayGenericWarningText(const char *) /cmn/git/VTK-include/vtkSetGet.h
305 0x00000008  vtkOutputWindowDisplayDebugText(const char *) /cmn/git/VTK-include/vtkSetGet.h
306 0x00000004  vtkTimeStamp /cmn/git/VTK-include/vtkTimeStamp.h
307 0x00000004  vtkObjectBaseToWeakPointerBaseFriendship /cmn/git/VTK-include/vtkWeakPointerBase.h
308 0x00000004  vtkWeakPointerBase /cmn/git/VTK-include/vtkWeakPointerBase.h
309 0x00000008  operator==(const vtkWeakPointerBase &, const vtkWeakPointerBase &) /cmn/git/VTK-include/vtkWeakPointerBase.h
310 0x00000008  operator==(vtkObjectBase *, const vtkWeakPointerBase &) /cmn/git/VTK-include/vtkWeakPointerBase.h
311 0x00000008  operator==(const vtkWeakPointerBase &, vtkObjectBase *) /cmn/git/VTK-include/vtkWeakPointerBase.h
312 0x00000008  operator!=(const vtkWeakPointerBase &, const vtkWeakPointerBase &) /cmn/git/VTK-include/vtkWeakPointerBase.h
313 0x00000008  operator!=(vtkObjectBase *, const vtkWeakPointerBase &) /cmn/git/VTK-include/vtkWeakPointerBase.h
314 0x00000008  operator!=(const vtkWeakPointerBase &, vtkObjectBase *) /cmn/git/VTK-include/vtkWeakPointerBase.h
315 0x00000008  operator<(const vtkWeakPointerBase &, const vtkWeakPointerBase &) /cmn/git/VTK-include/vtkWeakPointerBase.h
316 0x00000008  operator<(vtkObjectBase *, const vtkWeakPointerBase &) /cmn/git/VTK-include/vtkWeakPointerBase.h
317 0x00000008  operator<(const vtkWeakPointerBase &, vtkObjectBase *) /cmn/git/VTK-include/vtkWeakPointerBase.h
318 0x00000008  operator<=(const vtkWeakPointerBase &, const vtkWeakPointerBase &) /cmn/git/VTK-include/vtkWeakPointerBase.h
319 0x00000008  operator<=(vtkObjectBase *, const vtkWeakPointerBase &) /cmn/git/VTK-include/vtkWeakPointerBase.h
320 0x00000008  operator<=(const vtkWeakPointerBase &, vtkObjectBase *) /cmn/git/VTK-include/vtkWeakPointerBase.h
321 0x00000008  operator>(const vtkWeakPointerBase &, const vtkWeakPointerBase &) /cmn/git/VTK-include/vtkWeakPointerBase.h
322 0x00000008  operator>(vtkObjectBase *, const vtkWeakPointerBase &) /cmn/git/VTK-include/vtkWeakPointerBase.h
323 0x00000008  operator>(const vtkWeakPointerBase &, vtkObjectBase *) /cmn/git/VTK-include/vtkWeakPointerBase.h
324 0x00000008  operator>=(const vtkWeakPointerBase &, const vtkWeakPointerBase &) /cmn/git/VTK-include/vtkWeakPointerBase.h
325 0x00000008  operator>=(vtkObjectBase *, const vtkWeakPointerBase &) /cmn/git/VTK-include/vtkWeakPointerBase.h
326 0x00000008  operator>=(const vtkWeakPointerBase &, vtkObjectBase *) /cmn/git/VTK-include/vtkWeakPointerBase.h
327 0x00000008  operator<<(ostream &, const vtkWeakPointerBase &) /cmn/git/VTK-include/vtkWeakPointerBase.h
328 0x00000004  vtkSubjectHelper /cmn/git/VTK-include/vtkObject.h
329 0x00000004  vtkCommand /cmn/git/VTK-include/vtkObject.h
330 0x00000004  vtkObject /cmn/git/VTK-include/vtkObject.h
331 0x00000004  vtkAbstractArray /cmn/git/VTK-include/vtkDataObject.h
332 0x00000004  vtkDataSetAttributes /cmn/git/VTK-include/vtkDataObject.h
333 0x00000004  vtkFieldData /cmn/git/VTK-include/vtkDataObject.h
334 0x00000004  vtkInformation /cmn/git/VTK-include/vtkDataObject.h
335 0x00000004  vtkInformationDataObjectKey /cmn/git/VTK-include/vtkDataObject.h
336 0x00000004  vtkInformationDoubleKey /cmn/git/VTK-include/vtkDataObject.h
337 0x00000004  vtkInformationDoubleVectorKey /cmn/git/VTK-include/vtkDataObject.h
338 0x00000004  vtkInformationIntegerKey /cmn/git/VTK-include/vtkDataObject.h
339 0x00000004  vtkInformationIntegerPointerKey /cmn/git/VTK-include/vtkDataObject.h
340 0x00000004  vtkInformationIntegerVectorKey /cmn/git/VTK-include/vtkDataObject.h
341 0x00000004  vtkInformationStringKey /cmn/git/VTK-include/vtkDataObject.h
342 0x00000004  vtkInformationVector /cmn/git/VTK-include/vtkDataObject.h
343 0x00000004  vtkInformationInformationVectorKey /cmn/git/VTK-include/vtkDataObject.h
344 0x00000004  vtkDataObject /cmn/git/VTK-include/vtkDataObject.h
345 0x00000004  vtkCell /cmn/git/VTK-include/vtkDataSet.h
346 0x00000004  vtkCellData /cmn/git/VTK-include/vtkDataSet.h
347 0x00000004  vtkCellTypes /cmn/git/VTK-include/vtkDataSet.h
348 0x00000004  vtkExtentTranslator /cmn/git/VTK-include/vtkDataSet.h
349 0x00000004  vtkGenericCell /cmn/git/VTK-include/vtkDataSet.h
350 0x00000004  vtkIdList /cmn/git/VTK-include/vtkDataSet.h
351 0x00000004  vtkPointData /cmn/git/VTK-include/vtkDataSet.h
352 0x00000004  vtkDataSet /cmn/git/VTK-include/vtkDataSet.h
353 0x00000015  GetPoint(vtkIdType, double *) /cmn/git/VTK-include/vtkDataSet.h
354 0x00000004  vtkStdString /cmn/git/VTK-include/vtkStdString.h
355 0x00000008  operator<<(ostream &, const vtkStdString &) /cmn/git/VTK-include/vtkStdString.h
356 0x00000004  vtkStdString /cmn/git/VTK-include/vtkStdString.h
357 0x00000016  std /usr/lib/gcc/x86_64-linux-gnu/4.6/../../../../include/c++/4.6/bits/stl_construct.h
358 0x00000016  std /usr/lib/gcc/x86_64-linux-gnu/4.6/../../../../include/c++/4.6/bits/stl_uninitialized.h
359 0x00000016  std /usr/lib/gcc/x86_64-linux-gnu/4.6/../../../../include/c++/4.6/bits/stl_vector.h
360 0x00000016  std /usr/lib/gcc/x86_64-linux-gnu/4.6/../../../../include/c++/4.6/bits/stl_bvector.h
361 0x00000016  std /usr/lib/gcc/x86_64-linux-gnu/4.6/../../../../include/c++/4.6/bits/stl_bvector.h
362 0x00000016  std /usr/lib/gcc/x86_64-linux-gnu/4.6/../../../../include/c++/4.6/bits/vector.tcc
363 0x00000004  vtkUnicodeString /cmn/git/VTK-include/vtkUnicodeString.h
364 0x00000014  vtkUnicodeStringValueType /cmn/git/VTK-include/vtkUnicodeString.h
365 0x00000004  vtkUnicodeString /cmn/git/VTK-include/vtkUnicodeString.h
366 0x00000008  operator==(const vtkUnicodeString &, const vtkUnicodeString &) /cmn/git/VTK-include/vtkUnicodeString.h
367 0x00000008  operator!=(const vtkUnicodeString &, const vtkUnicodeString &) /cmn/git/VTK-include/vtkUnicodeString.h
368 0x00000008  operator<(const vtkUnicodeString &, const vtkUnicodeString &) /cmn/git/VTK-include/vtkUnicodeString.h
369 0x00000008  operator<=(const vtkUnicodeString &, const vtkUnicodeString &) /cmn/git/VTK-include/vtkUnicodeString.h
370 0x00000008  operator>=(const vtkUnicodeString &, const vtkUnicodeString &) /cmn/git/VTK-include/vtkUnicodeString.h
371 0x00000008  operator>(const vtkUnicodeString &, const vtkUnicodeString &) /cmn/git/VTK-include/vtkUnicodeString.h
372 0x00000004  vtkStdString /cmn/git/VTK-include/vtkVariant.h
373 0x00000004  vtkUnicodeString /cmn/git/VTK-include/vtkVariant.h
374 0x00000004  vtkObjectBase /cmn/git/VTK-include/vtkVariant.h
375 0x00000004  vtkAbstractArray /cmn/git/VTK-include/vtkVariant.h
376 0x00000004  vtkVariant /cmn/git/VTK-include/vtkVariant.h
377 0x00000002  vtkVariantLessThan /cmn/git/VTK-include/vtkVariant.h
378 0x00000008  operator<<(ostream &, const vtkVariant &) /cmn/git/VTK-include/vtkVariant.h
379 0x00000004  vtkVariant /cmn/git/VTK-include/vtkVariant.h
380 0x00000008  IsSigned64Bit(int) /cmn/git/VTK-include/vtkVariantInlineOperators.h
381 0x00000008  IsSigned(int) /cmn/git/VTK-include/vtkVariantInlineOperators.h
382 0x00000008  IsFloatingPoint(int) /cmn/git/VTK-include/vtkVariantInlineOperators.h
383 0x00000008  CompareSignedUnsignedEqual(const vtkVariant &, const vtkVariant &) /cmn/git/VTK-include/vtkVariantInlineOperators.h
384 0x00000008  CompareSignedUnsignedLessThan(const vtkVariant &, const vtkVariant &) /cmn/git/VTK-include/vtkVariantInlineOperators.h
385 0x00000008  CompareUnsignedSignedLessThan(const vtkVariant &, const vtkVariant &) /cmn/git/VTK-include/vtkVariantInlineOperators.h
386 0x00000008  CompareSignedLessThan(const vtkVariant &, const vtkVariant &) /cmn/git/VTK-include/vtkVariantInlineOperators.h
387 0x00000008  CompareUnsignedLessThan(const vtkVariant &, const vtkVariant &) /cmn/git/VTK-include/vtkVariantInlineOperators.h
388 0x00000015  operator==(const vtkVariant &) /cmn/git/VTK-include/vtkVariantInlineOperators.h
389 0x00000015  operator<(const vtkVariant &) /cmn/git/VTK-include/vtkVariantInlineOperators.h
390 0x00000015  operator!=(const vtkVariant &) /cmn/git/VTK-include/vtkVariantInlineOperators.h
391 0x00000015  operator>(const vtkVariant &) /cmn/git/VTK-include/vtkVariantInlineOperators.h
392 0x00000015  operator<=(const vtkVariant &) /cmn/git/VTK-include/vtkVariantInlineOperators.h
393 0x00000015  operator>=(const vtkVariant &) /cmn/git/VTK-include/vtkVariantInlineOperators.h
394 0x00000002  vtkVariantLessThan /cmn/git/VTK-include/vtkVariant.h
395 0x00000002  vtkVariantEqual /cmn/git/VTK-include/vtkVariant.h
396 0x00000002  vtkVariantStrictWeakOrder /cmn/git/VTK-include/vtkVariant.h
397 0x00000002  vtkVariantStrictEquality /cmn/git/VTK-include/vtkVariant.h
398 0x00000004  vtkArrayIterator /cmn/git/VTK-include/vtkAbstractArray.h
399 0x00000004  vtkDataArray /cmn/git/VTK-include/vtkAbstractArray.h
400 0x00000004  vtkIdList /cmn/git/VTK-include/vtkAbstractArray.h
401 0x00000004  vtkIdTypeArray /cmn/git/VTK-include/vtkAbstractArray.h
402 0x00000004  vtkInformation /cmn/git/VTK-include/vtkAbstractArray.h
403 0x00000004  vtkInformationDoubleVectorKey /cmn/git/VTK-include/vtkAbstractArray.h
404 0x00000004  vtkInformationIntegerKey /cmn/git/VTK-include/vtkAbstractArray.h
405 0x00000004  vtkInformationInformationVectorKey /cmn/git/VTK-include/vtkAbstractArray.h
406 0x00000004  vtkInformationVariantVectorKey /cmn/git/VTK-include/vtkAbstractArray.h
407 0x00000004  vtkVariantArray /cmn/git/VTK-include/vtkAbstractArray.h
408 0x00000004  vtkAbstractArray /cmn/git/VTK-include/vtkAbstractArray.h
409 0x00000004  vtkDoubleArray /cmn/git/VTK-include/vtkDataArray.h
410 0x00000004  vtkIdList /cmn/git/VTK-include/vtkDataArray.h
411 0x00000004  vtkInformationDoubleVectorKey /cmn/git/VTK-include/vtkDataArray.h
412 0x00000004  vtkLookupTable /cmn/git/VTK-include/vtkDataArray.h
413 0x00000004  vtkDataArray /cmn/git/VTK-include/vtkDataArray.h
414 0x00000004  vtkIdList /cmn/git/VTK-include/vtkPoints.h
415 0x00000004  vtkPoints /cmn/git/VTK-include/vtkPoints.h
416 0x00000004  vtkPoints /cmn/git/VTK-include/vtkPoints.h
417 0x00000015  SetNumberOfPoints(vtkIdType) /cmn/git/VTK-include/vtkPoints.h
418 0x00000015  SetPoint(vtkIdType, double, double, double) /cmn/git/VTK-include/vtkPoints.h
419 0x00000015  InsertPoint(vtkIdType, double, double, double) /cmn/git/VTK-include/vtkPoints.h
420 0x00000015  InsertNextPoint(double, double, double) /cmn/git/VTK-include/vtkPoints.h
421 0x00000004  vtkPointLocator /cmn/git/VTK-include/vtkPointSet.h
422 0x00000004  vtkPointSet /cmn/git/VTK-include/vtkPointSet.h
423 0x00000015  GetNumberOfPoints() /cmn/git/VTK-include/vtkPointSet.h
424 0x0000001f  vtkDataArrayTemplateLookup<T> /cmn/git/VTK-include/vtkDataArrayTemplate.h
425 0x0000001f  vtkDataArrayTemplate<T> /cmn/git/VTK-include/vtkDataArrayTemplate.h
426 0x00000004  vtkIntArray /cmn/git/VTK-include/vtkIntArray.h
427 0x00000004  vtkUnsignedCharArray /cmn/git/VTK-include/vtkUnsignedCharArray.h
428 0x00000005   /cmn/git/VTK-include/vtkCellType.h
429 0x00000014  VTKCellType /cmn/git/VTK-include/vtkCellType.h
430 0x00000004  vtkCellTypes /cmn/git/VTK-include/vtkCellTypes.h
431 0x00000015  IsType(unsigned char) /cmn/git/VTK-include/vtkCellTypes.h
432 0x00000015  IsLinear(unsigned char) /cmn/git/VTK-include/vtkCellTypes.h
433 0x00000004  vtkDataSet /cmn/git/VTK-include/vtkCellLinks.h
434 0x00000004  vtkCellArray /cmn/git/VTK-include/vtkCellLinks.h
435 0x00000004  vtkCellLinks /cmn/git/VTK-include/vtkCellLinks.h
436 0x00000015  InsertCellReference(vtkIdType, unsigned short, vtkIdType) /cmn/git/VTK-include/vtkCellLinks.h
437 0x00000015  DeletePoint(vtkIdType) /cmn/git/VTK-include/vtkCellLinks.h
438 0x00000015  InsertNextCellReference(vtkIdType, vtkIdType) /cmn/git/VTK-include/vtkCellLinks.h
439 0x00000015  RemoveCellReference(vtkIdType, vtkIdType) /cmn/git/VTK-include/vtkCellLinks.h
440 0x00000015  AddCellReference(vtkIdType, vtkIdType) /cmn/git/VTK-include/vtkCellLinks.h
441 0x00000015  ResizeCellList(vtkIdType, int) /cmn/git/VTK-include/vtkCellLinks.h
442 0x00000004  vtkVertex /cmn/git/VTK-include/vtkPolyData.h
443 0x00000004  vtkPolyVertex /cmn/git/VTK-include/vtkPolyData.h
444 0x00000004  vtkLine /cmn/git/VTK-include/vtkPolyData.h
445 0x00000004  vtkPolyLine /cmn/git/VTK-include/vtkPolyData.h
446 0x00000004  vtkTriangle /cmn/git/VTK-include/vtkPolyData.h
447 0x00000004  vtkQuad /cmn/git/VTK-include/vtkPolyData.h
448 0x00000004  vtkPolygon /cmn/git/VTK-include/vtkPolyData.h
449 0x00000004  vtkTriangleStrip /cmn/git/VTK-include/vtkPolyData.h
450 0x00000004  vtkEmptyCell /cmn/git/VTK-include/vtkPolyData.h
451 0x00000004  vtkPolyData /cmn/git/VTK-include/vtkPolyData.h
452 0x00000015  GetPointCells(vtkIdType, unsigned short &, vtkIdType *&) /cmn/git/VTK-include/vtkPolyData.h
453 0x00000015  IsTriangle(int, int, int) /cmn/git/VTK-include/vtkPolyData.h
454 0x00000015  IsPointUsedByCell(vtkIdType, vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
455 0x00000015  DeletePoint(vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
456 0x00000015  DeleteCell(vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
457 0x00000015  RemoveCellReference(vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
458 0x00000015  AddCellReference(vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
459 0x00000015  ResizeCellList(vtkIdType, int) /cmn/git/VTK-include/vtkPolyData.h
460 0x00000015  ReplaceCellPoint(vtkIdType, vtkIdType, vtkIdType) /cmn/git/VTK-include/vtkPolyData.h
```
