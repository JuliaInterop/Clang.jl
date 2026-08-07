# Every option must have an observable effect on the output.
#
# This is deliberately a per-option check, not an interaction check: it proves each key is wired
# up, not that any pair of them composes. Interactions are still untested.

include(joinpath(@__DIR__, "CxxCodegen.jl"))
using .CxxCodegen

const d = mktempdir()
write(joinpath(d, "h.h"), """
struct Keep { int a; };
struct Drop { int b; };
struct Opaque;
struct Bits { unsigned lo : 3; unsigned hi : 5; int whole; };
struct Plain { int x; double y; };
struct HasBool { _Bool b; int n; };
_Bool flag(_Bool b);
int fn_keep(int x);
static int fn_static(void);
struct Opaque *make(void);
""")
write(joinpath(d, "pro.jl"), "# PROLOGUE MARKER")
write(joinpath(d, "epi.jl"), "# EPILOGUE MARKER")

"Generate `h.h` under `opts` and return the source text."
function gen(; kw...)
    buf = IOBuffer()
    CxxCodegen.generate([joinpath(d, "h.h")]; io=buf, options=CxxCodegen.Options(; kw...))
    return String(take!(buf))
end

pass = fail = 0
function check(label, ok)
    global pass, fail
    ok ? (pass += 1) : (fail += 1)
    println(rpad(label, 34), ok ? "OK" : "FAILED")
end

# --- the original batch, all at once ---
src = gen(library_name="libdemo", module_name="Demo",
          prologue_file_path=joinpath(d, "pro.jl"), epilogue_file_path=joinpath(d, "epi.jl"),
          export_symbol_prefixes=["fn_"], output_ignorelist=["Drop"],
          skip_static_functions=true, use_ccall_macro=true)
check("module wrapper", occursin("module Demo", src) && occursin("end # module", src))
check("prologue", occursin("PROLOGUE MARKER", src))
check("epilogue", occursin("EPILOGUE MARKER", src))
check("export prefixes", occursin("PREFIXES", src))
check("ignorelist drops Drop", !occursin("struct Drop", src))
check("...but keeps Keep", occursin("struct Keep", src))
check("library_name used", occursin("libdemo", src))
check("@ccall form", occursin("@ccall", src))
check("static skipped", !occursin("fn_static", src))

# --- one option at a time, each against its own default ---
base = gen()

check("use_julia_bool default -> Bool", occursin("b::Bool", base))
check("use_julia_bool=false -> UInt8",
      (s = gen(use_julia_bool=false); occursin("b::UInt8", s) && !occursin("b::Bool", s)))

check("strictly_typed default off", occursin("function fn_keep(x)", base))
check("is_function_strictly_typed=true",
      occursin("function fn_keep(x::Cint)", gen(is_function_strictly_typed=true)))

check("opaque default mutable struct", occursin("mutable struct Opaque", base))
check("opaque_as_mutable_struct=false",
      (s = gen(opaque_as_mutable_struct=false);
       occursin("const Opaque = Cvoid", s) && !occursin("mutable struct Opaque", s)))

# `Bits` has bit-fields, so it is blobbed and has no default constructor of its own.
check("no record constructor by default", !occursin("function Bits(", base))
check("add_record_constructors=true", occursin("function Bits(", gen(add_record_constructors=true)))
check("add_record_constructors by name",
      (s = gen(add_record_constructors=["Bits"]); occursin("function Bits(", s)))
check("...and only that name",
      !occursin("function Keep(", gen(add_record_constructors=["Bits"])))

# `Plain` is a plain struct: it gets no pointer accessors unless asked for by name.
check("no pointer accessors by default", !occursin("Ptr{Plain}, f::Symbol", base))
check("field_access_method_list",
      occursin("Ptr{Plain}, f::Symbol", gen(field_access_method_list=["Plain"])))

check("setproperty! for blobbed record", occursin("setproperty!(x::Ptr{Bits}", base))

