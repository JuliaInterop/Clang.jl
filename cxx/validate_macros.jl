# Macros end to end: generate, load, and check the constants hold the values a C compiler gives.
#
# This is `test/macros.jl` run through the new backend. It cannot live in the test suite yet —
# Clang.jl and ClangCompiler cannot share a process (GENERATORS-REWORK.md §3.4) — so it stays a
# standalone script until S-D, at which point `test/macros.jl` becomes the same assertions and
# the two #510/#382 `@test_broken`s should report Unexpected Pass.
#
#   julia --project=/tmp/cxxenv cxx/validate_macros.jl

include(joinpath(@__DIR__, "CxxCodegen.jl"))
using .CxxCodegen

const R = dirname(@__DIR__)
pass = fail = 0

function check(label, cond)
    global pass, fail
    cond ? (pass += 1) : (fail += 1)
    println("  ", cond ? "OK  " : "FAIL", "  ", label)
end

"Generate `header` into a fresh module and return it, or `nothing` if it will not load."
function load_header(header; args=String[], name=:M)
    path = tempname() * ".jl"
    st = open(path, "w") do io
        CxxCodegen.generate([header]; args=args,
                            options=CxxCodegen.Options(library_name="libnotused"), io=io)
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
check("loads", m !== nothing)
if m !== nothing
    println("  (translated $(st.macros) of $(st.macros_seen) discovered)")
    # #356: adjacent string literals are ONE StringLiteral by the time clang is done.
    check("S == \"abcdef\"", has(m, :S) && val(m, :S) == "abcdef")
    check("EL == \"DCAP_NONSPATIAL\"", has(m, :EL) && val(m, :EL) == "DCAP_NONSPATIAL")
    # These name CPL_STATIC_CAST, which nothing declares. Emitting them is the UndefVarError
    # that test/macros.jl exists to pin.
    check("GINTBIG_MAX not emitted", !has(m, :GINTBIG_MAX))
    check("GUINTBIG_MAX not emitted", !has(m, :GUINTBIG_MAX))
    # #389: `#define foo foo` beside `int foo(void);` must not become `const foo = foo`.
    check("foo is the function, not a const", has(m, :foo))
    # #357: a wide string literal aborts clang's getString(); it must be skipped, not crashed on.
    check("SL (wide literal) skipped", !has(m, :SL))
end

println("── large-integer-literals.h: C11 6.4.4.1p5 ──")
m2, _ = load_header(joinpath(R, "test", "include", "large-integer-literals.h"); name=:M2)
check("loads", m2 !== nothing)
if m2 !== nothing
    check("TEST == 0x80000001", has(m2, :TEST) && val(m2, :TEST) == 0x80000001)
    check("TEST_2 == 2147483649", has(m2, :TEST_2) && val(m2, :TEST_2) == 2147483649)
    check("TEST_SIGNED == 1", has(m2, :TEST_SIGNED) && val(m2, :TEST_SIGNED) == 1)
    check("TEST_SIGNED_2 == 2147483646", has(m2, :TEST_SIGNED_2) && val(m2, :TEST_SIGNED_2) == 2147483646)
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
check("loads", m3 !== nothing)
if m3 !== nothing
    check("#510  FIVE == 5", has(m3, :FIVE) && val(m3, :FIVE) == 5)
    check("#382  MPI_FLOAT_INT == -1946157056",
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
    check("loads", m4 !== nothing)
    if m4 !== nothing
        println("  (translated $(st4.macros) of $(st4.macros_seen) discovered)")
        for (s, want) in [(:G_MAXUINT, 4294967295), (:G_MAXINT, 2147483647),
                          (:G_MININT, -2147483648), (:G_MAXUINT64, 0xffffffffffffffff),
                          (:G_MININT64, typemin(Int64)), (:G_MAXINT8, 127),
                          (:G_PI, 3.141592653589793), (:G_DIR_SEPARATOR, Cchar('/'))]
            check("$s == $want", has(m4, s) && val(m4, s) == want)
        end
    end
end

println("── macro_mode = \"disable\" ──")
path = tempname() * ".jl"
open(path, "w") do io
    CxxCodegen.generate([joinpath(R, "test", "include", "macro.h")];
                        options=CxxCodegen.Options(macro_mode="disable"), io=io)
end
check("no macro emitted when disabled", !occursin("const EL", read(path, String)))

println()
println("macros: $pass passed, $fail failed")
exit(fail == 0 ? 0 : 1)
