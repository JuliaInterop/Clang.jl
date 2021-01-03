abstract type AbstractContext end

mutable struct Context <: AbstractContext
    index::Index
    trans_units::Vector{TranslationUnit}
    passes::Vector{AbstractPass}
    dag::ExprDAG
    options::Dict
end
function Context(options; index=Index(true), tus=[], passes=[], dag=ExprDAG(ExprNode[]))
    return Context(index, tus, passes, dag, options)
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

function find_std_headers()
    headers = String[]
    @static if Sys.isapple()
        xcode_path = strip(read(`xcode-select --print-path`, String))
        sdk_path = strip(read(`xcrun --show-sdk-path`, String))
        occursin("Xcode", xcode_path) &&
            (xcode_path *= "/Toolchains/XcodeDefault.xctoolchain/")
        didfind = false
        lib = joinpath(xcode_path, "usr", "lib", "c++", "v1")
        inc = joinpath(xcode_path, "usr", "include", "c++", "v1")
        isdir(lib) && (push!(headers, lib); didfind = true)
        isdir(inc) && (push!(headers, inc); didfind = true)
        if isdir("/usr/include")
            push!(headers, "/usr/include")
        else
            isdir(joinpath(sdk_path, "usr", "include"))
            push!(headers, joinpath(sdk_path, "usr", "include"))
        end
        didfind ||
            error("Could not find C++ standard library. Is XCode or CommandLineTools installed?")
    end
    return headers
end

"""
    create_context(headers::Vector, args::Vector, options::Dict)
Create a context from a vector of paths of headers, a vector of compiler flags and
a option dict.
"""
function create_context(headers::Vector, args::Vector, options::Dict)
    ctx = Context(options)

    general_options = get(options, "general", Dict())
    if get(general_options, "auto_detect_system_headers", true)
        sys_headers = map(x->"-I"*x, find_std_headers())
        args = vcat(sys_headers, args)
    end
    parse_headers!(ctx, headers, args)

    push!(ctx.passes, CollectTopLevelNode(ctx.trans_units))
    push!(ctx.passes, LinkTypedefToAnonymousTagType())
    push!(ctx.passes, IndexDefinition())
    push!(ctx.passes, ResolveDependency())
    push!(ctx.passes, RemoveCircularReference())
    push!(ctx.passes, TopologicalSort())
    push!(ctx.passes, IndexDefinition())
    push!(ctx.passes, ResolveDependency())
    push!(ctx.passes, CodegenPreprocessing())
    if get(general_options, "smart_de_anonymize", true)
        push!(ctx.passes, DeAnonymize())
    end
    push!(ctx.passes, Audit())
    push!(ctx.passes, Codegen())
    push!(ctx.passes, CodegenPostprocessing())

    # support old behavior
    api_file = get(general_options, "output_api_file_path", "")
    common_file = get(general_options, "output_common_file_path", "")

    output_file_path = get(general_options, "output_file_path", "")
    @assert !isempty(output_file_path) "output file path is empty, please set `output_file_path` in the toml file."
    if isempty(api_file) && isempty(common_file)
        push!(ctx.passes, ProloguePrinter(output_file_path))
        push!(ctx.passes, GeneralPrinter(output_file_path))
        push!(ctx.passes, EpiloguePrinter(output_file_path))
    else
        # TODO: impl
    end

    return ctx
end

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
    for pass in ctx.passes
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
