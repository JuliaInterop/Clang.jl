# cxx/ — the ClangCompiler-backed generator

Staging area for the new pipeline. These modules depend only on ClangCompiler and are tested by
standalone scripts, because ClangCompiler and Clang.jl cannot share a process until libclang is
removed from `src/` (GENERATORS-REWORK.md §3.4).

    CxxFacts.jl    extract   — one reachability walk over the AST -> nodes of FACTS + edges
    CxxOrder.jl    order     — emission order + a cut set (edge and degraded field, together)
    CxxCodegen.jl  codegen   — facts -> Julia
    CxxMacros.jl   macros    — clang parses each macro body; the typed AST is translated

## Running the validators

Needs an environment with ClangCompiler **and** CEnum, carrying ClangCompiler's
`LocalPreferences.toml` — without it the released `libclangex_jll` loads instead of the local
build and symbols fail at call time:

    mkdir -p /tmp/cxxenv && cd /tmp/cxxenv
    julia --project=. -e 'using Pkg; Pkg.develop(path="/path/to/ClangCompiler"); Pkg.add("CEnum")'
    cp /path/to/ClangCompiler/LocalPreferences.toml .

    julia --project=/tmp/cxxenv cxx/validate_facts.jl          # extraction vs the ABI baseline
    julia --project=/tmp/cxxenv cxx/validate_order.jl          # ordering on the cycle fixtures
    julia --project=/tmp/cxxenv cxx/validate_order_libxml2.jl  # ordering at scale
    julia --project=/tmp/cxxenv cxx/validate_e2e.jl            # generate + load + ABI compare
    julia --project=/tmp/cxxenv cxx/validate_options.jl        # each option has an observable effect
    julia --project=/tmp/cxxenv cxx/validate_abi.jl fixtures libxml2 glib pango
    julia --project=/tmp/cxxenv cxx/validate_macros.jl        # macro values vs C semantics

`validate_abi.jl` is the strongest of these and the one to run before claiming anything. The
others compare against the old generator's recorded output; this one compares every emitted type
against the `ASTRecordLayout` clang computed for the same declaration — size, alignment and every
field offset — so it needs no baseline and works on any corpus. It found four ABI-silent defects
the fixture baseline passed (GENERATORS-REWORK.md, "S-C: done, and what it cost").

Its three checks have each been fault-injected and shown to fail: mapping `int`→`Cshort` trips
size and alignment, reversing field order trips offsets, and a load failure is reported as a
finding rather than printed and forgotten — a run that measures nothing must not summarise as a
run that agreed.

## Option surface

`Options` honours 32 keys, named to match `generator.toml` so a config maps across unchanged.
`Options(TOML.parsefile(path))` reads them straight out of the `[general]`, `[codegen]` and
`[codegen.macro]` tables.

- `[general]`: library_name, library_names, module_name, prologue_file_path,
  epilogue_file_path, jll_pkg_name, jll_pkg_extra, export_symbol_prefixes, output_ignorelist,
  generate_isystem_symbols, use_julia_native_enum_type, print_using_CEnum, add_fptr_methods,
  skip_static_functions,
  auto_mutability, auto_mutability_with_new, auto_mutability_includelist,
  auto_mutability_ignorelist
- `[codegen]`: use_ccall_macro, wrap_variadic_function, use_julia_bool,
  is_function_strictly_typed, opaque_as_mutable_struct, add_record_constructors,
  field_access_method_list, extract_c_comment_style, fold_single_line_comment,
  show_c_function_prototype
- `[codegen.macro]`: macro_mode, add_comment_for_skipped_macro
- Julia-only (no TOML spelling): `callback_documentation`, a `(node, lines) -> lines` hook

`validate_options.jl` asserts each one has an observable effect — 53 checks. Note what it does
*not* do: every option is checked in isolation, so no pair is known to compose.

`auto_mutability` reproduces the existing heuristic exactly: a record stays immutable only when
some function takes it **by pointer** while also taking an integer — the pointer-and-length
shape, where the caller wants an array and an immutable struct is what makes that work.
Everything else becomes a `mutable struct`, since `Ref` on one gives C a stable address. Over
resolved `TypeRef`s that rule is a direct question about each parameter; the libclang pass
spells it over cursors and `node.adj` indices.

The api/common split is `generate(...; api_io=...)`: function wrappers there, everything else
(macros included) to `io`, and neither file gets a module wrapper, `using CEnum`, prologue or
epilogue -- matching the existing FunctionPrinter/CommonPrinter pair.

`"doxygen"` renders the commands that carry structure — `\param`, `\return`, `\note`, `\bug`
and friends — into Markdown sections and bullet lists. It is a much smaller renderer than
`src/generator/documentation.jl`, so its output is not character-identical to the old pass;
it carries the same information in the same order. Corpora written in GTK-doc style (libxml2,
glib) use no such commands, so `"raw"` and `"doxygen"` come out near-identical there.
