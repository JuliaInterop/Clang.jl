# Changelog

This documents notable changes in Clang.jl. The format is based on [Keep a
Changelog](https://keepachangelog.com).

## Unreleased

### Changed

- **The generator now runs on Clang's C++ API** through ClangCompiler.jl. The 21-pass pipeline
  over a mutable expression DAG is replaced by three stages over plain data — extract, order,
  emit. Most of those passes existed only to reconstruct, by name and source location, what
  libclang could not express; parsing all headers into one translation unit and keying on
  `getCanonicalDecl` answers those questions directly.
- `ctx.nodes`, a plain `Vector{Node}` of facts, replaces `ctx.dag` for rewriters. The two-stage
  `BUILDSTAGE_NO_PRINTING` / `BUILDSTAGE_PRINTING_ONLY` workflow is unchanged.

### Removed

- **The libclang binding.** `Clang.LibClang`, `CLCursor`, `CLType`, `parse_headers`, `children`,
  `spelling`, `@add_def` and the rest of the object layer are gone, along with `lib/16…21/`.
  libclang and clang-cpp both register LLVM's global command-line options statically, so no
  process can load both, and the generator needs the C++ side. Code that walked an AST rather
  than generating bindings should pin `Clang@0.19` or use ClangCompiler.jl directly.
- Objective-C support was removed with the libclang layer, then restored on ClangCompiler's
  C++ surface (ClangCompiler#49/#52): `@objcwrapper`/`@objcproperties` output with supertypes,
  protocol conformance, availability, and explicit getters/setters. ObjC generics remain
  unsupported, as they always were. Wide string literal macros (#357) now translate instead of
  being skipped.

### Fixed

- Blobbed records were under-aligned: `NTuple{N,UInt8}` reproduces clang's size but always has
  alignment 1. They now use a tuple of a wider unsigned.
- `_Nullable` pointers and cvr-qualified builtins (`const int`, `unsigned const int`) were not
  recognised and became `Cvoid`, which is *zero-sized* in Julia — silently shifting every
  following field. macOS `FILE` came out 120 bytes instead of 152.
- Macro casts to a pointer, negative constants, and unsigned folds. Issues #510 and #382 now
  produce the values a C compiler gives.
- A parameter whose name collides with a type in its own signature (glib's
  `g_date_to_struct_tm(GDate*, struct tm*)`).

## [v0.19.3] - 2026-03-03

### Changed

- Switch to Clang_unified_jll.jl for improved compatibility ([#563]).

## [v0.19.2] - 2026-02-25

### Fixed

- Implement two-arg `hash` to avoid invalidations ([#562]).

## [v0.19.1] - 2026-01-14

### Added

- Added support for Clang 20 and Clang 21 ([#550], [#551], [#558]).
- Added support for recognizing `intptr_t` as `Cptrdiff_t` [#552].

## [v0.19.0] - 2025-08-14

### Added

- Added support for recognizing signed chars as enum constants
  ([5a1cc29](https://github.com/JuliaInterop/Clang.jl/commit/5a1cc29c154ed925f01e59dfd705cbf8042158e4)).
- Added bindings for Clang 17/18/19, which should allow compatibility with Julia
  1.12 and 1.13 ([#494], [#503], [#526]).
- Added `TranslationUnit(::Function)`,
  `parse_header(::Function)`, and `parse_headers(::Function)` to
  help with using Clang.jl in a memory-safe way ([#545]).
- Added initial support for generating bindings for ObjectiveC code, currently
  limited to interfaces and protocols ([#505], [#519], [#522], [#524], [#527]).
- Implemented `Base.propertynames` for Union structs ([#538]).

### Fixed

- The generator will now explicitly import the symbols from `CEnum` it uses to
  avoid implicit imports ([#488]).
- Added support to the auditor for detecting structs and function-like macros of
  the same name, which previously caused the generator to crash ([#500]).
- Large L-suffixed integer literals that are greater than `typemax(Clong)` will now be wrapped
  as unsigned integers (`Culong`) ([#516]).
- Fixed handling of non-field struct children ([#479]).

## [v0.18.3] - 2024-04-23

### Fixed

- Fixed a regression regarding shard names ([#487]).

## [v0.18.2] - 2024-04-20

### Added

- Add an option `generate_isystem_symbols` for ignoring all symbols in the `-isystem` headers ([#485]).

## [v0.18.1] - 2024-04-09

### Fixed

- Improved support for the internal changes in Clang 16
  ([8652cd4](https://github.com/JuliaInterop/Clang.jl/commit/8652cd4f73ffe2a1e5996f6bb8efe5273a3da4a2)).

## [v0.18.0] - 2024-04-08

### Added

- Doxygens `@deprecated` and `@bug` commands will now be translated to `!!!
  compat` and `!!! danger` admonitions, respectively ([#460], [#463]).
- Initial support for non-field struct children ([#479]).
- Experimental support has been added for a few C++-isms ([#432], [#435]).
- `CXFile` and `unique_id` support ([#424])

### Changed

- Renamed the 'Parameters' docstring section to 'Arguments' ([#466]).
- Generated `unsafe_convert()` methods now specify `RefValue` instead of `Ref`
  to avoid method ambiguities ([#474]).

### Fixed

- Fixed compatibility with Julia 1.11 and Clang 16 ([#465]).
- Updated the compiler shards we use, which should fix artifact issues on
  Windows ([#480]).

### Breaking

- The `callback_documentation` callback will be called whenever it is set, and
  any docstring parsed from the headers will be passed to it ([#458],
  [#462]). The signature of the callback changed from `f(node::ExprNode)` to
  `f(node::ExprNode, doc::Vector{String})`.
