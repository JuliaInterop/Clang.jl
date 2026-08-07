# Settled design: emission ordering

**Status**: for review. No code changes yet.

> **Scoped by [GENERATORS-REWORK.md](GENERATORS-REWORK.md) §0**: libclang is being dropped, so
> Clang.jl will have a single ClangCompiler-backed frontend. What survives from this document is
> the part that is frontend-independent — the ordering walk (§3.2), the two-tier cycle policy
> (§3.2a), the atomicity requirement (§2.0) and the verifier (§3.4) — because Julia's lack of
> forward declarations does not care where the facts came from, and `decl_id` *is* the stable key
> §3.2b asks for. What does **not** survive, and should not be built: the 15→11 pass reduction,
> §3.3's splicing fix, and the `IndexDefinition` split. Passes 2-8 are libclang compensation and
> are deleted outright by the AST walk.
**Supersedes**: [GENERATORS-REWORK.md](GENERATORS-REWORK.md) §3.6, which contains an error
corrected in §1 below.

The `ExprDAG` exists for one reason — Julia has no forward declarations, so a generated
single-file wrapper needs a strict definition order. This document settles what that actually
requires, what the current pipeline does instead, and what to change.

---

## 1. Correction: types *can* depend on functions

§3.6 asserted "no type ever depends on a function" and used it to justify moving all functions
to a trailing section. **That is false.** Measured:

| construct | result |
| --- | --- |
| `const ALIAS = c_func` … `c_func() = 1` | **FAILS** — `#define ALIAS c_func` |
| `const V = ENC(1,2)` … `ENC(a,b) = …` | **FAILS** — `#define V ENC(1,2)` over a function-like macro |
| `abstract type P2 <: P1 end` … `abstract type P1 end` | **FAILS** — `@objcwrapper P2 <: P1` expands to this |
| `const __U_S = Union{Cint,Ptr{Node}}` … `struct Node` | **FAILS** — `emit_constructor!` on a union |

The correct statement is narrower:

> No **struct, enum or typedef** depends on a function. A **`const`** can — and macros compile
> to `const`s, so the macro band must come *after* functions, not before.

Today's printers already emit macros last (`passes.jl:1004-1014`, `1043-1054`, `1081-1091`).
That ordering is correct and must be preserved. The two-section split proposed in §3.6 would
have regressed it.

**Corrected band order: types & consts → functions & methods → macros.**

---

## 2. What ordering actually requires

Julia requires definition order for **definition-time type positions only**: struct field types,
method signature annotations, `ccall` type arguments, `const` right-hand sides, and
`abstract type X <: Y`. Ordinary body expressions are lazy (`g() = Foo`, `g() = Foo(1)`,
`g() = sizeof(Foo)`, `g() = h()` all load with the referent defined later).

### 2.0 clang-c is NOT representative — libxml2 fails outright today

**The evidence in §2.1 below is real but unrepresentative, and it must not be read as "the sort
is unnecessary".** clang-c is written in opaque-handle style and barely uses forward
declarations. Headers that do use them tell a completely different story.

Running the current generator on **libxml2** (a mainstream C library, 2417 nodes):

```
ERROR: Could not remove circular reference after 100000 trials.
10 suggested culprits: xmlSchemaType, xmlSchemaTypePtr, _xmlSchemaFacet, xmlSchemaFacet,
   xmlSchemaFacetPtr, _xmlSchemaAnnot, _xmlSchemaAttribute, ...  (schemasInternals.h)
```

It does not generate at all. And once the cycle-breaker is made to get past that point, the
backward-edge count is nothing like clang-c's:

| corpus | backward edges from type/const nodes |
| --- | --- |
| clang-c | **2** |
| libxml2 | **205** |

So the topological sort is genuinely required. Any claim resting on clang-c alone is a claim
about opaque-handle APIs, not about C headers.

#### Root cause of the libxml2 failure

libxml2 is built on the ubiquitous idiom:

```c
typedef struct _xmlSchemaType xmlSchemaType;   /* TypedefElaborated */
typedef xmlSchemaType *xmlSchemaTypePtr;       /* TypedefDefault -- points at a TYPEDEF */
struct _xmlSchemaType { xmlSchemaTypePtr subtypes; ... };
```

Both cycle-breaking policies miss it:

