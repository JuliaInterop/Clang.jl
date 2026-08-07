# Macro handling: what is broken, and the design that fixes it

**Status**: redesigned around clang's AST after the token-level design proved to be the wrong
shape. Both approaches were prototyped and measured; §4 is the recommendation. Nothing in `src/`
has changed.
**Companions**: [CLAUDE.md](CLAUDE.md) (the pipeline today), [GENERATORS-REWORK.md](GENERATORS-REWORK.md) (§5.6 sketched this; this document supersedes that sketch).

---

## 1. Where it stands

Macro translation is the largest single source of reported defects in the generator: of 41
macro-tagged issues triaged, **25 are genuinely about translating `#define`**, and **6 are still
open**. The failure mode is worse than "produces odd output" — it produces output that **does not
load**.

Reproduced on current master, in this worktree:

```julia
# typedef int INT;              #define FIVE ((INT) 4+1)
const FIVE = (INT(4))(1)                        # MethodError: Int32 not callable
# typedef int MPI_Datatype;     #define MPI_FLOAT_INT ((MPI_Datatype)0x8c000000)
const MPI_FLOAT_INT = MPI_Datatype(0x8c000000)  # InexactError: convert(Int32, ...)
```

Both throw **at load time**, so one such macro in a header makes the whole generated module
unusable. That is why both reporters' workaround was `output_ignorelist`.

And the same is true of the project's own fixture. Running the current generator over
`test/include/macro.h` emits:

```julia
const GINTBIG_MAX = CPL_STATIC_CAST(GIntBig, 0x7fffffff) << 32 | Cuint(0xffffffff)
```

`CPL_STATIC_CAST` and `GIntBig` are defined nowhere, so loading it raises
`UndefVarError: CPL_STATIC_CAST`. **The macro testset has never noticed, because it asserts only
that `build!` reached `"Done!"`** ([test/generators.jl:165-168](test/generators.jl:165)). Every
conclusion in this document follows from that gap: the current bar cannot see the actual failure.

---

## 2. Triage

41 issues matched a search for "macro"; 16 mention macros only incidentally (they are about
types, ObjC, callbacks, or the `@cenum` macro) and are excluded. Of the remaining 25:

| Root cause | Fixed by (§4 design) | Issues |
| --- | --- | --- |
| cast detection | clang parses it — `CStyleCastExpr` node | **#510**, **#382**, **#309** |
| integer-literal typing | clang deduces it — `getType` on the node | #515, (#202) |
| system/builtin macro not collected | macro expansion happens in the probe | #446, #234, **#288** |
| cross-header duplicate | umbrella single-TU parse | **#467** |
| doc comment on `#define` | `RawCommentList::getCommentsInFile` | **#371** |
| function-like macro as a constant | expansion at the use site | #255, #81 |
| "not a C expression" | clang rejects it | #374 |
| `_Generic` dispatch | clang resolves it | #228 |
| already fixed (the regression bar) | — | 12 issues |

Bold = still open. Twelve closed issues form the regression bar and are mostly represented in
`test/include/macro.h`.

Note what is *not* in the right-hand column: no heuristic, no re-implemented C rule, and no
category we have to define ourselves. Every row is a question handed back to the compiler. §4b
reports the measured result for each.

