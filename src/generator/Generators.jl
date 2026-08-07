"""
    Generators

The C-header-to-Julia binding generator.

`create_context(headers, args, options)` then `build!(ctx)` writes a file of `ccall` wrappers,
structs, enums, constants and macros.

## Shape

Three stages over plain data, and nothing downstream of the first holds a clang handle:

    extract   CxxFacts   one reachability walk over the AST -> nodes of FACTS
    order     CxxOrder   emission order + the cuts a genuine cycle forces
    emit      CxxEmit    facts -> Julia

This replaces a 21-pass pipeline over a mutable expression DAG. Most of those passes existed
to reconstruct, by name and by source location, what libclang could not hand over: the
typedef↔anonymous-tag link, cross-translation-unit duplicate marking, dependent system nodes,
nested-record discovery, opaque detection. Parsing every header into ONE translation unit and
keying on `getCanonicalDecl` answers all of it directly, so there is nothing left for those
passes to do. See `GENERATORS-REWORK.md`.

## Rewriting the output

`build!` still splits into two stages, so a caller can inspect and edit before anything is
written:

    ctx = create_context(headers, args, options)
    build!(ctx, BUILDSTAGE_NO_PRINTING)
    # ctx.nodes is a plain Vector{Node} -- filter it, map it, replace facts
    build!(ctx, BUILDSTAGE_PRINTING_ONLY)

`ctx.nodes` replaces the old `ctx.dag.nodes`. It is ordinary data rather than a graph with
index-valued edges, so a rewriter is `filter`/`map` rather than surgery that has to keep
`node.adj` consistent.
"""
module Generators

using TOML

using ..JLLEnvs
using ..JLLEnvs: get_system_dirs, triple2target

include("facts.jl")
using .CxxFacts
include("order.jl")
using .CxxOrder
include("macros.jl")
using .CxxMacros
include("emit.jl")
using .CxxEmit

export create_context, build!, get_default_args, detect_headers, load_options
export BUILDSTAGE_ALL, BUILDSTAGE_NO_PRINTING, BUILDSTAGE_PRINTING_ONLY
export Context, Options
# the data model, for rewriters
export Node, RecordFacts, EnumFacts, TypedefFacts, FunctionFacts, FieldFacts
export TypeRef, BuiltinRef, PointerRef, ArrayRef, RecordRef, EnumRef, TypedefRef,
       FunctionRef, UnknownRef

const BUILDSTAGE_ALL = 0
const BUILDSTAGE_NO_PRINTING = 1
const BUILDSTAGE_PRINTING_ONLY = 2

"""
    load_options(path) -> Dict

Parse a `generator.toml`. As before there is no schema and no validation, so a misspelled key
is silently inert — `Options(dict)` reads the keys it knows and ignores the rest.
"""
load_options(path::AbstractString) = TOML.parsefile(path)

"""
    Context

A generator run. `nodes` and `macros` are empty until `build!` has run its first stage.
"""
mutable struct Context
    headers::Vector{String}
    args::Vector{String}
    options::Dict{String,Any}
    opts::CxxEmit.Options
    nodes::Vector{CxxFacts.Node}
    macros::Vector{Any}
end

"""
    create_context(headers, args=get_default_args(), options=Dict()) -> Context

Set up a run over `headers`. Nothing is parsed yet — that happens in `build!`, so a caller can
adjust `ctx.args` or `ctx.opts` first.

Unlike the libclang pipeline this does **not** parse each header into its own translation unit;
`build!` parses them together as one. That is what removes cross-translation-unit duplicate
analysis rather than improving it.
"""
function create_context(headers::Vector{String}, args::Vector{String}=get_default_args(),
                        options::Dict=Dict{String,Any}())
    opts = CxxEmit.Options(options)
    return Context(headers, args, Dict{String,Any}(options), opts, CxxFacts.Node[], Any[])
end
create_context(header::AbstractString, args=get_default_args(), options=Dict{String,Any}()) =
    create_context([String(header)], args, options)

"Where a built context writes: either one file, the api/common pair, or stdout."
function output_paths(ctx::Context)
    g = get(ctx.options, "general", Dict{String,Any}())
    api = string(get(g, "output_api_file_path", ""))
    common = string(get(g, "output_common_file_path", ""))
    isempty(api) && isempty(common) && return (string(get(g, "output_file_path", "")), "", "")
    return ("", api, common)
end

