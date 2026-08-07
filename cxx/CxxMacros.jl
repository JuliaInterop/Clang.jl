"""
    CxxMacros

Macro translation built on clang's real C++ API, via ClangCompiler.jl.

!!! warning "This module cannot be loaded alongside Clang.jl"
    `Clang.jl` loads libclang from `Clang_unified_jll`; `ClangCompiler.jl` loads `clang-cpp`
    via `libclangex`. Both statically register LLVM's global CommandLine options, so importing
    the second one aborts the process:

        julia: CommandLine Error: Option 'sanitizer-early-opt-ep' registered more than once!

    This happens in either order and is why the C++ frontend cannot be a package *extension*
    of Clang.jl -- an extension loads into the same process. See `GENERATORS-REWORK.md` §3.3.
    This module therefore depends only on ClangCompiler, and is written to be lifted into
    whichever package ends up owning the C++ frontend.

The generator's own macro path re-lexes a `#define`'s tokens into Julia tokens, which means
every rule about precedence, casts, literal typing and macro expansion has to be
re-implemented — and each re-implementation is a chance to be silently wrong. See
`MACRO-HANDLING.md` for the defects that produced.

This module does not transliterate. For each object-like macro it emits one probe declaration
into the *same* translation unit as the headers,

    __auto_type __cjl_probe_17 = (MACRO_NAME);

and then reads what clang made of it: whether it is valid C at all (`isInvalidDecl`), its type
(`getType`, with typedefs preserved), its typed AST (`getInit`), and — when it folds — its
constant value. Parsing, typing and macro expansion all become the compiler's job.

The probes must share the headers' parse: a typedef declared in an earlier incremental parse is
invisible to the parser later, so `(INT)x` would not parse in a follow-up.
"""
module CxxMacros

import ClangCompiler as CC

export translate_macros, MacroTranslated, MacroSkipped

# ------------------------------------------------------------------------------------------
# Results
# ------------------------------------------------------------------------------------------
"A macro that was not translated, and why."
struct MacroSkipped
    name::Symbol
    reason::String
end

"A translated macro: `expr` is the Julia value, `ctype` what clang deduced, `folded` its
constant value when clang could fold it (`nothing` otherwise)."
struct MacroTranslated
    name::Symbol
    expr::Any
    ctype::String
    folded::Union{Nothing,Integer}
end

# ------------------------------------------------------------------------------------------
# 1. Discover
# ------------------------------------------------------------------------------------------
"""
Every macro the given headers actually define, as `name => MacroInfo`.

Three origins are excluded and only the first is what `isInSystemHeader` catches: clang's
predefines buffer and anything from a `-D` flag live in synthetic buffers, not in any header.
Builtin macros and header guards are dropped too — the guard test is clang's own
`isUsedForHeaderGuard`, not a `_H` suffix rule, so a guard named anything else is still caught.
"""
function discover_macros(pp, sm; include_system::Bool=false)
    out = Tuple{Symbol,Any}[]
    for ii in CC.getMacros(pp)
        name = CC.getName(ii)
        mi = CC.getMacroInfo(pp, ii)
        mi.ptr == C_NULL && continue
        CC.isBuiltinMacro(mi) && continue
        CC.isUsedForHeaderGuard(mi) && continue
        loc = CC.getDefinitionLoc(mi)
        (CC.isWrittenInBuiltinFile(sm, loc) || CC.isWrittenInCommandLineFile(sm, loc)) && continue
        (!include_system && CC.isInSystemHeader(sm, loc)) && continue
        push!(out, (Symbol(name), mi))
    end
    return sort!(out; by=first)
end

# ------------------------------------------------------------------------------------------
# 2. Translate a typed clang AST into a Julia expression
# ------------------------------------------------------------------------------------------
struct Untranslatable <: Exception
    what::String
end

# C's binary operators that mean the same thing in Julia. `/` is deliberately absent: C's `/`
# on integers truncates and Julia's does not, so it is handled per-type below. `^` is absent
# because it is xor in C and exponentiation in Julia.
const BINOPS = Dict("+" => :+, "-" => :-, "*" => :*, "%" => :rem,
                    "<<" => :<<, ">>" => :>>, "&" => :&, "|" => :|,
                    "==" => :(==), "!=" => :!=, "<" => :<, ">" => :>,
                    "<=" => :<=, ">=" => :>=, "&&" => :&&, "||" => :||)

