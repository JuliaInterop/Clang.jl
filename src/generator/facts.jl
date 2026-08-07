"""
    CxxFacts

Frontend-neutral facts extracted from clang's AST, and the reachability walk that produces
them.

This replaces passes 1–8 of the libclang pipeline (`GENERATORS-REWORK.md` §0). Those passes
exist to reconstruct, by name, what libclang cannot hand over — the typedef↔anonymous-tag link,
a `Symbol` index, cross-TU duplicate marking, dependent system nodes, nested-record discovery
and opaque detection. Every one of them is a direct question to the AST, so a single walk keyed
on `decl_id` subsumes the lot.

Nothing here holds a clang handle past extraction. A node carries *facts* — field offsets in
bits, sizes in bytes, the resolved key of every type it references — so downstream passes never
re-query the AST, which is what makes the ordering and codegen stages frontend-independent
(`GENERATORS-REWORK.md` §3.5).
"""
module CxxFacts

import ClangCompiler as CC
using ClangCompiler: create_interpreter, dispose

export extract, Node, RecordFacts, EnumFacts, TypedefFacts, FunctionFacts, FieldFacts
export builtin_include_dir, included_files
export TypeRef, BuiltinRef, PointerRef, ArrayRef, RecordRef, EnumRef, TypedefRef,
       FunctionRef, UnknownRef, deps, Key

const Key = UInt   # a clang decl identity; stable for the life of one ASTContext

# ------------------------------------------------------------------------------------------
# Types, as a frontend-neutral tree
# ------------------------------------------------------------------------------------------
abstract type TypeRef end

struct BuiltinRef <: TypeRef;  name::Symbol;                       end  # :int, :char, :double…
struct PointerRef <: TypeRef;  pointee::TypeRef;                   end
struct ArrayRef   <: TypeRef;  elem::TypeRef; len::Int;            end  # len < 0 => incomplete
struct RecordRef  <: TypeRef;  key::Key;                           end
struct EnumRef    <: TypeRef;  key::Key;                           end
struct TypedefRef <: TypeRef;  key::Key;                           end
struct FunctionRef<: TypeRef;  ret::TypeRef; params::Vector{TypeRef}; variadic::Bool; end
struct UnknownRef <: TypeRef;  spelling::String;                   end

"""
Every declaration key this type mentions, and whether the reference is pointer-mediated.

The contract is **what codegen will emit**, not what the C type mentions. Anything looser and
the ordering pass invents constraints that no Julia expression actually has; anything tighter
and it emits a name before its definition.

Hence the silence on `FunctionRef`: a function type is untyped in the output — every one becomes
`Ptr{Cvoid}` — so its return and parameter types impose no ordering at all. Descending into them
made libxml2's `xmlDOMWrapAcquireNsFunction` claim five dependencies for a line that reads
`const xmlDOMWrapAcquireNsFunction = Ptr{Cvoid}`, one of which closed a cycle that then could not
be broken, because there was no real edge there to cut. (Function *declarations* are unaffected:
`deps(::Node)` walks a `FunctionFacts`' own params and return type, which the `ccall` does name.)
"""
function deps!(out::Vector{Pair{Key,Bool}}, t::TypeRef, viaptr::Bool=false)
    if t isa RecordRef || t isa EnumRef || t isa TypedefRef
        push!(out, t.key => viaptr)
    elseif t isa PointerRef
        deps!(out, t.pointee, true)
    elseif t isa ArrayRef
        deps!(out, t.elem, viaptr)      # an array does NOT introduce indirection
    end
    return out
end
deps(t::TypeRef) = deps!(Pair{Key,Bool}[], t)

# ------------------------------------------------------------------------------------------
# Declarations
# ------------------------------------------------------------------------------------------
struct FieldFacts
    name::Symbol          # Symbol("") when unnamed
    type::TypeRef
    bitoffset::Int        # BITS, from ASTRecordLayout — addresses unnamed fields too
    bitwidth::Int         # -1 when not a bit-field
end

abstract type DeclFacts end

