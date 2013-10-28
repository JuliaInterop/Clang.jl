.. _doc-debugging:

Debugging
=========

General
*******

- pass `diagnostics = true` to *cindex.parse_header*
- set `clang_args = ["-v"]` in *cindex.parse_header*

Missing AST Items
*****************

If some AST elements (for example, FunctionDecl entries) appear to be missing, verify that all headers are locatable. To diagnose, pass `diagnostics = true` to `cindex.parse_header`. Doing so may uncover the following error.

Missing stddef.h (or others)
****************************

See `http://clang.llvm.org/docs/LibTooling.html#libtooling-builtin-includes`
