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

`Options` honours 22 keys, named to match `generator.toml` so a config maps across unchanged:

- `[general]`: library_name, library_names, module_name, prologue_file_path,
  epilogue_file_path, jll_pkg_name, jll_pkg_extra, export_symbol_prefixes, output_ignorelist,
  generate_isystem_symbols, use_julia_native_enum_type, print_using_CEnum
- `[codegen]`: skip_static_functions, use_ccall_macro, wrap_variadic_function, use_julia_bool,
  is_function_strictly_typed, opaque_as_mutable_struct, add_record_constructors,
  field_access_method_list
- `[codegen.macro]`: macro_mode, add_comment_for_skipped_macro

`validate_options.jl` asserts each one has an observable effect — 28 checks. Note what it does
*not* do: every option is checked in isolation, so no pair is known to compose.

Still unimplemented: doc comments (`extract_c_comment_style` and friends), the two-file
api/common split, `auto_mutability`, `add_fptr_methods`. See GENERATORS-REWORK.md §0.1.
`Options(TOML.parsefile(path))` reads the [general] and [codegen] tables directly.
Everything else in the ~45-key surface is still unimplemented -- GENERATORS-REWORK.md 0.1.