struct RecordFacts <: DeclFacts
    kind::Symbol                  # :struct | :union
    fields::Vector{FieldFacts}
    size::Int                     # bytes; -1 when incomplete
    align::Int                    # bytes; -1 when incomplete
    complete::Bool                # false => opaque
    packed::Bool
end

struct EnumFacts <: DeclFacts
    integer_type::TypeRef
    constants::Vector{Pair{Symbol,Int}}
end

struct TypedefFacts <: DeclFacts
    underlying::TypeRef
end

struct FunctionFacts <: DeclFacts
    params::Vector{Pair{Symbol,TypeRef}}
    ret::TypeRef
    variadic::Bool
    internal::Bool                # `static`
end

"""
One declaration. `key` is clang's identity — the stable key the ordering pass needs
(`ORDERING-DESIGN.md` §3.2b) — so nothing is invalidated by insertion or reordering.
"""
struct Node
    key::Key
    id::Symbol                    # the Julia name to emit; Symbol("") when anonymous+unnamed
    facts::DeclFacts
    file::String
    line::Int
    system::Bool                  # clang says the decl is in a system header
    anonymous::Bool
    typedef_name::Symbol          # getTypedefNameForAnonDecl, or Symbol("")
    doc::String                   # raw comment text; "" unless extraction asked for comments
end

"Dependency edges of a node: `key => pointer_mediated`."
function deps(n::Node)
    out = Pair{Key,Bool}[]
    f = n.facts
    if f isa RecordFacts
        for fld in f.fields; deps!(out, fld.type); end
    elseif f isa TypedefFacts
        deps!(out, f.underlying)
    elseif f isa FunctionFacts
        deps!(out, f.ret)
        for (_, t) in f.params; deps!(out, t); end
    elseif f isa EnumFacts
        deps!(out, f.integer_type)
    end
    return out
end

# ------------------------------------------------------------------------------------------
# Extraction
# ------------------------------------------------------------------------------------------
const BUILTIN = Dict(
    "void"=>:void, "_Bool"=>:bool, "bool"=>:bool, "char"=>:char,
    "signed char"=>:schar, "unsigned char"=>:uchar,
    "short"=>:short, "unsigned short"=>:ushort, "int"=>:int, "unsigned int"=>:uint,
    "long"=>:long, "unsigned long"=>:ulong, "long long"=>:longlong,
    "unsigned long long"=>:ulonglong, "float"=>:float, "double"=>:double,
    "long double"=>:longdouble, "__int128"=>:int128, "unsigned __int128"=>:uint128,
    "wchar_t"=>:wchar, "char16_t"=>:char16, "char32_t"=>:char32)

sname(d) = CC.is_null_handle(CC.getIdentifier(d)) ? "" : CC.getName(d)

mutable struct Ctx
    interp
    ctx
    sm
    nodes::Vector{Node}
    seen::Dict{Key,Int}     # key -> index into nodes
    comments::Bool          # ask clang for each decl's raw comment (off: it is per-decl work)
end