"""
Unary opcodes, by name.

These were once written as the bare integers 6–9, which are the right *values* — and never
matched, because `getOpcode` returns a `CXUnaryOperatorKind`, and a Julia `@enum` does not
compare equal to an `Integer`. Every unary operator therefore fell through to
`Untranslatable`, so **every negative constant in every corpus was silently skipped**:
glib's `G_MININT`, `G_MINLONG`, `G_MININT64` and friends all vanished, and the only symptom was
a slightly lower translation count. Naming them makes the mismatch a load error rather than a
silent no-op.
"""
const UO_PLUS  = CC.LibClangEx.CXUnaryOperatorKind_UO_Plus
const UO_MINUS = CC.LibClangEx.CXUnaryOperatorKind_UO_Minus
const UO_NOT   = CC.LibClangEx.CXUnaryOperatorKind_UO_Not
const UO_LNOT  = CC.LibClangEx.CXUnaryOperatorKind_UO_LNot
# GNU `__extension__`, which is how glib writes its 64-bit constants. It only suppresses a
# pedantic diagnostic, so it is transparent here.
const UO_EXTENSION = CC.LibClangEx.CXUnaryOperatorKind_UO_Extension

"Map a clang builtin type spelling to the Julia type to annotate a literal with."
const CTYPE_TO_JL = Dict(
    "int" => :Cint, "unsigned int" => :Cuint, "long" => :Clong, "unsigned long" => :Culong,
    "long long" => :Clonglong, "unsigned long long" => :Culonglong,
    "short" => :Cshort, "unsigned short" => :Cushort,
    "char" => :Cchar, "signed char" => :Int8, "unsigned char" => :Cuchar,
    "float" => :Float32, "double" => :Float64, "_Bool" => :Bool)

jl_type_for(spelling::AbstractString) = get(CTYPE_TO_JL, spelling, Symbol(spelling))

"Read an `llvm::APInt`-backed value that crosses as an LLVMGenericValueRef."
function generic_int(gv)
    v = CC.LLVM.GenericValue(gv)
    try
        return convert(Int, v)
    finally
        CC.LLVM.dispose(v)
    end
end

"""
Re-read a value at the signedness clang gave its type.

`GenericValue` hands back a signed reading of the APInt, so `0x8c000000` — an `unsigned int`
whose value is 2348810240 — arrives as -1946157056. Emitting `Cuint(-1946157056)` would throw.

This applies to **both** ends of the verification, which is the part that was easy to miss:
`glib`'s `G_MAXUINT` translated correctly to 4294967295, but the fold it was checked against
came back as -1, so the verifier rejected eight correct macros. A skipped-but-correct macro is
the safe failure direction, which is exactly why it stayed invisible until the skip reasons
were counted.
"""
function at_signedness(raw::Integer, qt, ctx)
    if CC.isUnsignedIntegerType(CC.getTypePtr(qt)) && raw < 0
        return raw + (big(1) << Int(CC.getTypeSize(ctx, qt)))
    end
    return raw
end

literal_int(r, ctx) = at_signedness(generic_int(CC.getValue(r)), CC.getType(r), ctx)