*Caveat:* one triage batch (#364, #357, #356, #354, #353, #328, #320, #281 — all closed) died on
a connection error and was not re-run. Four of those (`__cdecl`, `UCS_EMPTY_STATEMENT`, the
line-continued string, the wide string `SL`) are already fixtures in `test/include/macro.h` and
are covered by the prototype run in §5; the rest are unreviewed.

---

## 3. The four root causes

### 3.1 Casts have no representation (#510, #382, #309)

The current code has no notion of a cast. `tweak_exprs` wraps the type identifier in parens
([macro.jl:210](src/generator/macro.jl:210)) and `add_spaces_for_macros`
([macro.jl:262-268](src/generator/macro.jl:262)) then concatenates it onto the parenthesised
literal from `normalize_literal` — and Julia reads juxtaposition as a **call**.

On top of that, the cast heuristic locates its sign token with `findnext(... ∈ C_UNARY_OPS ...)`
scanning **anywhere later in the stream** ([macro.jl:194-209](src/generator/macro.jl:194)). For
`((INT) 4+1)` it therefore latches onto the *binary* `+` of `4+1`, blanks it, and glues it onto
the next literal, so the body becomes `((INT) ) (4) (+1)` — hence `(INT(4))(1)`.

The damage is wider than the two headline issues. From #382 and #309, all verified as reported:

```julia
const MPI_ARGV_NULL = (Cchar * (*))(0)          # does not even parse
const SIG_DFL = ((Cvoid(*))(Cint))(0)           # does not parse
const MPI_T_ENUM_NULL = MPI_T_enum(NULL)        # NULL is undefined in Julia
const FLUX_MSGHANDLER_TABLE_END = {0, NULL, NULL, 0}   # does not parse
```

### 3.2 Literal typing is guessed from the suffix (#515, #202)

`normalize_literal_type` walks an **ordered longest-first suffix list**
([macro.jl:52-114](src/generator/macro.jl:52)) and applies the suffix as the type. That is not
C's rule. Per C11 6.4.4.1p5 the type is **the first in the suffix's candidate list that can
represent the value**, and the list differs for decimal vs hex/octal:

| suffix | decimal | hex / octal |
| --- | --- | --- |
| *(none)* | `int, long, long long` | `int, unsigned, long, unsigned long, long long, unsigned long long` |
| `U` | `unsigned, unsigned long, unsigned long long` | same |
| `L` | `long, long long` | `long, unsigned long, long long, unsigned long long` |
| `UL` | `unsigned long, unsigned long long` | same |
| `LL` | `long long` | `long long, unsigned long long` |

So `0x80000001L` is **`long` on LP64** and **`unsigned long` on a 32-bit-`long` target**. The
existing test encodes that split by *predicting* the platform
(`Sys.iswindows() || Int === Int32`, [test/generators.jl:328](test/generators.jl:328)) rather than
asking the compiler.

### 3.3 The wrong translation unit (#467, #446, #288, #234)

Each header is parsed into its own TU, so a `#define` executed while parsing `a.h` is invisible
when `b.h` is parsed. In #467 that makes a header guard fail to suppress a second definition, and
both an enum constant and a macro named `DECADE` reach the DAG — the reporter's own workaround
was an umbrella header that includes both.

Separately, macros from system headers and from clang's `<built-in>` / `<command line>` buffers
are never collected, so `INT8_MAX` (#446) and `UINT_MAX` (#288) are referenced but undefined.
#234 is the same territory from the other side: a macro with no backing source file crashed the
tokenizer outright.

### 3.4 Everything is text (#59, #196, #206, #356, #357)

Literal suffixes, octal detection, string merging via a `Meta.parse` round-trip, and
`normalize_punctuation` rewriting `/` → `÷` and `^` → `xor` unconditionally
([macro.jl:137](src/generator/macro.jl:137)) — all operate on token *spellings*. The string-literal
cluster is closed, but the machinery that produced it is unchanged.

---

## 4. The redesign: translate clang's AST, not the macro's text

Both the current code and the token-level design that preceded this section are the same shape —
**transliteration**. They take C tokens, rewrite them into Julia tokens, and hope the result
parses to something equivalent. Better tokens make that less wrong, but the shape is what
produces the whole defect class: every rule about precedence, casts, literal typing and
expansion has to be *re-implemented*, and each re-implementation is a chance to be silently
wrong.

The redesign stops transliterating. **Let clang parse the macro body as a C expression, then
translate the typed AST it produces.**

### 4.1 Mechanism

For every object-like macro, emit one C declaration into the *same* translation unit as the
headers:

```c
__auto_type __cjl_probe_17 = (MACRO_NAME);
```

`__auto_type` deduces the type, so a single probe form works for integers, floats, strings,
pointers, casts and function pointers alike. From the resulting `VarDecl` we get, in one shot:

| what | from | replaces |
| --- | --- | --- |
| the macro is valid C at all | `isInvalidDecl(d)` | `is_macro_unsupported` heuristics |
| its **type** | `getType(d)` — typedefs preserved | the C11 6.4.4.1p5 table, hand-written |
| its **AST** | `getInit(d)` — every node typed | token re-lexing |
| its **value** | `evaluateValue(d)` → `APValue` | nothing; there was no check |

Three things become clang's job instead of ours:

1. **Parsing** — precedence, associativity, casts, ternaries, `sizeof`, `_Generic`, and nested
   macro expansion (including system and builtin macros).
2. **Typing** — every AST node carries a `QualType`. A literal's type is *read*, not derived.
3. **Verification** — where the macro folds to a constant, the emitted Julia can be evaluated
   and compared against clang's own value.

Point 3 is the one that changes the character of the output: **a macro is emitted only if clang
accepted it and our translation agrees with clang's value.** Silently-wrong output stops being
a bug class and becomes structurally impossible.

### 4.2 What the AST looks like

`#define FIVE ((INT) 4+1)` — the case that currently emits `(INT(4))(1)`:

```
ParenExpr            : int
  BinaryOperator     : int
    CStyleCastExpr   : INT          <- the cast is a NODE, and it is typed
      IntegerLiteral : int
    IntegerLiteral   : int
```

There is nothing to detect. The cast is a `CStyleCastExpr`; its type is `INT`; the operand is its
child. Translation is a recursive walk over ~15 node classes (`IntegerLiteral`,
`FloatingLiteral`, `StringLiteral`, `CharacterLiteral`, `UnaryOperator`, `BinaryOperator`,
`ParenExpr`, `CStyleCastExpr`, `ImplicitCastExpr`, `DeclRefExpr`, `ConditionalOperator`,
`UnaryExprOrTypeTraitExpr`), each of which asks its own node for its type.

### 4.3 Pipeline

1. **Discover** — parse the umbrella; `getMacros(pp)` → filter out builtin
   (`isBuiltinMacro`), header guards (`isUsedForHeaderGuard`), and the predefines/command-line
   buffers (`isWrittenInBuiltinFile` / `isWrittenInCommandLineFile` — `isInSystemHeader` alone is
   not enough); split object-like from function-like.
2. **Probe** — one second frontend run over `umbrella + one probe per object-like macro`.
   It must be one parse: a typedef declared in an earlier increment is invisible to the parser
   later, so `(INT)x` would not parse in a follow-up (verified).
3. **Harvest** — per probe: reject if `isInvalidDecl`; else take type, AST, folded value.
4. **Translate** — AST → Julia `Expr`.
5. **Verify** — for constant-folding macros, evaluate the Julia and compare. On mismatch, do not
   emit; report it.

### 4.4 The old token design, retained where it still applies

The typed-token work is not wasted — it is what step 1 is built from, and it remains the route
for anything that never becomes an AST (function-like macro bodies, and the `# Skipping` comment
text). The token-level notes below are kept for that reason.

**a. Casts become a rule, not a heuristic.** A cast is `l_paren <type> r_paren <operand>`, where
"is this a type" is *answered*: C type keywords are distinct token kinds, and a typedef name is
looked up in the typedef set the generator already collects. Nothing is guessed.

**b. A cast emits `%`, never a constructor.** C casts truncate; Julia constructors throw. `(T)x`
→ `x % T` fixes #382 by construction and matches C's semantics exactly.

**c. Integer literals use C's real rule**, with `int`/`long`/`long long` widths read from clang's
`TargetInfo` (`getIntWidth`, `getLongWidth`, `getLongLongWidth`) rather than predicted from
`Sys.iswindows()`. Because the type is chosen so the value fits, the emitted conversion **cannot
throw** — which is the whole point.

**d. Suffix splitting must parse forwards.** Scanning backwards for `uUlLfF` is wrong: `f`, `e`,
`a`–`c` are hex *digits*. Establish the base, consume digits, and the remainder is the suffix.

**e. Header guards use `isUsedForHeaderGuard`**, which clang tracks natively — replacing the
hard-coded `_H` suffix plus the user-supplied `ignore_header_guards_with_suffixes` list. Verified:
it correctly flags a guard named `HDR_NOT_SUFFIXED`, which today leaks out as a spurious `const`.

**f. Filter three origins, not one.** `isInSystemHeader` alone is not enough — clang's predefines
and `-D` flags live in synthetic buffers. `isWrittenInBuiltinFile` and
`isWrittenInCommandLineFile` are needed too. (I hit this: `__GCC_HAVE_DWARF2_CFI_ASM` leaked into
the prototype's first run. It is also the likely shape of #234.)

**g. Self-referential macros are skipped.** `#define foo foo` beside `int foo(void);` (#389)
currently emits circular `const foo = foo`.

**h. Doc comments (#371) need a source, not new plumbing.** `pretty_print` already calls
`print_documentation` for macro nodes ([print.jl:291-293](src/generator/print.jl:291)); libclang
simply returns empty for a `MacroDefinition`. `RawCommentList::getCommentsInFile` is wrapped in
ClangCompiler, so the fix is to match a comment whose range ends just above the macro's
definition line. *(Not yet verified end-to-end — see §7.)*

**i. Constant evaluation, as a second pass.** For #288, #255, #81, #309 the value cannot be
recovered symbolically — `UINT_MAX` expands through `__INT_MAX__`, a compiler builtin present in
no header. The fix is to let clang fold it. **Constraint found by probe: this cannot be a
separate parse** — typedef names from an earlier increment are invisible to the parser later, so
`(INT)x` fails to parse in a follow-up increment. Probes must be emitted into the *same* parse as
the headers, i.e. a second frontend run over `umbrella + all probes`.

---

## 4b. What the AST design was measured to do

Every row below is a live result, not a prediction. One parse, `-x c -std=c11`, probes and
headers together.

| macro | clang's deduced type | folded value | issue |
| --- | --- | --- | --- |
| `((INT) 4+1)` | `int` | **5** | **#510** |
| `((MPI_Datatype)0x8c000000)` | **`MPI_Datatype`** *(typedef kept)* | **-1946157056** | **#382** |
| `0x80000001L` | **`long`** *(target-correct, no table)* | 2147483649 | #515 |
| `(UINT_MAX - 1)` | `unsigned int` | folded | **#288** |
| `(INT8_MAX)` | `int` | **127** | #446 |
| `sizeof(int)` | `unsigned long` | 4 | — |
| `SODIUM_MIN(1U, 3U)` | `unsigned int` | **1** | #255 |
| `((void (*)(int))0)` | **`void (*)(int)`** | — | **#309** |
| `(char **)0` | **`char **`** | — | **#382** |
| `_Generic(1, int: 1, default: 0)` | `int` | **1** | #228 |
| `"abc" "def"` | `char *` | — | #356/#59 |
| `{ 0, 0 }` | **rejected by clang** | — | #382 |
| `0.0.1` | **rejected by clang** | — | **#374** |
| `CPL_STATIC_CAST(GIntBig, 1)` | **rejected by clang** | — | `macro.h` |

Two of those deserve calling out because they were open questions rather than known bugs:

- **#374 ("what is a pure definition macro?") dissolves.** `0.0.1` is not a C expression, so
  clang refuses it. The category does not need defining; it needs asking.
- **#255 needs no function-like macro support.** `SODIUM_MIN` expands at its *use site* inside
  `OPSLIMIT_MIN`, so the object-like macro folds to `1` without anyone translating `SODIUM_MIN`
  itself.

## 5. What the earlier token prototype proves

A working prototype (~200 lines) implements a–g. Values checked against a C compiler:

| macro | current | prototype | C |
| --- | --- | --- | --- |
| `FIVE` | `(INT(4))(1)` — **load error** | `Cint(4) % INT + Cint(1)` → `5` | `5` |
| `MPI_FLOAT_INT` | `MPI_Datatype(0x8c000000)` — **load error** | `Cuint(0x8c000000) % MPI_Datatype` → `-1946157056` | `-1946157056` |

Against `test/include/large-integer-literals.h`, the prototype reproduces **all four exact-`Expr`
assertions** in the existing testset — with the widths read from clang rather than predicted:

```
TEST           Clong(0x80000001)      TEST_SIGNED     Clong(0x00000001)
TEST_2         Clong(2147483649)      TEST_SIGNED_2   Clong(2147483646)
```

Against `test/include/macro.h`, it also correctly *declines* the two macros the current generator
emits unloadably (`GINTBIG_MAX`, `GUINTBIG_MAX` — they call the undefined `CPL_STATIC_CAST`), and
skips `#define foo foo` and `UCS_EMPTY_STATEMENT { }`.

**The corpus caught two bugs in the prototype**, which is the argument for §7's test bar:

1. `0x7FFFFFFF` → `0x7`, from backwards suffix scanning (→ design point d).
2. A case where the **current code was right and the prototype wrong**: naive `%`-on-suffix broke
   `0x80000001L` on 32-bit-`long` targets (→ design point c). Casts truncate; literals promote.
   Conflating the two rules is the trap.

---

## 6. What stays hard, and what it costs

Genuinely unresolved:

- **Function-like macros themselves.** Their *uses* inside object-like macros are handled (#255),
  but translating `#define MIN(A,B) ((A)<(B)?(A):(B))` into a Julia function still needs argument
  types nobody has. A probe could supply them only by guessing. This stays behind
  `functionlike_macro_includelist`.
- **`NULL` → `C_NULL`** is a name-mapping decision, not a parse. The AST gives
  `ImplicitCastExpr` over an integer `0` at pointer type, which is enough to *detect* it.
- **Symbolic vs folded output.** Users prefer `1 << 3` to `8`. The AST gives the symbolic form
  and the fold gives the check, so both are available — but which to emit is a policy choice
  that needs an option.

Costs and risks of the AST approach, honestly:

- **One extra frontend run.** Discovery must precede probing, and probes must share the headers'
  parse.
- **`__auto_type` is a GNU extension.** clang supports it in C mode; C23 spells it `auto`. Fine
  for clang-only, which this path is.
- **Probe-name collisions.** A sufficiently unlikely prefix, plus a check that the name is not
  already bound.
- **Diagnostics are unreliable on this route** — see §9. The run above reported "parse failed"
  and `getNumErrors == 0` while still producing all 15 probe decls correctly.
- **`evaluateValue` segfaults on an invalid decl** — see §9.

---

## 7. The test bar has to change

**This is the most important recommendation in this document.** The current macro testset asserts
`build!` reached `"Done!"`, which is why `test/include/macro.h` has been generating unloadable
output without anyone noticing. Replace it with two assertions:

1. **The generated file loads.** `include` it into a fresh `Module`. This alone would have caught
   #510, #382, #446, #288, #467 and the `CPL_STATIC_CAST` case.
2. **Each constant equals what C says.** Compile a tiny C program that prints each macro, or —
   better, since clang is in-process on the C++ path — fold the macro with clang and compare. This
   catches the whole silent-wrong-value class, which loading alone does not.

Together these subsume every issue in §2 except the documentation and function-like clusters.

---

## 8. Sequencing

**M1 — the bar, on the current libclang path.** Add the load-and-compare harness. Expect red on
`macro.h` immediately; that red is the point. Then stop emitting macros that reference undefined
names — a small change that fixes the `CPL_STATIC_CAST` case with no new dependency. Do this
regardless of everything below.

**M2 — the AST translator**, behind the C++ frontend (`GENERATORS-REWORK.md` Phase 2):
discover → probe → harvest → translate → verify (§4.3). This single milestone delivers **#510,
#382, #515, #446, #288, #255, #309, #374** and, with the umbrella, **#467**.

**M3 — doc comments (#371)** via `RawCommentList::getCommentsInFile`, matching a comment whose
range ends just above the macro's definition line. Independent of M2.

**M4 — function-like macros.** The residue. Needs a design, not a mechanism.

Note the shape change from the previous plan: the separate "literal typing" milestone is **gone**,
because implementing C11 6.4.4.1p5 by hand stops being necessary the moment clang deduces the
type. That is the clearest single argument for the redesign — the most intricate piece of the
token approach simply ceases to exist.

---

## 9. ClangCompiler filings this uncovered

Two are new, and both are robustness issues rather than missing features:

**Filing 7 — `VarDecl::evaluateValue` segfaults on an invalid declaration.** Its own comment
promises an `APValue` wrapping `C_NULL` "when the initializer is absent or not constant-foldable"
([`src/clang/api/AST/Decl.jl:515-518`]), but on a decl whose initializer failed to typecheck it
crashes inside `EvaluateInPlace`/`EvaluateAsInitializer` (SIGSEGV, reproduced). Per the repo's own
Invariant-3 rule, the wrapper needs the precondition restated: `@assert !isInvalidDecl(x) &&
hasInit(x)`. This is exactly the "partial clang method" case
`deps/ClangExtra/CLAUDE.md` warns about.

**Filing 8 — the parse-success signal is unreliable.** The probe run reported a NULL
`PartialTranslationUnit` *and* `getNumErrors == 0`, while stderr carried a real error and all 15
probe decls were nonetheless created correctly. A caller cannot currently distinguish "the parse
failed" from "the parse emitted a diagnostic and carried on". This is the same underlying gap as
Filing 3 (`TextDiagnosticBuffer`) and raises its priority: the AST macro design depends on
per-probe success being detectable, which it gets from `isInvalidDecl` per decl — but the
*translation-unit* level signal should not be trusted.

Also observed, and worth a look before this ships: with `-x c` against the JLL sysroot,
`<stdint.h>` produced `error: unknown type name '__builtin_va_list'`. It did not prevent the
probes from working, but it suggests the C-mode flag set needs review.