"""
Translate a clang type into a `TypeRef`, registering any declaration it names.

Qualifiers come off first. `getAsString` on a `QualType` includes them, so the builtin table
was being probed with `"const int"` and `"unsigned const int"` — neither of which is a key, so
both fell to `:unknown` and then to `Cvoid`. That made `const char *` into `Ptr{Cvoid}` (every
string parameter in glib) and, far worse, a `const int` struct field into a ZERO-SIZED one.
Stripping here rather than at each call site means the recursion handles every level:
`const char *` is an unqualified pointer whose pointee arrives as `const char` and is stripped
in turn.
"""
function typeref(c::Ctx, qt, depth::Int=0)
    qt = CC.getUnqualifiedType(qt)
    tp = CC.getTypePtr(qt)
    r = CC.resolve(tp)
    if r isa CC.AbstractBuiltinType
        return BuiltinRef(get(BUILTIN, CC.getAsString(qt), :unknown))
    elseif r isa CC.AbstractPointerType
        return PointerRef(typeref(c, CC.getPointeeType(r)))
    elseif r isa CC.AbstractConstantArrayType
        # getSize returns an LLVMGenericValueRef (ClangCompiler#43); go through the element
        # count clang already computed for the whole array instead.
        n = try
            Int(CC.getTypeSizeInChars(c.ctx, qt) ÷ max(CC.getTypeSizeInChars(c.ctx, CC.getElementType(r)), 1))
        catch; -1 end
        return ArrayRef(typeref(c, CC.getElementType(r)), n)
    elseif r isa CC.AbstractIncompleteArrayType
        return ArrayRef(typeref(c, CC.getElementType(r)), -1)
    elseif r isa CC.AbstractFunctionProtoType
        ps = TypeRef[typeref(c, CC.getParamType(r, i)) for i = 0:(CC.getNumParams(r) - 1)]
        return FunctionRef(typeref(c, CC.getReturnType(r)), ps, CC.isVariadic(r))
    elseif r isa CC.AbstractFunctionNoProtoType
        return FunctionRef(typeref(c, CC.getReturnType(r)), TypeRef[], false)
    end
    # ORDER MATTERS. A typedef must be recognised BEFORE falling through to `getAsTagDecl`,
    # which looks straight through the sugar to the underlying tag. Checking the tag first
    # spells `__list::__pthread_internal_list` where the source wrote `__pthread_list_t` —
    # ABI-identical, but it discards the name the header chose, and readability is an
    # acceptance criterion here (GENERATORS-REWORK.md §5.7).
    if r isa CC.AbstractTypedefType
        return TypedefRef(visit(c, CC.resolve(CC.getDecl(r))))
    elseif r isa CC.AbstractElaboratedType
        return typeref(c, CC.getNamedType(r))    # `struct Foo` / `enum Bar` keyword sugar
    end
    td = CC.getAsTagDecl(tp)
    if !CC.is_null_handle(td)
        d = CC.resolve(td)
        return d isa CC.AbstractEnumDecl ? EnumRef(visit(c, d)) : RecordRef(visit(c, d))
    end
    # Sugar we do not name explicitly: `AttributedType` (`_Nullable`, `__attribute__`),
    # `MacroQualifiedType`, `ParenType`, `AdjustedType`/`DecayedType`. One desugaring step
    # covers all of them and any kind clang adds later, which matters because the failure is
    # silent and non-local: an unrecognised type became `UnknownRef` -> `Cvoid`, and a `Cvoid`
    # field is ZERO-SIZED in Julia. macOS's `FILE` has four `_Nullable` function pointers, so
    # `__sFILE` came out 120 bytes instead of 152 and every field after the first one was at the
    # wrong offset. Nothing downstream could have caught that; only comparing against clang's
    # own ASTRecordLayout did.
    if depth < 8
        ds = try CC.getSingleStepDesugaredType(qt, c.ctx) catch; nothing end
        if ds !== nothing && CC.getTypePtr(ds).ptr != tp.ptr
            return typeref(c, ds, depth + 1)
        end
    end
    return UnknownRef(CC.getAsString(qt))
end

"""
The one node a declaration belongs to.

A forward declaration and its definition are *different* `Decl`s with different `decl_id`s, so
keying on the decl as found would emit two nodes for one entity — which is the duplicate
problem `IndexDefinition` solves by name, first-wins, in the libclang pipeline. Clang answers
it directly: `getCanonicalDecl` maps every redeclaration to the same representative.
"""
function canonical(d)
    (d isa CC.AbstractTagDecl || d isa CC.AbstractTypedefNameDecl ||
     d isa CC.AbstractFunctionDecl) || return d
    cd = CC.getCanonicalDecl(d)
    return CC.is_null_handle(cd) ? d : CC.resolve(cd)
end