"""
    translate_expr(e, ctx) -> Julia expression

Walk clang's typed AST. Every node is asked for its own type, so nothing here re-derives a C
rule: literal typing, precedence and cast targets all arrive already decided.
"""
function translate_expr(@nospecialize(e), ctx)
    r = CC.resolve(e)

    if r isa CC.AbstractParenExpr
        return translate_expr(CC.getSubExpr(r), ctx)

    elseif r isa CC.AbstractIntegerLiteral
        v = literal_int(r, ctx)
        ty = CC.getAsString(CC.getType(r))
        # A plain `int` needs no annotation: Julia's default integer is wide enough and the
        # unannotated form is what a reader wants to see.
        return ty == "int" ? v : Expr(:call, jl_type_for(ty), v)

    elseif r isa CC.AbstractFloatingLiteral
        d = CC.getValueAsApproximateDouble(r)
        ty = CC.getAsString(CC.getType(r))
        return ty == "float" ? Expr(:call, :Float32, d) : d

    elseif r isa CC.AbstractStringLiteral
        # getString ABORTS on a wide/UTF-16/UTF-32 literal (clang asserts getCharByteWidth()==1).
        CC.getCharByteWidth(r) == 1 || throw(Untranslatable("wide string literal"))
        return CC.getString(r)

    elseif r isa CC.AbstractCharacterLiteral
        # Unlike `IntegerLiteral::getValue`, this returns the code point directly rather than an
        # APInt behind an LLVMGenericValueRef — passing it through `generic_int` threw on the
        # first header that used a character macro.
        v = Int(CC.getValue(r))
        # A plain C character literal has type `int`; `Cchar` says what it MEANT, and is what
        # the existing generator emits. A wide literal will not fit, so keep it numeric.
        return 0 <= v <= 127 ? Expr(:call, :Cchar, v) : v

    elseif r isa CC.AbstractUnaryOperator
        op = CC.getOpcode(r); sub = translate_expr(CC.getSubExpr(r), ctx)
        op == UO_MINUS && return Expr(:call, :-, sub)
        (op == UO_PLUS || op == UO_EXTENSION) && return sub
        op == UO_NOT && return Expr(:call, :~, sub)
        op == UO_LNOT && return Expr(:call, :!, sub)
        throw(Untranslatable("unary operator $op"))

    elseif r isa CC.AbstractBinaryOperator
        opstr = CC.getOpcodeStr(r)
        lhs = translate_expr(CC.getLHS(r), ctx); rhs = translate_expr(CC.getRHS(r), ctx)
        if opstr == "/"
            # C integer division truncates; Julia's `/` promotes to Float64. Pick by the
            # node's own type rather than guessing from the operands.
            return CC.isIntegerType(CC.getTypePtr(CC.getType(r))) ?
                   Expr(:call, :div, lhs, rhs) : Expr(:call, :/, lhs, rhs)
        elseif opstr == "^"
            return Expr(:call, :⊻, lhs, rhs)      # C `^` is xor
        end
        jlop = get(BINOPS, opstr, nothing)
        jlop === nothing && throw(Untranslatable("binary operator `$opstr`"))
        # && and || are short-circuit forms in Julia, not calls
        (jlop === :&& || jlop === :||) && return Expr(jlop, lhs, rhs)
        return Expr(:call, jlop, lhs, rhs)

    elseif r isa CC.AbstractConditionalOperator
        return Expr(:if, translate_expr(CC.getCond(r), ctx),
                    translate_expr(CC.getTrueExpr(r), ctx),
                    translate_expr(CC.getFalseExpr(r), ctx))

    elseif r isa CC.AbstractCStyleCastExpr
        sub = translate_expr(CC.getSubExpr(r), ctx)
        qt = CC.getType(r); tp = CC.getTypePtr(qt)
        spelling = CC.getAsString(qt)
        if CC.isPointerType(tp)
            # A cast to pointer is either a string decaying to `char *` or a numeric address.
            # libxml2 writes `#define XML_XML_NAMESPACE (const xmlChar *) "http://…"`; wrapping
            # that gave `Ptr{Cvoid}("http://…")`, a MethodError at load. The string itself is
            # the right Julia value — `ccall` decays it exactly as C does.
            sub isa AbstractString && return sub
            sub isa Integer && return :(Ptr{Cvoid}($sub))
            throw(Untranslatable("cast to pointer of a non-constant"))
        elseif CC.isIntegerType(tp)
            # A C cast TRUNCATES. `T(x)` is a checked conversion that throws, which is
            # Clang.jl issue #382; `%` is the operation C actually performs.
            return Expr(:call, :%, sub, jl_type_for(spelling))
        else
            return Expr(:call, jl_type_for(spelling), sub)
        end

    elseif r isa CC.AbstractImplicitCastExpr
        # Implicit conversions clang inserted while type-checking. The Julia expression is
        # built from the operands' own types, so these are transparent -- except a decay to
        # pointer, which is how a string literal reaches a `char *`.
        return translate_expr(CC.getSubExpr(r), ctx)

    elseif r isa CC.AbstractDeclRefExpr
        d = CC.resolve(CC.getDecl(r))
        CC.is_null_handle(CC.getIdentifier(d)) && throw(Untranslatable("unnamed declaration"))
        return Symbol(CC.getName(d))

    elseif r isa CC.AbstractUnaryExprOrTypeTraitExpr
        # sizeof / alignof: fold it, since the Julia side has no equivalent spelling
        av = CC.EvaluateAsInt(r, ctx)
        CC.is_null_handle(av) && throw(Untranslatable("unevaluatable sizeof/alignof"))
        return generic_int(CC.getInt(av))
    end

    throw(Untranslatable(string(nameof(typeof(r)))))
