# Changelog

This documents notable changes in Clang.jl. The format is based on [Keep a
Changelog](https://keepachangelog.com).

## [v0.18.0] - 2024-01-05

### Added

- Doxygens `@deprecated` command will now be translated to a `!!! compat`
  admonition ([#460]).

### Breaking

- The `callback_documentation` callback will be called whenever it is set, and
  any docstring parsed from the headers will be passed to it ([#458],
  [#462]). The signature of the callback changed from `f(node::ExprNode)` to
  `f(node::ExprNode, doc::Vector{String})`.