"Extract one declaration (idempotent), returning its key."
function visit(c::Ctx, d)::Key
    d = canonical(CC.resolve(d))
    k = CC.decl_id(d)
    haskey(c.seen, k) && return k
    c.seen[k] = 0                              # reserve: breaks recursion on self-reference

    loc = CC.getBeginLoc(d)
    sys = CC.isInSystemHeader(c.sm, loc)
    pl  = try CC.getPresumedLoc(c.sm, loc) catch; nothing end
    file, line = pl === nothing ? ("", 0) : (String(pl[1]), Int(pl[2]))

    anon = CC.is_null_handle(CC.getIdentifier(d))
    tdn  = Symbol("")
    if anon && d isa CC.AbstractTagDecl
        t = CC.getTypedefNameForAnonDecl(d)
        CC.is_null_handle(t) || (tdn = Symbol(sname(CC.resolve(t))))
    end

    # "ForAnyRedecl" matters: C headers routinely carry the doc comment on the forward
    # declaration and leave the definition bare, and `canonical` above may have landed on
    # either one.
    doc = c.comments ? (try CC.getRawCommentTextForAnyRedecl(c.ctx, d) catch; "" end) : ""

    facts = extract_facts(c, d)
    id = anon ? tdn : Symbol(sname(d))
    node = Node(k, id, facts, file, line, sys, anon, tdn, doc)
    push!(c.nodes, node)
    c.seen[k] = length(c.nodes)
    return k
end

function extract_facts(c::Ctx, d)
    if d isa CC.AbstractRecordDecl
        def = CC.definition(d)
        kind = CC.isUnion(d) ? :union : :struct
        def === nothing && return RecordFacts(kind, FieldFacts[], -1, -1, false, false)
        lay = CC.get_record_layout(c.ctx, def)
        flds = FieldFacts[]
        for f in CC.getFields(def)
            bw = CC.isBitField(f) ? Int(CC.getBitWidthValue(f, c.ctx)) : -1
            push!(flds, FieldFacts(Symbol(sname(f)), typeref(c, CC.getType(f)),
                                   Int(CC.getFieldOffset(lay, CC.getFieldIndex(f))), bw))
        end
        packed = try CC.hasAttrOfKind(def, CC.LibClangEx.CXAttrKind_Packed) catch; false end
        return RecordFacts(kind, flds, Int(CC.getSize(lay)), Int(CC.getAlignment(lay)), true, packed)

    elseif d isa CC.AbstractEnumDecl
        def = CC.definition(d)
        def === nothing && return EnumFacts(BuiltinRef(:int), Pair{Symbol,Int}[])
        cs = Pair{Symbol,Int}[]
        for e in CC.getEnumerators(def)
            gv = CC.getInitVal(e)
            v = CC.LLVM.GenericValue(gv)
            push!(cs, Symbol(sname(e)) => convert(Int, v))
            CC.LLVM.dispose(v)
        end
        return EnumFacts(typeref(c, CC.getIntegerType(def)), cs)

    elseif d isa CC.AbstractTypedefNameDecl
        return TypedefFacts(typeref(c, CC.getUnderlyingType(d)))

    elseif d isa CC.AbstractFunctionDecl
        ps = Pair{Symbol,TypeRef}[]
        for i = 0:(CC.getNumParams(d) - 1)
            p = CC.getParamDecl(d, i)
            push!(ps, Symbol(sname(p)) => typeref(c, CC.getType(p)))
        end
        ft = CC.resolve(CC.getTypePtr(CC.getType(d)))
        va = ft isa CC.AbstractFunctionProtoType && CC.isVariadic(ft)
        return FunctionFacts(ps, typeref(c, CC.getReturnType(d)), va, !CC.isExternallyVisible(d))
    end
    return TypedefFacts(UnknownRef(string(nameof(typeof(d)))))
end

"""
    extract(headers; args=String[], is_cxx=false) -> Vector{Node}

Parse `headers` as ONE translation unit and walk it. Nodes come back in discovery order, which
is source order for top-level declarations — the starting point the ordering pass perturbs as
little as possible (`ORDERING-DESIGN.md` §3).
"""
function extract(headers::Vector{String}; args::Vector{String}=String[], is_cxx::Bool=false,
                 comments::Bool=false)
    flags = is_cxx ? copy(args) : String["-x", "c", args...]
    I = create_interpreter(flags; is_cxx)
    try
        ci = CC.get_instance(I)
        ctx = CC.get_ast_context(I)
        umbrella = join(("#include \"$h\"" for h in headers), '\n') * "\n"
        CC.parse(I, umbrella)
        CC.setTraversalScope(ctx, [CC.getTranslationUnitDecl(ctx)])
        c = Ctx(I, ctx, CC.getSourceManager(ci), Node[], Dict{Key,Int}(), comments)
        for d in CC.decls_in(CC.castToDeclContext(CC.getTranslationUnitDecl(ctx)))
            (d isa CC.AbstractRecordDecl || d isa CC.AbstractEnumDecl ||
             d isa CC.AbstractTypedefNameDecl || d isa CC.AbstractFunctionDecl) || continue
            CC.isInSystemHeader(c.sm, CC.getBeginLoc(d)) && continue
            visit(c, d)
        end
        return c.nodes
    finally
        dispose(I)
    end
