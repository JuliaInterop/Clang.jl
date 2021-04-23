abstract type AbstractContext end

Base.@kwdef mutable struct Context <: AbstractContext
    index::Index = Index(true)
    trans_units::Vector{TranslationUnit} = TranslationUnit[]
    passes::Vector{AbstractPass} = AbstractPass[]
    dag::ExprDAG = ExprDAG()
    options::Dict = Dict()
end

function parse_header!(ctx::AbstractContext, header::AbstractString, args)
    flags = CXTranslationUnit_DetailedPreprocessingRecord
    flags |= CXTranslationUnit_SkipFunctionBodies
    push!(ctx.trans_units, parse_header(ctx.index, header, args, flags))
    return ctx
end

function parse_headers!(ctx::AbstractContext, headers::Vector{<:AbstractString}, args)
    flags = CXTranslationUnit_DetailedPreprocessingRecord
    flags |= CXTranslationUnit_SkipFunctionBodies
    tus = parse_headers(ctx.index, headers, args, flags)
    append!(ctx.trans_units, tus)
    return ctx
end

"""
    find_dependent_headers(headers::Vector{T}, args::Vector, system_dirs) where {T<:AbstractString}
Return a vector of headers to which those missing dependent headers are added.
"""
function find_dependent_headers(headers::Vector{T}, args::Vector, system_dirs) where {T<:AbstractString}
    flags = CXTranslationUnit_DetailedPreprocessingRecord
    flags |= CXTranslationUnit_SkipFunctionBodies
    all_headers = copy(headers)
    dependent_headers = T[]
    new_headers = T[]
    idx = Index(false)
    while true
        empty!(new_headers)
        for header in all_headers
            try
                parse_header(idx, header, args, flags)
            catch err
                @info "failed to parse $header, skip..."
                retheow(err)
                continue
            end
            tu = parse_header(idx, header, args, flags)
            GC.@preserve tu begin
                tu_cursor = getTranslationUnitCursor(tu)
                for cursor in children(tu_cursor)
                    is_inclusion_directive(cursor) || continue
                    file = getIncludedFile(cursor)
                    file_name = get_filename(file) |> normpath
                    (isempty(file_name) || !isfile(file_name)) && continue
                    # skip system headers
                    any(sysdir->startswith(file_name, sysdir), system_dirs) && continue
                    file_name ∈ all_headers && continue
                    file_name ∈ new_headers && continue
                    push!(new_headers, file_name)
                end
            end
        end
        isempty(new_headers) && break
        foreach(new_headers) do h
            @info "found dependent header: $h"
        end
        append!(dependent_headers, new_headers)
        append!(all_headers, new_headers)
    end

    return normpath.(dependent_headers)
end

"""
    create_context(headers::Vector, args::Vector=String[], options::Dict=Dict())
Create a context from a vector of paths of headers, a vector of compiler flags and
a option dict.
"""
function create_context(headers::Vector, args::Vector=String[], options::Dict=Dict())
    ctx = Context(; options)

    system_dirs = map(x->x[9:end], filter(x->startswith(x, "-isystem"), args))
    dependant_headers = find_dependent_headers(headers, args, system_dirs)

    parse_headers!(ctx, headers, args)

    push!(ctx.passes, CollectTopLevelNode(ctx.trans_units, dependant_headers, system_dirs))
    push!(ctx.passes, LinkTypedefToAnonymousTagType())
    push!(ctx.passes, IndexDefinition())
    push!(ctx.passes, CollectNestedRecord())
    push!(ctx.passes, FindOpaques())
    push!(ctx.passes, ResolveDependency())
    push!(ctx.passes, RemoveCircularReference())
    push!(ctx.passes, TopologicalSort())
    push!(ctx.passes, IndexDefinition())
    push!(ctx.passes, ResolveDependency())
    push!(ctx.passes, CatchDuplicatedAnonymousTags())
    push!(ctx.passes, CodegenPreprocessing())

    general_options = get(options, "general", Dict())
    if get(general_options, "smart_de_anonymize", true)
        push!(ctx.passes, DeAnonymize())
    end
    push!(ctx.passes, Audit())
    push!(ctx.passes, Codegen())
    push!(ctx.passes, CodegenMacro())
    # push!(ctx.passes, CodegenPostprocessing())
    if get(general_options, "auto_mutability", false)
        push!(ctx.passes, TweakMutability())
    end

    # support old behavior
    api_file = get(general_options, "output_api_file_path", "")
    common_file = get(general_options, "output_common_file_path", "")

    output_file_path = get(general_options, "output_file_path", "")
    if isempty(api_file) && isempty(common_file)
        if !isempty(output_file_path)
            push!(ctx.passes, ProloguePrinter(output_file_path))
            push!(ctx.passes, GeneralPrinter(output_file_path))
            push!(ctx.passes, EpiloguePrinter(output_file_path))
        else
            # print to stdout if there is no `output_file_path`
            # this is handy when playing in REPL
            push!(ctx.passes, StdPrinter())
        end
    else
        # TODO: impl
    end

    return ctx