"""
    build!(ctx, stage=BUILDSTAGE_ALL) -> ctx

Run the generator. `BUILDSTAGE_NO_PRINTING` stops after extraction so `ctx.nodes` can be
rewritten; `BUILDSTAGE_PRINTING_ONLY` emits whatever `ctx.nodes` now holds.
"""
function build!(ctx::Context, stage::Int=BUILDSTAGE_ALL)
    if stage == BUILDSTAGE_ALL || stage == BUILDSTAGE_NO_PRINTING
        ctx.nodes = CxxFacts.extract(ctx.headers; args=ctx.args,
                                     comments=ctx.opts.extract_c_comment_style != "disable")
        ctx.macros = ctx.opts.macro_mode == "disable" ? Any[] :
                     Vector{Any}(CxxMacros.translate_macros(ctx.headers, ctx.args))
    end
    if stage == BUILDSTAGE_ALL || stage == BUILDSTAGE_PRINTING_ONLY
        single, api, common = output_paths(ctx)
        if !isempty(api) || !isempty(common)
            open(isempty(common) ? tempname() : common, "w") do cio
                open(isempty(api) ? tempname() : api, "w") do aio
                    CxxEmit.generate(ctx.nodes; options=ctx.opts, macros=ctx.macros,
                                     io=cio, api_io=aio)
                end
            end
        elseif isempty(single)
            CxxEmit.generate(ctx.nodes; options=ctx.opts, macros=ctx.macros, io=stdout)
        else
            open(single, "w") do io
                CxxEmit.generate(ctx.nodes; options=ctx.opts, macros=ctx.macros, io=io)
            end
        end
    end
    @info "Done!"
    return ctx
end

# ------------------------------------------------------------------------------------------
# Toolchain arguments
# ------------------------------------------------------------------------------------------
const GCC_MIN_VER = v"4.8.5"

function get_triple()
    is_libc_musl = occursin("musl", Base.MACHINE)
    if Sys.isapple() && Sys.ARCH === :aarch64
        return "aarch64-apple-darwin20"
    elseif Sys.islinux() && Sys.ARCH === :aarch64 && !is_libc_musl
        return "aarch64-linux-gnu"
    elseif Sys.islinux() && Sys.ARCH === :aarch64 && is_libc_musl
        return "aarch64-linux-musl"
    elseif Sys.islinux() && startswith(string(Sys.ARCH), "arm") && !is_libc_musl
        return "armv7l-linux-gnueabihf"
    elseif Sys.islinux() && startswith(string(Sys.ARCH), "arm") && is_libc_musl
        return "armv7l-linux-musleabihf"
    elseif Sys.islinux() && Sys.ARCH === :i686 && !is_libc_musl
        return "i686-linux-gnu"
    elseif Sys.islinux() && Sys.ARCH === :i686 && is_libc_musl
        return "i686-linux-musl"
    elseif Sys.iswindows() && Sys.ARCH === :i686
        return "i686-w64-mingw32"
    elseif Sys.islinux() && Sys.ARCH === :powerpc64le
        return "powerpc64le-linux-gnu"
    elseif Sys.isapple() && Sys.ARCH === :x86_64
        return "x86_64-apple-darwin14"
    elseif Sys.islinux() && Sys.ARCH === :x86_64 && !is_libc_musl
        return "x86_64-linux-gnu"
    elseif Sys.islinux() && Sys.ARCH === :x86_64 && is_libc_musl
        return "x86_64-linux-musl"
    elseif Sys.isbsd() && !Sys.isapple()
        return "x86_64-unknown-freebsd"
    elseif Sys.iswindows() && Sys.ARCH === :x86_64
        return "x86_64-w64-mingw32"
    end
end

"""
    get_default_args(triple=get_triple(); is_cxx=false, version=GCC_MIN_VER)

The `-isystem` flags and `--target` for a cross-compilation shard, so generation does not depend
on the host's own headers.

The C++ path additionally needs clang's builtin include directory, which now comes from the
running `clang-cpp` rather than from a libclang JLL path.
"""
function get_default_args(triple=get_triple(); is_cxx=false, version=GCC_MIN_VER)
    if is_cxx
        env = JLLEnvs.get_default_env(triple; version, is_cxx)
        args = ["-isystem" * dir for dir in JLLEnvs.get_system_includes(env)]
        inc = CxxFacts.builtin_include_dir()
        isempty(inc) || push!(args, "-isystem" * inc)
        push!(args, "--target=$(JLLEnvs.target(env.platform))")
        return args
    else
        args = ["-isystem" * dir for dir in get_system_dirs(triple)]
        push!(args, "--target=$(triple2target(triple))")
        return args
    end
end

"""
    detect_headers(include_dir, args, options=Dict(), filter=(header)->false)

Every header in `include_dir` that is not included by another header there — the set that spans
the directory. Use `filter` to drop candidates.
"""
function detect_headers(include_dir, args, options::Dict=Dict(), filter_op=(header) -> false)
    system_dirs = map(x -> x[9:end], filter(x -> startswith(x, "-isystem"), args))
    all = String[]
    for (root, dirs, files) in walkdir(include_dir)
        any(d -> normpath(root) == normpath(d), system_dirs) && continue
        for f in files
            (endswith(f, ".h") || endswith(f, ".hh") || endswith(f, ".hpp")) || continue
            p = joinpath(root, f)
            filter_op(p) || push!(all, normpath(p))
        end
    end
    sort!(all)
    isempty(all) && return all
    # A header included by another in the same set is covered already. Asking clang which files
    # a parse touched is exact, where the old pass walked InclusionDirective cursors per TU.
    included = CxxFacts.included_files(all; args=args)
    return filter(h -> !(normpath(h) in included), all)
end

end # module