end

# ------------------------------------------------------------------------------------------
# 3. Verification
# ------------------------------------------------------------------------------------------
"""
Map each typedef name in the translation unit to the Julia type its canonical builtin
corresponds to, so an emitted expression naming a typedef can be evaluated for checking.
"""
function typedef_bindings(ctx)
    binds = Dict{Symbol,Any}()
    for d in CC.decls_in(CC.castToDeclContext(CC.getTranslationUnitDecl(ctx)))
        d isa CC.AbstractTypedefNameDecl || continue
        CC.is_null_handle(CC.getIdentifier(d)) && continue
        canon = CC.getCanonicalType(ctx, CC.getUnderlyingType(d))
        jl = get(CTYPE_TO_JL, CC.getAsString(canon), nothing)
        jl === nothing && continue
        binds[Symbol(CC.getName(d))] = jl
    end
    return binds
end

"Every symbol in `ex` that would be looked up as a binding."
function referenced_symbols!(out::Set{Symbol}, @nospecialize(ex))
    if ex isa Symbol
        push!(out, ex)
    elseif ex isa Expr
        for a in ex.args
            (a isa QuoteNode || a isa LineNumberNode) && continue
            referenced_symbols!(out, a)
        end
    end
    return out
end

"""
Check a translated expression by evaluating it, and against clang's fold when there is one.

Returns `:ok`, `:unchecked` (the expression names something only the generated module will
define, so it cannot be evaluated here), or a `Pair` describing the disagreement.

Two distinctions matter, and both were learned by getting them wrong:

  * An expression which **throws** is a FAILURE, not an unchecked case. `MPI_Datatype(0x8c000000)`
    raising `InexactError` is precisely the defect this exists to catch — treating a throw as
    "could not check" is how a verifier becomes vacuous.
  * The evaluation runs **whether or not clang folded the macro**. Gating it on a fold meant
    every non-integer macro went out unverified, and libxml2's `XML_XML_NAMESPACE` — a string
    cast to `const xmlChar *` — was emitted as `Ptr{Cvoid}("http://…")`, which fails at load.
    A fold is extra evidence when available, not the precondition for looking.
"""
function check_translation(@nospecialize(ex), folded::Union{Nothing,Integer},
                           binds::Dict{Symbol,Any})
    syms = referenced_symbols!(Set{Symbol}(), ex)
    for s in syms
        haskey(binds, s) && continue
        (isdefined(Base, s) || isdefined(Core, s)) && continue
        return :unchecked          # a name only the generated module will have
    end
    m = Module(:CxxMacroCheck)
    for (k, v) in binds
        Core.eval(m, Expr(:const, Expr(:(=), k, v)))
    end
    v = try
        Core.eval(m, ex)
    catch err
        return :threw => first(split(sprint(showerror, err), "\n"))
    end
    folded === nothing && return :ok
    v isa Number || return :ok     # strings and pointers do not compare against an integer fold
    return v == folded ? :ok : (:mismatch => "got $v, clang folded to $folded")
end

# ------------------------------------------------------------------------------------------
# 4. The pipeline
# ------------------------------------------------------------------------------------------
const PROBE_PREFIX = "__cjl_macro_probe_"