check("library_names overrides per file",
      (s = gen(library_name="libdefault", library_names=Dict("h\\.h" => "libspecial"));
       occursin("libspecial", s) && !occursin("libdefault", s)))
check("library_names falls back when no match",
      (s = gen(library_name="libdefault", library_names=Dict("nomatch\\.h" => "libspecial"));
       occursin("libdefault", s) && !occursin("libspecial", s)))

check("use_julia_native_enum_type=false -> @cenum", occursin("using CEnum", base))
check("print_using_CEnum=false", !occursin("using CEnum", gen(print_using_CEnum=false)))
# Needs a header pulling in a system declaration that is NOT already mapped to a Julia builtin.
# `h.h` includes nothing at all, and `<stdint.h>` alone is no better: `uint32_t` and friends are
# in `SYSTEM_TYPEDEFS`, so they are skipped either way and the option looks inert. `FILE` is a
# real system record with no Julia counterpart.
let sysh = joinpath(d, "sys.h")
    write(sysh, "#include <stdio.h>\nint widen(FILE *f);\n")
    with = IOBuffer(); CxxCodegen.generate([sysh]; io=with, options=CxxCodegen.Options())
    without = IOBuffer()
    CxxCodegen.generate([sysh]; io=without,
                        options=CxxCodegen.Options(generate_isystem_symbols=false))
    a, b = String(take!(with)), String(take!(without))
    check("generate_isystem_symbols=false shrinks output", length(b) < length(a))
    check("...and the API itself survives", occursin("function widen", b))
end

# --- doc comments ---
let R = dirname(@__DIR__), doch = joinpath(R, "test", "include", "documentation.h")
    plain = IOBuffer(); CxxCodegen.generate([doch]; io=plain, options=CxxCodegen.Options())
    check("no docstring by default", !occursin("\"\"\"", String(take!(plain))))

    raw = IOBuffer()
    CxxCodegen.generate([doch]; io=raw,
                        options=CxxCodegen.Options(extract_c_comment_style="raw"))
    r = String(take!(raw))
    check("raw: markers stripped", occursin("@brief Dummy function.", r) && !occursin("/**", r))

    dox = IOBuffer()
    CxxCodegen.generate([doch]; io=dox,
                        options=CxxCodegen.Options(extract_c_comment_style="doxygen"))
    x = String(take!(dox))
    check("doxygen: brief becomes body text", occursin("Dummy function.", x) &&
                                              !occursin("@brief", x))
    check("doxygen: @return becomes a section", occursin("### Returns", x))
    check("doxygen: @param becomes a bullet",
          occursin("### Parameters", x) && occursin("* `foo`: A parameter.", x))
    # A Documenter admonition's body is the indented block under it; flush left it renders as
    # an empty admonition followed by an unrelated paragraph.
    check("doxygen: admonition body is indented",
          occursin("!!! warning \"Bug\"\n    May wipe your disk.", x))

    # The docstring has to actually attach, which a bare `occursin` cannot tell you.
    p = tempname() * ".jl"; write(p, x)
    m = Module(:DocCheck); Core.eval(m, :(using CEnum: CEnum, @cenum))
    Core.eval(m, :(const libfoo = "libfoo"))
    Base.include(m, p)
    attached = Base.invokelatest() do
        occursin("Dummy function", string(Base.Docs.doc(Base.Docs.Binding(m, :doxygen_func))))
    end
    check("doxygen: docstring attaches to the method", attached)

    fold = IOBuffer()
    write(joinpath(d, "one.h"), "/// One line.\nint one(void);\n")
    CxxCodegen.generate([joinpath(d, "one.h")]; io=fold,
                        options=CxxCodegen.Options(extract_c_comment_style="raw",
                                                   fold_single_line_comment=true))
    check("fold_single_line_comment", occursin("\"\"\"One line.\"\"\"", String(take!(fold))))
end

println()
println("options: $pass passed, $fail failed")
exit(fail == 0 ? 0 : 1)
