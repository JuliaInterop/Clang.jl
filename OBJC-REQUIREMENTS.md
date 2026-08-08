# What Objective-C support needs from ClangCompiler

Objective-C is the one capability this branch dropped outright, and the only merge blocker that
is not in this repo. It is gated on
[ClangCompiler#49](https://github.com/Gnimuc/ClangCompiler.jl/issues/49) — `clang/AST/DeclObjC.h`
is unwrapped, so no ObjC `Decl` carrier exists and `resolve` falls back to the base `Decl`
(`ClangCompiler/src/clang/DeclKindMap.jl:3`).

This is the **gap list**, derived from the assertions the pre-rework testset made
(`git show master:test/generators.jl`, the `@testset "Objective-C"` block) against
`test/include/objectiveC.h`. It is deliberately not a wish list: everything here is load-bearing
for one of those assertions, and everything not needed for them is called out at the bottom.

The generator emits [ObjectiveC.jl](https://github.com/JuliaInterop/ObjectiveC.jl) macros, not
plain structs — `@objcwrapper`, `@objcproperties`, `@autoproperty` — so the facts it needs are
about *interfaces, protocols and properties*, not layout.

## Required

| # | emitted form | clang query | needed from ClangCompiler |
| --- | --- | --- | --- |
| 1 | `@objcwrapper immutable = true TestInterface <: NSObject` | `ObjCInterfaceDecl` name + `getSuperClass()` | `ObjCInterfaceDecl` carrier, `getSuperClass` → `ObjCInterfaceDecl` |
| 2 | `@objcwrapper immutable = true TestProtocol <: NSObject` | `ObjCProtocolDecl` name | `ObjCProtocolDecl` carrier |
| 3 | `TestProtocol2 <: TestProtocol` | a protocol's inherited protocols | protocol-list iteration on `ObjCProtocolDecl` (`protocol_begin`/`protocol_end`, or a `getProtocols` vector like `getFields`) |
| 4 | `@objcproperties TestInterfaceProperties begin … end` | the interface's properties | property iteration on `ObjCInterfaceDecl` |
| 5 | `@autoproperty intproperty1` | `ObjCPropertyDecl` name | `ObjCPropertyDecl` carrier + `getName` |
| 6 | `@autoproperty length::Int32` | property type | `ObjCPropertyDecl::getType` (existing `QualType` path then applies) |
| 7 | `getter = isintproperty2`, `setter = setIntproperty1` | explicit accessor selectors | `getGetterName`/`getSetterName` → `Selector`, and a `Selector` → `String` accessor |
| 8 | readonly vs readwrite | `getPropertyAttributes()` bitmask | the attribute enum, or predicates like `isReadOnly` |
| 9 | `@autoproperty intproperty4::id{TestInterface}` | `TestInterface *` | `ObjCObjectPointerType` carrier + `getInterfaceDecl` |
| 10 | `@autoproperty intproperty5::id{TestProtocol}` | `id<TestProtocol>` | protocol qualifiers on `ObjCObjectPointerType` (`getNumProtocols`/`getProtocol(i)`) |
| 11 | `availability = macos(v"100.11.0")` | `API_AVAILABLE(macos(100.11))` on a decl | `AvailabilityAttr`: platform name + `getIntroduced()` as a version |

(11) is the only one that is not a `DeclObjC.h` question — it is an attribute, and it applies to
properties as well as to interfaces (`@autoproperty length::Int32 availability = macos(…)`).

Also needed, and cheap: **`DeclKindMap.jl` entries** for `ObjCInterfaceDecl`, `ObjCProtocolDecl`
and `ObjCPropertyDecl`, so `CC.resolve` hands back the typed carrier instead of a base `Decl`.
Without that the walk in `facts.jl` cannot dispatch on them at all.

## Explicitly NOT needed for the bar

- **`ObjCMethodDecl`.** The old generator emitted wrapper types and properties only; no
  assertion covers methods. Worth having eventually, not for parity.
- **`ObjCCategoryDecl`, `ObjCImplementationDecl`, ivars.** Untouched by the fixture.
- **ObjC generics.** `NSArray<id<TestProtocol>> *` was `broken=true` in the old suite —
  `Vector{TestProtocol}` never worked. Reaching parity means keeping it broken, not fixing it.

## On this side, once the carriers exist

`facts.jl` gains two node kinds (`ObjCInterfaceFacts`, `ObjCProtocolFacts`) carrying a name, a
supertype key and a property list; `emit.jl` gains the `@objcwrapper`/`@objcproperties` forms.
Ordering already handles it — a protocol hierarchy is just more edges, and `NSObject` is an
external root like any system typedef.

The fixture needs the macOS SDK (`#import <Foundation/Foundation.h>`), so the testset stays
`@static if Sys.isapple()`, and `test/generators.jl` must drop `objectiveC.h` from its `SKIP`
set at the same time.

## Unrelated, but in flight and worth knowing

The uncommitted `getBytes`/`getString` split in `ClangCompiler/src/clang/api/AST/Expr.jl` fixes a
defect this branch currently works around: `getString` aborts the process on a wide, UTF-16 or
UTF-32 literal, because upstream's `getCharByteWidth() == 1` assertion is compiled into the
release library. `CxxMacros.translate_expr` therefore *skips* wide string literals —
`#define SL L"string"` in `test/include/macro.h` is a documented skip. Once `getBytes` lands,
that skip can become a translation.