"""
    translate_macros(headers, args=String[]; include_system=false, is_cxx=false)

Translate the object-like macros defined by `headers`, returning a vector of
`MacroTranslated` and `MacroSkipped`.

Runs the clang frontend twice: once to learn which macros exist, and once over the headers
plus one probe per macro. The second run must include the headers, because the probes are only
parseable in a translation unit where the headers' typedefs are visible.
"""
function translate_macros(headers::Vector{String}, args::Vector{String}=String[];
                          include_system::Bool=false, is_cxx::Bool=false)
    flags = is_cxx ? copy(args) : String["-x", "c", args...]
    umbrella = join(("#include \"$h\"" for h in headers), '\n') * "\n"

    # --- pass 1: which macros are there? ---
    names = Symbol[]
    I1 = CC.create_interpreter(flags; is_cxx)
    try
        pp = CC.getPreprocessor(CC.get_instance(I1))
        CC.createPreprocessingRecord(pp)
        CC.parse(I1, umbrella)
        sm = CC.getSourceManager(CC.get_instance(I1))
        for (nm, mi) in discover_macros(pp, sm; include_system)
            CC.isFunctionLike(mi) && continue      # see MACRO-HANDLING.md §6
            push!(names, nm)
        end
    finally
        CC.dispose(I1)
    end
    isempty(names) && return Union{MacroTranslated,MacroSkipped}[]

    # --- pass 2: headers AND probes, one parse ---
    probes = join(("__auto_type $PROBE_PREFIX$i = ($(names[i]));" for i in eachindex(names)), '\n')
    results = Union{MacroTranslated,MacroSkipped}[]
    I2 = CC.create_interpreter(flags; is_cxx)
    try
        ctx = CC.get_ast_context(I2)
        CC.parse(I2, umbrella * probes * "\n")
        CC.setTraversalScope(ctx, [CC.getTranslationUnitDecl(ctx)])
        typedefs = typedef_bindings(ctx)

        probevars = Dict{Int,Any}()
        for d in CC.decls_in(CC.castToDeclContext(CC.getTranslationUnitDecl(ctx)))
            d isa CC.AbstractVarDecl || continue
            CC.is_null_handle(CC.getIdentifier(d)) && continue
            n = CC.getName(d)
            startswith(n, PROBE_PREFIX) || continue
            probevars[parse(Int, n[(length(PROBE_PREFIX) + 1):end])] = d
        end

        for (i, nm) in enumerate(names)
            d = get(probevars, i, nothing)
            # clang refusing the probe IS the answer: the macro is not a C expression. That is
            # what makes `#define VERSION 0.0.1` and `#define X { 0, 0 }` skip correctly with
            # no heuristic of ours.
            if d === nothing || CC.isInvalidDecl(d) || !CC.hasInit(d)
                push!(results, MacroSkipped(nm, "not a C expression clang accepts"))
                continue
            end
            ctype = CC.getAsString(CC.getType(d))
            folded = nothing
            # NOTE: evaluateValue segfaults on a decl with no initializer -- guarded above.
            av = CC.evaluateValue(d)
            if !CC.is_null_handle(av) && CC.isInt(av)
                folded = at_signedness(generic_int(CC.getInt(av)), CC.getType(d), ctx)
            end
            ex = try
                translate_expr(CC.getInit(d), ctx)
            catch err
                err isa Untranslatable || rethrow()
                push!(results, MacroSkipped(nm, "unsupported construct: $(err.what)"))
                continue
            end
            # `#define foo foo` beside `int foo(void);` resolves to the function, but emitting
            # `const foo = foo` is circular in Julia.
            if ex isa Symbol && ex === nm
                push!(results, MacroSkipped(nm, "self-referential"))
                continue
            end
            # The check the token-based translator could not make: does our Julia mean what
            # clang says the macro means, and does it even evaluate? A failure is never emitted.
            verdict = check_translation(ex, folded, typedefs)
            if verdict isa Pair
                push!(results, MacroSkipped(nm, "translation rejected ($(verdict[1])): $(verdict[2])"))
                continue
            end
            push!(results, MacroTranslated(nm, ex, ctype, folded))
        end
    finally
        CC.dispose(I2)
    end
    return results
end

end # module