- **Policy 1** (`is_non_pointer_ref`, `passes.jl:340-351`) asks
  `is_jl_pointer(tojulia(fty))`, and `is_jl_pointer` is defined only on `JuliaCpointer`
  (`jltypes.jl:212-215`) — i.e. **top level only**. A field declared `xmlSchemaTypePtr` is a
  `JuliaCtypedef`, so the reference is misjudged as by-value and the edge is deemed
  unbreakable.
- **Policy 2** (the typedef fallback, `passes.jl:417-435`) requires
  `is_typedef_elaborated(child)`. `xmlSchemaTypePtr`'s underlying type refers to a *typedef*,
  not an elaborated tag, so the node is `TypedefDefault` and the branch is skipped.

Nothing changes, the loop spins to `MAX_CIRCIR_DETECTION_COUNT` and aborts.

#### Why the one-line fix is NOT the fix — and what it reveals

Canonicalizing the test (`is_jl_pointer(tojulia(getCanonicalType(fty)))`) makes libxml2 generate.
It also **breaks `method-ambiguity.h`**, which works today, producing unloadable output:

```julia
struct foo_struct
    bar::foo          # foo is not defined yet
end
const foo = Ptr{foo_struct}
```

Because policy 1 now fires where policy 2 used to, the edge `foo_struct → foo` is deleted — but
the *field* is still emitted as `bar::foo`. Deleting the ordering edge and degrading the field
are two separate decisions in the current code: the edge goes in `RemoveCircularReference`
(`passes.jl:390-400`), while whether to erase the field is decided later in codegen by an index
comparison (`codegen.jl:603`, `node_idx < field_idx`). Once ordering changes, that comparison
disagrees with the break.

**This is a hard requirement on the new design:**

> Breaking a cycle must remove the edge **and** degrade the referring field atomically, recording
> *which field* was degraded at the moment of the cut. The cut must not be reconstructed later
> from node positions.

The two-section-scc design reached the same conclusion independently, via `Edge.site`. It is the
single most important constraint this analysis produced, and it is why `nested-struct.h` and
libxml2 are both broken today.

### 2.1 On the clang-c corpus specifically, the sort is a no-op

clang-c, truncating the pipeline after the first `ResolveDependency`:

```
nodes 1176  (func 762, tag 188, typedef 161, macro 65)
edges  851
BACKWARD edges (adj index > own index): 0
```

Replacing `TopologicalSort` with a no-op and diffing the output: **byte-identical, 701,381
bytes.** The sort does nothing on this corpus because **C already forbids a non-pointer struct
member of an incomplete type**, so C source order is a valid topological order for every
non-pointer edge.

Edge composition (851 edges):

```
func -> typedef 588 | tag -> typedef 116 | typedef -> tag 59
func -> tag      58 | macro -> macro  22 | tag -> tag      8
edges out of FUNCTION nodes: 646 (76%)
edges TARGETING a function:    0   (in this corpus — see §1 for why that is not a law)
```

### 2.2 Where ordering *does* bite — and half of it is self-inflicted

Every backward edge in `test/include/` — **10 edges across 5 of 28 headers**:

| cause | n | where |
| --- | --- | --- |
| nested anon record `push!`ed to the END of `dag.nodes` | **4** | `nested.jl:19,27` — alignment.h, dependency.h, escape-with-var.h |
| opaque discovered late and `push!`ed | **1** | `nested.jl:35` — struct-mutual-ref.h |
| `typedef struct X X;` before `struct X{…}` | 3 | cycle-detection.h — **emits nothing**, inert |
| macro referring to a later macro | 1 | dependency.h |
| genuine typedef→pointer→struct cycle | 1 | method-ambiguity.h |

**Five of the ten are caused by the generator itself**, appending synthesized nodes to the end of
`dag.nodes` instead of splicing them before their parent. Three more are inert. The genuine
ordering problem in the entire fixture corpus is **two edges**.

**That number does not generalise, for the same reason clang-c's did not.** The fixtures are
minimal reproducers, mostly one or two declarations each. On libxml2 the type-to-type graph is
551 edges (`tag→typedef` 257, `typedef→tag` 141, `typedef→typedef` 107, `tag→tag` 46) of which
**205 run backwards**. Splicing synthesized nodes (§3.3) is still worth doing — it removes a
self-inflicted class — but it is a cleanup, not the solution. The ordering machinery has to work
for 205 backward edges, not two.

With no ordering repair at all, 26 of 28 fixtures load identically; exactly one regression
(`dependency.h` → `UndefVarError: SECOND`). So **"verify instead of sort" is a viable default
and an unviable policy** — it must stay a sort.

