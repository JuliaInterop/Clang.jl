# Settled design: emission ordering

**Status**: for review. No code changes yet.
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

`break_cycle!` keeps today's policy verbatim so output does not move: prefer a record whose
reference is pointer-mediated (retype `StructMutualRef`), else a `TypedefElaborated` whose
underlying type is a pointer (retype `TypedefMutualRef`).

A 60-line prototype of this produced **byte-identical output on clang-c** and identical
generate-and-load outcomes on all 28 fixtures, including method-ambiguity.h, cycle-detection.h,
struct-mutual-ref.h and dependency.h.

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

Banding (types → functions → macros) removes 646 of 851 edges from the ordering graph. But it is
a visible layout change for every downstream package and it collides with the two-file
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
- **It does not delete the second `ResolveDependency`.** That pass restores the edges
  `RemoveCircularReference` pruned, and `TweakMutability` depends on the restored content. It
  can be narrowed to mutual-ref nodes, but not dropped. The "15 passes → 13" saving does not
  hold.
- **It is still superlinear on breaks.** Each broken edge costs another O(V+E) walk — strictly
  better than today (progress kept, no fixed budget), but not linear.
- **It does not fix `nested-struct.h`**, which fails today and will continue to. The underlying
  missing edge is `get_nested_tag` returning `nothing` (`resolve_deps.jl:158-163`); the verifier
  only makes the failure loud.

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
| S3 | splice synthesized nodes instead of appending | `__JL_Ctag_N` renumbering expected — re-pin |
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
