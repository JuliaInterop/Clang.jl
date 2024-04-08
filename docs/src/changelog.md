# Changelog

This documents notable changes in Clang.jl. The format is based on [Keep a
Changelog](https://keepachangelog.com).

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