end

create_context(header::AbstractString, args=String[], ops=Dict()) = create_context([header], args, ops)

@enum BuildStage begin
    BUILDSTAGE_ALL
    BUILDSTAGE_NO_PRINTING
    BUILDSTAGE_PRINTING_ONLY
end

"""
    build!(ctx::Context, skip_printing = true)
Run all passes.
"""
function build!(ctx::Context, stage=BUILDSTAGE_ALL)
    reset_counter()
    for pass in ctx.passes
        pass isa LinkTypedefToAnonymousTagType && @info "Building the DAG..."
        pass isa Codegen && @info "Emit Julia expressions..."
        if stage == BUILDSTAGE_NO_PRINTING
            pass isa AbstractPrinter && continue
        elseif stage == BUILDSTAGE_PRINTING_ONLY
            !(pass isa AbstractPrinter) && continue
        end
        pass(ctx.dag, ctx.options)
    end
    @info "Done!"
    return ctx
end

"""
    get_identifier_node(ctx::AbstractContext, s::Symbol)
Return an identifer node that has `s` as its node id.
"""
function get_identifier_node(ctx::AbstractContext, s::Symbol)
    if haskey(ctx.dag.ids, s)
        return ctx.dag.nodes[ctx.dag.ids[s]]
    else
        return nothing
    end
end

"""
    get_tagtype_node(ctx::AbstractContext, s::Symbol)
Return a tag-type node that has `s` as its node id.
"""
function get_tagtype_node(ctx::AbstractContext, s::Symbol)
    if haskey(ctx.dag.tags, s)
        return ctx.dag.nodes[ctx.dag.tags[s]]
    else
        return nothing
    end
end

# FIXME: find a more robust way to do this.
function get_triple()
    @static if Sys.isapple()
        return "x86_64-apple-darwin14"
    elseif Sys.isbsd()
        return "x86_64-unknown-freebsd11.1"
    elseif Sys.iswindows() && Sys.WORD_SIZE == 64
        return "x86_64-w64-mingw32"
    elseif Sys.iswindows() && Sys.WORD_SIZE == 32
        return "i686-w64-mingw32"
    elseif Sys.islinux() && Sys.WORD_SIZE == 64
        return "x86_64-linux-gnu"
    elseif Sys.islinux() && Sys.WORD_SIZE == 32
        return "i686-linux-gnu"
    else
        return "aarch64-linux-gnu"
    end
end

function get_default_args(triple=get_triple())
    args = ["-isystem"*dir for dir in get_system_dirs(triple)]
    target = triple2target(triple)
    push!(args, "--target=$target")
    return args
end

"""
    detect_headers(include_dir, args, options::Dict=Dict())
Detect a set of headers which can span the whole directory.
"""
function detect_headers(include_dir, args, options::Dict=Dict())
    system_dirs = filter(x->startswith(x, "-isystem"), args)
    system_dirs = map(x->x[9:end], system_dirs)

    candidates = Set{String}()
    dependencies = Set{String}()
    idx = Index(false)
    flags = CXTranslationUnit_DetailedPreprocessingRecord
    flags |= CXTranslationUnit_SkipFunctionBodies
    for (root, dirs, files) in walkdir(normpath(include_dir))
        for file in files
            header = joinpath(root, file)
            try
                parse_header(idx, header, args, flags)
            catch err
                @info "failed to parse $header, skip..."
                continue
            end
            push!(candidates, header)
            tu = parse_header(idx, header, args, flags)
            GC.@preserve tu begin
                tu_cursor = getTranslationUnitCursor(tu)
                header_name = spelling(tu_cursor)
                header_dir = dirname(header_name)
                @assert startswith(header_dir, include_dir)
                for cursor in children(tu_cursor)
                    is_inclusion_directive(cursor) || continue
                    incfile = getIncludedFile(cursor)
                    file_path = get_filename(incfile) |> normpath
                    (isempty(file_path) || !isfile(file_path)) && continue
                    # skip system headers
                    any(sysdir->startswith(file_path, sysdir), system_dirs) && continue
                    push!(dependencies, file_path)
                end
            end
        end
    end
    return collect(setdiff(candidates, dependencies))
end
