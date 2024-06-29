# Changelog

This documents notable changes in Clang.jl. The format is based on [Keep a
Changelog](https://keepachangelog.com).

## [Unreleased](https://github.com/JuliaInterop/Clang.jl/compare/v0.18.3...master)

### Added

- Added support for recognizing signed chars as enum constants
  ([5a1cc29](https://github.com/JuliaInterop/Clang.jl/commit/5a1cc29c154ed925f01e59dfd705cbf8042158e4)).
- Added bindings for Clang 17, which should allow compatibility with Julia 1.12
  ([#494]).

### Fixed

- The generator will now explicitly import the symbols from `CEnum` it uses to
  avoid implicit imports ([#488]).
- Added support to the auditor for detecting structs and function-like macros of
  the same name, which previously caused the generator to crash ([#500]).

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