---

## 3. The design

### 3.1 `dag.nodes` is never permuted; emission goes through an order vector

```julia
Base.@kwdef struct ExprDAG
    nodes::Vector{ExprNode} = ExprNode[]   # SOURCE ORDER, for the whole run
    order::Vector{Int}      = Int[]        # emission order, a permutation of 1:length(nodes)
    rank::Vector{Int}       = Int[]        # inverse of `order`
    # tags / ids / ids_extra / sys unchanged
end
```

Today `TopologicalSort` does `dag.nodes .= list` (`passes.jl:489`) and then empties `dag.tags`
and `dag.ids` (`:492-493`) **because every integer in every `adj` just became wrong**. That is
the whole reason `IndexDefinition` and `ResolveDependency` appear again at
`context.jl:109-110`. Stop permuting and the indices stay valid for the entire run.

It also un-breaks the position-anchored tests (`ctx.dag.nodes[6]`, `nodes[end]`, `nodes[end-1]`
in #529/#535/#536): they index a stable source-ordered vector instead of a sorted one.

### 3.2 One pass replaces `RemoveCircularReference` + `TopologicalSort`

Cycle detection and ordering are the same DFS. Today they are two, and the first
(`detect_cycle!`, `passes.jl:316-338`) is restarted from scratch with `fill!(marks, UNMARKED)`
(`:382`) once per broken edge, up to `MAX_CIRCIR_DETECTION_COUNT = 100000` (`:372`).

Fuse them into one iterative walk in source order:

- a node finishing pushes itself to `order` (DFS post-order)
- a self-edge `v == u` is skipped: `struct B; x::Ptr{B}; end` needs no repair (measured)
- an edge to an `ONSTACK` node is a cycle, and **the cycle path falls out of the live stack** —
  no second traversal to find it
- on a break, `DONE` marks are **kept** (they are monotone under edge removal); only the live
  stack is rewound. This is the progress today's pass discards.
- an unbreakable cycle raises an error naming the path, replacing the fixed iteration budget

A 60-line prototype of the fused walk produced **byte-identical output on clang-c** and
identical generate-and-load outcomes on all 28 fixtures. Note what that does *not* establish:
the prototype kept today's `break_cycle!` policy verbatim, so it inherits the libxml2 failure in
§2.0. **The walk and the policy are separate changes, and only the walk is validated.**

### 3.2a The cycle-breaking policy must change too

Today's policy has two tiers and applies them in the wrong order, which is why
`method-ambiguity.h` costs eight top-level forms and a synthetic type:

```julia
mutable struct __JL_foo_struct end                       # a placeholder for a type we HAVE
function Base.unsafe_load(x::Ptr{__JL_foo_struct}) ... end
function Base.getproperty(x::Ptr{__JL_foo_struct}, f) ... end
function Base.setproperty!(x::Ptr{__JL_foo_struct}, f, v) ... end
const foo = Ptr{__JL_foo_struct}
struct foo_struct
    bar::foo
end
Base.unsafe_convert(::Type{Ptr{__JL_foo_struct}}, x::Base.RefValue{foo_struct}) = ...
Base.unsafe_convert(::Type{Ptr{__JL_foo_struct}}, x::Ptr{foo_struct}) = ...
```

**Tier 1 — canonical substitution (preferred, new).** If the field's declared type is a typedef
whose *canonical* type is a pointer, emit the field with the canonical pointer type. A
self-referential `Ptr` inside a struct is legal in Julia, so the cycle simply disappears:

```julia
struct foo_struct
    bar::Ptr{foo_struct}
end
const foo = Ptr{foo_struct}
```

Measured: loads, `sizeof(foo_struct) == 8` matching C, and `foo === Ptr{foo_struct}` — so the
public name survives and is now *better* typed than `Ptr{__JL_foo_struct}`. Two forms replace
eight, and `TypedefMutualRef`, `premature_exprs` and `partially_emitted_nodes` all become
unnecessary for this shape.

**Tier 2 — opaque placeholder (fallback, today's mechanism).** Substitution cannot break a
genuine mutual cycle between two *distinct* records: `struct A; b::Ptr{B}; end` before `B` fails
regardless of how `b`'s type is spelled (measured). Those keep the placeholder plus typed
repairs, which is what libxml2's `_xmlSchemaType` ↔ `_xmlSchemaFacet` pairs will need.

**Breakability is judged on the canonical spine** — through elaborated types, typedefs and
arrays — not on the declared type. That is the libxml2 fix (§2.0). It must land *together with*
the atomicity requirement, because canonicalizing alone re-routes `method-ambiguity.h` into
Tier 2 with no field degradation and produces unloadable output.

Self-edges need neither tier: `cycle-detection.h` already emits `struct B; x::Ptr{B}; end`, and
`struct-mutual-ref.h` emits `grad::Ptr{mutualref}` and `src::NTuple{10, Ptr{mutualref}}`, all
without repair.

### 3.2b The resulting pipeline

Today's pre-codegen stretch is 15 unconditional passes; the new one is 11. Nothing in the emit
stretch changes.

```
COLLECT
   1  CollectTopLevelNode              source order; assigns each node a STABLE KEY
   2  LinkTypedefToAnonymousTagType    (dag.nodes)
   3  LinkTypedefToAnonymousTagType    (dag.sys)
   4  IndexDefinition                  tags/ids : Symbol -> KEY;  marks *Duplicated
   5  CollectDependentSystemNode       pulls sys nodes in;  indexes each as it inserts
   6  CollectNestedRecord              SPLICES before parent; indexes each as it inserts
   7  FindOpaques                      rewrites in place
   8  CatchDuplicatedAnonymousTags

RESOLVE
   9  ResolveDependency                adj : KEY edges carrying kind + field site.
                                       Built ONCE. Never pruned.

ORDER
  10  OrderDefinitions                 one iterative DFS. Produces `dag.order` and a CUT SET;
                                       a cut records the edge AND the degraded field together.

EMIT  (unchanged except where noted)
  11  CodegenPreprocessing
  12  [DeAnonymize]  [Audit | LinkEnumAlias]
  13  Codegen                          consults the cut set for degraded fields
  14  CodegenMacro
  15  [AddFPtrMethods]
  16  [TweakMutability]                reads the FULL adj — see below
  17  VerifyOrder                      NEW (§3.4)
  18  printers
```

**What disappears, and why each one is now safe to remove:**

| removed | today's reason for existing | why it goes |
| --- | --- | --- |
| `IndexDefinition` #2 | `CollectDependentSystemNode` `prepend!`s, shifting every index | keys are stable; insertion shifts nothing |
| `IndexDefinition` #3 | `TopologicalSort` permutes `dag.nodes` | nothing permutes `dag.nodes` (§3.1) |
| `ResolveDependency` #2 | rebuilds the `adj` that #3 cleared | `adj` is built once and never cleared |
| `RemoveCircularReference` + `TopologicalSort` | two DFSs over the same graph | fused into `OrderDefinitions` (§3.2) |

**Two things make that possible, and neither is optional.**

*Stable keys.* Splicing (§3.3) inserts into the middle of `dag.nodes`, which shifts positions
just as `prepend!` and `dag.nodes .= list` do today. Position-keyed `adj`/`tags`/`ids` would be
invalidated by the very change meant to reduce churn. So each node gets an integer key at
creation, never reused, and `adj`, `tags`, `ids` and `dag.order` are all key-based. §3.1's
"don't permute" is really the weaker half of this.

*Non-destructive cuts.* Today `RemoveCircularReference` does `deleteat!(child.adj, idx)`
(`passes.jl:398`) and `ResolveDependency` #2 then silently rebuilds the deleted edge — which is
what `TweakMutability` reads (`mutability.jl:1-21`). The restoration is accidental and
undocumented. In the new design `OrderDefinitions` mutates nothing: it returns an order plus a
cut set, `adj` stays complete, and `TweakMutability` reads the full graph directly. **This is
what retires §5's "the second `ResolveDependency` cannot be deleted".** It could not be deleted
while cuts were destructive; once they are data, it can.

**One refactor this forces.** `IndexDefinition` currently does two jobs in one sweep — build the
Symbol→node index, and mark duplicates. Because the collectors at steps 5 and 6 add nodes
*after* it runs, it has to split into `index!(dag, node)` (one node: register or mark duplicate)
and `index!(dag)` (all of them), with the collectors calling the single-node form as they
insert. `CollectNestedRecord` already approximates this with its `new_tags` dict
(`nested.jl:20,28,36`); the difference is that the single-node form must also run the duplicate
check, which today only the whole-DAG sweep does.

### 3.3 Splice synthesized nodes, don't append

`collect_nested_record!` (`nested.jl:19,27,35`) appends hoisted anonymous records and
late-discovered opaques to the end of `dag.nodes`, creating 5 of the 10 backward edges in the
corpus. Splice them immediately before their parent instead. This removes the cause rather than
repairing the effect.

**Cost:** it changes the order in which `gensym_deterministic("Ctag")` is called, so every
`__JL_Ctag_N` renumbers. That churns pinned output and must land together with §3.1, not before.

### 3.4 A post-emission verifier

Walk the emitted `Expr`s in `dag.order`, collect definition-time symbols, and assert each is
bound by an earlier form. This turns a silently broken file into a located error.

It must run over the **printed** set (after `should_exclude_node`), because `output_ignorelist`
/ `output_exclusivelist` / `generate_isystem_symbols=false` delete nodes from the artifact after
ordering. And `bound_names` must special-case `@cenum`, `@objcwrapper`, `@objcproperties`,
`@autoproperty` and `@generated` before it is allowed to `error()` — those macro forms bind
names no plain `Expr` walk will see.

### 3.5 Bands: opt-in, not default

Banding (types → functions → macros) removes 646 of 851 edges on clang-c, and the proportion
holds on libxml2 — 2060 of 2735, **75.3%**, essentially identical to clang-c's 76%. So the
reduction is a real and general property, not a corpus artifact.

But it does not remove the need for the machinery. After banding, libxml2 still has 551
type-to-type edges with 205 backward, so the walk, the cycle-breaker and the two-tier policy are
all still required. **Banding is an optimisation, not an enabler** — which is what settles the
default.

libxml2 also supplies the empirical case for the band *order*. `edges TARGETING a function: 29`,
all of them `macro → func`: twenty-nine libxml2 macros expand to a function name, exactly the
`#define ALIAS c_func` shape from §1. The correction there is not theoretical — put macros
before functions and libxml2 emits 29 `const`s naming undefined bindings.

Against that, banding is a visible layout change for every downstream package and it collides
with the two-file
`output_api_file_path` / `output_common_file_path` split, where `FunctionPrinter` and
`CommonPrinter` already partition by kind into files the user includes in an order the generator
does not control.

**Therefore: bands are an option, default off.** `order_deps` returns `node.adj` unchanged
unless banding is enabled. The 76% edge reduction is a benefit of the flag, not of the default
pipeline.

---

## 4. Rejected: blob everything

Emitting every record as `struct X; data::NTuple{N,UInt8}; end` would delete record-to-record
edges and make ordering trivial. **Rejected — it is not portable.**

- `CXTUResourceUsageEntry` is sizeof 16 / offsetof 8 on arm64-darwin and x86_64-linux, but
  sizeof 8 / offsetof 4 on x86_64-windows-msvc and i686-linux. Blob sizes and accessor offsets
  are baked integer literals, so a generated file is silently wrong on any target but the
  generation host.
- On `constructors.h`'s `PackedFloat3`, the flattened constructor writes overlapping
  anonymous-union members; measured through a real C call, `pf_sum` returned **NaN instead of
  7.75**.
- Two anonymous unions in one struct produce duplicate field names in the flat table.
- A C field literally named `data` collides with the blob's synthetic `data`.

Selective blobbing — unions, and structs with attributes, bitfields or nested anonymous members
— stays exactly as it is today.

---

## 5. What this does *not* do

Stated plainly, because two earlier drafts overclaimed:

- **It does not remove the DAG.** The walk needs edges, `break_cycle!` needs
  `is_non_pointer_ref` (which re-queries cursors), and `adj` has three other consumers: skip
  propagation, layout propagation and `TweakMutability`.
- **The second `ResolveDependency` *can* now be dropped** — but only because cuts became data
  rather than mutations (§3.2b). While `RemoveCircularReference` destructively pruned `adj`,
  that pass was silently restoring the edges `TweakMutability` reads, and dropping it would have
  been a regression. An earlier draft of this document said it could not be removed; that was
  true of the design as then written.
- **It is still superlinear on breaks.** Each broken edge costs another O(V+E) walk — strictly
  better than today (progress kept, no fixed budget), but not linear.
- **`nested-struct.h` is not broken.** An earlier draft (and one design agent) claimed it fails
  both with and without ordering repair. Measured: it generates, **loads, and its accessors
  work** — `sizeof(test_t) == 8`, and `getproperty(ptr, :s)` returns a
  `Ptr{var"##Ctag#277"}`. Note its `getproperty` body names `__pthread_mutex_s`, which is
  defined at the *end* of the file, and that is fine: method bodies are lazy (§2).
- **`nested-declaration.h` is the genuinely broken fixture** (the `@test_broken` at
  `test/generators.jl:138-146`), and **ordering has nothing to do with it**:

  ```
  ERROR: There is no definition for Inner_t's underlying type: [`Inner`]
  ```

  ```c
  struct Outer { struct Inner { int i; } inner; };   /* Inner is globally visible in C */
  typedef struct Inner Inner_t;
  ```

  `struct Inner` is declared nested inside `Outer` but is visible at file scope.
  `collect_top_level_nodes!` walks only top-level cursors, and `Outer` lives in a system header
  so it is routed to `dag.sys` — so `Inner` never becomes a node, and the typedef's
  name-keyed lookup fails. This is a **collection** gap, not an ordering one. No change in this
  document fixes it; the verifier in §3.4 would not even see it, because the failure happens
  during dependency resolution, before emission. It is fixed for free by a frontend that walks
  `TypedefDecl → getUnderlyingType → getAsTagDecl` to a `RecordDecl` pointer instead of looking
  a name up in a table ([GENERATORS-REWORK.md](GENERATORS-REWORK.md) §5.3).

---

## 6. Validation plan

The clang-c evidence is necessary but **not sufficient**: that corpus has zero backward edges
and zero cycles, so a run over it exercises neither the hoister nor the cycle-breaker. The
prototype's `stats = (visited=1176, hoisted=0, broken=0)` says exactly that.

So validation must be fixture-driven:

1. **Byte-identical output on clang-c** — proves no regression on the opaque-handle path.
2. **libxml2 must generate and load.** It does not today (§2.0). This is the primary
   forward-declaration-heavy corpus and the acceptance test for the cycle-breaker; clang-c
   cannot substitute for it. Add it (or an equivalent `typedef T *TPtr`-idiom corpus) to the
   suite.
3. **Generate-and-load on all 28 fixtures** — the bar added in `test/macros.jl`, extended.
   `method-ambiguity.h` is the regression guard for the atomicity requirement in §2.0.
4. **A ≥3-node cycle fixture must be added.** Nothing in the corpus currently exercises a cycle
   path longer than 2, so the path-orientation fix in §3.2 has no regression test. The cycle
   path must be `reverse(stack[j:end])` with `v` appended, so consecutive pairs satisfy
   "child.adj contains parent" — the orientation `break_cycle!` consumes.
5. **A cross-TU case**: header `c.h` forward-declares a struct that `a.h` defines later in the
   umbrella. The fixtures do not cover this and source order across TUs is currently an
   assumption, not a verified property.

---

## 7. Staging

| step | change | check |
| --- | --- | --- |
| S1 | `dag.order`/`dag.rank`; stop permuting `dag.nodes` | byte-identical clang-c; #529/#535/#536 index a source-ordered vector |
| S2 | fuse `RemoveCircularReference` + `TopologicalSort` into one iterative walk | byte-identical clang-c; 28 fixtures load; **new ≥3-cycle fixture** |
| ~~S3~~ | ~~splice synthesized nodes instead of appending~~ | **DROPPED** — libclang-only, and the AST walk never appends. It was also the step forcing `__JL_Ctag_N` renumbering across every generated file, so this removes the worst compatibility cost for no loss. |
| S4 | post-emission verifier over the printed set | `nested-struct.h` fails loudly instead of silently |
| S5 | bands behind an option, default off | opt-in only; two-file split unaffected |

S1 and S2 are byte-identical refactors and can land independently. S3 changes output and must
follow S1. S4 is additive. S5 is opt-in.

---

## 8. For review

1. **Is `dag.order` acceptable as public surface?** `get_nodes(dag)` currently returns nodes in
   *emission* order and is the documented rewrite hook (`test/rewriter.jl`, `gen/generator.jl`).
   After S1 it returns source order. Either `get_nodes` changes meaning, or it keeps emission
   order via `dag.order` and a new accessor exposes source order. This is a public-API decision.
2. **Is the `__JL_Ctag_N` renumbering in S3 acceptable?** It is a one-time churn of every
   generated file that uses `use_deterministic_symbol`.
3. **Bands default off — agreed?** §3.5 argues yes on layout-stability grounds, which costs the
   76% edge reduction in the default path.
4. **Is `nested-struct.h` in scope?** It fails today. S4 makes it loud; fixing it is separate
   work in `get_nested_tag`.
