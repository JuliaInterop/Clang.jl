# Macros end to end: generate, load, and check the constants hold the values a C compiler gives.
#
# Macros do not go through a token re-lexer. clang parses each `#define` body as C, in the same
# translation unit as the headers, and the typed AST is translated — so precedence, literal
# typing, cast targets and macro expansion are all the compiler's answers rather than ours
# (`MACRO-HANDLING.md`). Issues #510 and #382 were `@test_broken` against the token-based path.

using Test
using Clang
using Clang.Generators

using Clang.Generators.CxxEmit: Options, generate

const R = dirname(@__DIR__)

mcheck(label, cond) = @testset "$label" begin
    @test cond
end

"Generate `header` into a fresh module and return it, or `nothing` if it will not load."
function load_header(header; args=String[], name=:M)
    path = tempname() * ".jl"
    st = open(path, "w") do io
        generate([header]; args=args,
                            options=Options(library_name="libnotused"), io=io)
    end
    m = Module(name)
    Core.eval(m, :(using CEnum: CEnum, @cenum))
    Core.eval(m, :(const libnotused = "libnotused"))
    try
        Base.include(m, path)
    catch err
        println("  LOAD FAILED (", path, "): ", first(split(sprint(showerror, err), "\n")))
        return nothing, st
    end
    return m, st
end

has(m, s) = m !== nothing && Base.invokelatest(isdefined, m, s)
val(m, s) = Base.invokelatest(getfield, m, s)

# ------------------------------------------------------------------------------------------
println("── macro.h: six historical regressions ──")
m, st = load_header(joinpath(R, "test", "include", "macro.h"))
mcheck("loads", m !== nothing)
if m !== nothing
    println("  (translated $(st.macros) of $(st.macros_seen) discovered)")
    # #356: adjacent string literals are ONE StringLiteral by the time clang is done.
    mcheck("S == \"abcdef\"", has(m, :S) && val(m, :S) == "abcdef")
    mcheck("EL == \"DCAP_NONSPATIAL\"", has(m, :EL) && val(m, :EL) == "DCAP_NONSPATIAL")
    # These name CPL_STATIC_CAST, which nothing declares. Emitting them is the UndefVarError
    # that test/macros.jl exists to pin.
    mcheck("GINTBIG_MAX not emitted", !has(m, :GINTBIG_MAX))
    mcheck("GUINTBIG_MAX not emitted", !has(m, :GUINTBIG_MAX))
    # #389: `#define foo foo` beside `int foo(void);` must not become `const foo = foo`.
    mcheck("foo is the function, not a const", has(m, :foo))
    # #357: `L"string"` used to be SKIPPED, because clang's getString asserts a byte width of 1
    # and the release library aborts on it. ClangCompiler's getBytes reads the same arena bytes
    # at any width, so the macro now translates — the useful value is the text, and the wide
    # encoding is a property of the C type (`wchar_t*`), which a `const` could not carry anyway.
    mcheck("SL (wide literal) translates", has(m, :SL) && val(m, :SL) == "string")
end

println("── large-integer-literals.h: C11 6.4.4.1p5 ──")
m2, _ = load_header(joinpath(R, "test", "include", "large-integer-literals.h"); name=:M2)
mcheck("loads", m2 !== nothing)
if m2 !== nothing
    mcheck("TEST == 0x80000001", has(m2, :TEST) && val(m2, :TEST) == 0x80000001)
    mcheck("TEST_2 == 2147483649", has(m2, :TEST_2) && val(m2, :TEST_2) == 2147483649)
    mcheck("TEST_SIGNED == 1", has(m2, :TEST_SIGNED) && val(m2, :TEST_SIGNED) == 1)
    mcheck("TEST_SIGNED_2 == 2147483646", has(m2, :TEST_SIGNED_2) && val(m2, :TEST_SIGNED_2) == 2147483646)
end

println("── casts: issues #510 and #382 ──")
# Verified against cc: (int)4+1 == 5, (int)0x8c000000 == -1946157056.
dir = mktempdir(); hdr = joinpath(dir, "casts.h")
write(hdr, """
typedef int INT;
typedef int MPI_Datatype;
#define FIVE          ((INT) 4+1)
#define MPI_FLOAT_INT ((MPI_Datatype)0x8c000000)
""")
m3, _ = load_header(hdr; name=:M3)
mcheck("loads", m3 !== nothing)
if m3 !== nothing
    mcheck("#510  FIVE == 5", has(m3, :FIVE) && val(m3, :FIVE) == 5)
    mcheck("#382  MPI_FLOAT_INT == -1946157056",
          has(m3, :MPI_FLOAT_INT) && val(m3, :MPI_FLOAT_INT) == -1946157056)
end

println("── glib: values checked against C semantics ──")
# The fixture headers are too small to exercise the paths that broke at scale. Each of these
# pins one: G_MININT the unary-minus opcode (compared as a bare Integer it never matched, so
# every negative constant was silently skipped), G_MAXUINT/G_MAXUINT64 the signed reading of an
# APInt at both ends of verification, G_DIR_SEPARATOR the character literal, G_PI the float path.
const GLIB = joinpath(homedir(), ".julia", "artifacts",
                      "d3c452363ecbfffb1b5e29644395f7016c0ec781")
if !isdir(GLIB)
    println("  SKIP  glib artifact not present")
else
    m4, st4 = load_header(joinpath(GLIB, "include", "glib-2.0", "glib.h");
                          args=["-I" * joinpath(GLIB, "include", "glib-2.0"),
                                "-I" * joinpath(GLIB, "lib", "glib-2.0", "include")], name=:M4)
    mcheck("loads", m4 !== nothing)
    if m4 !== nothing
        println("  (translated $(st4.macros) of $(st4.macros_seen) discovered)")
        for (s, want) in [(:G_MAXUINT, 4294967295), (:G_MAXINT, 2147483647),
                          (:G_MININT, -2147483648), (:G_MAXUINT64, 0xffffffffffffffff),
                          (:G_MININT64, typemin(Int64)), (:G_MAXINT8, 127),
                          (:G_PI, 3.141592653589793), (:G_DIR_SEPARATOR, Cchar('/'))]
            mcheck("$s == $want", has(m4, s) && val(m4, s) == want)
        end
    end
end

println("── macro_mode = \"disable\" ──")
path = tempname() * ".jl"
open(path, "w") do io
    generate([joinpath(R, "test", "include", "macro.h")];
                        options=Options(macro_mode="disable"), io=io)
end
mcheck("no macro emitted when disabled", !occursin("const EL", read(path, String)))