end

# ------------------------------------------------------------------------------------------
# Toolchain queries
# ------------------------------------------------------------------------------------------
const BUILTIN_INCLUDE = Ref{Union{Nothing,String}}(nothing)

"""
    builtin_include_dir() -> String

Clang's own resource include directory (`stddef.h`, `stdarg.h`, …), asked of the running
frontend rather than derived from a JLL's artifact path. `""` if it cannot be determined.

Cached: it needs an interpreter to answer, and the answer cannot change within a session.
"""
function builtin_include_dir()
    BUILTIN_INCLUDE[] === nothing || return BUILTIN_INCLUDE[]
    dir = try
        I = create_interpreter(String[])
        try
            rd = CC.GetResourceDir(CC.getHeaderSearchOpts(CC.get_instance(I)))
            isempty(rd) ? "" : joinpath(rd, "include")
        finally
            dispose(I)
        end
    catch
        ""
    end
    BUILTIN_INCLUDE[] = dir
    return dir
end

"""
    included_files(headers; args=String[]) -> Set{String}

The normalised paths in `headers` that some header in the set `#include`s.

`detect_headers` uses this to keep only the headers that span a directory. The inclusion
directives come from clang's own preprocessing record — not a regex over the source — but the
record stores the *spelling* written in the directive, so a candidate is matched by path suffix.
That is exact for the case that matters (`#include "libxml/tree.h"` naming a candidate whose
path ends the same way) and cannot mistake a comment or a disabled `#if` branch for a directive.
"""
function included_files(headers::Vector{String}; args::Vector{String}=String[])
    out = Set{String}()
    isempty(headers) && return out
    I = create_interpreter(String["-x", "c", args...])
    try
        ci = CC.get_instance(I)
        pp = CC.getPreprocessor(ci)
        CC.createPreprocessingRecord(pp)
        CC.parse(I, join(("#include \"$h\"" for h in headers), '\n') * "\n")
        rec = CC.getPreprocessingRecord(pp)
        CC.is_null_handle(rec) && return out
        # The umbrella's OWN `#include` lines are inclusion directives like any other, so
        # counting them marks every candidate as included-by-something and detection returns
        # nothing. They are identified by what they spell: the umbrella writes each header's
        # full path, where a real directive inside a header writes whatever that header wrote.
        # (Filtering by `isInMainFile` does not work — the umbrella is an incremental input
        # buffer, not the translation unit's main file.)
        mine = Set(replace(h, '\\' => '/') for h in headers)
        spellings = Set{String}()
        for ent in CC.getPreprocessedEntities(rec)
            inc = CC.InclusionDirective(ent)
            CC.is_null_handle(inc) && continue
            nm = replace(CC.getFileName(inc), '\\' => '/')
            (isempty(nm) || nm in mine) && continue
            push!(spellings, nm)
        end
        for h in headers
            p = replace(normpath(h), '\\' => '/')
            any(s -> endswith(p, s), spellings) && push!(out, normpath(h))
        end
    catch err
        # A directory that does not parse as one umbrella is not a reason to fail detection;
        # returning nothing included means every candidate is reported, which is the safe way
        # to be wrong here. It is NOT a reason to be silent, though: this catch swallowed a
        # misspelled field accessor once, and the only symptom was detection quietly reporting
        # every header including the ones it should have filtered.
        @warn "detect_headers: could not determine inclusions; reporting every candidate" err
    finally
        dispose(I)
    end
    return out
end

end # module
