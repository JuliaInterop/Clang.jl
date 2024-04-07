abstract type AbstractContext end

Base.@kwdef mutable struct Context <: AbstractContext
    index::Index = Index(true)
    trans_units::Vector{TranslationUnit} = TranslationUnit[]
    passes::Vector{AbstractPass} = AbstractPass[]
    dag::ExprDAG = ExprDAG()
    options::Dict = Dict()
end

Base.show(io::IO, x::Context) = print(io, "Context(...)")

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
                        file_name ∈ dependent_headers && continue
                        file_name ∈ new_headers && continue
                        push!(new_headers, file_name)
                    end
                end
            catch err
                if !endswith(header, ".inc")
                    @warn "failed to parse $header, skip..."
                end
                continue
            end
        end
        isempty(new_headers) && break
        foreach(new_headers) do h
            @info "Found dependent header: $h"
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

    push!(args, "-nostdinc")

    system_dirs = map(x->x[9:end], filter(x->startswith(x, "-isystem"), args))
    dependent_headers = find_dependent_headers(headers, args, system_dirs)

    @info "Parsing headers..."
    parse_headers!(ctx, headers, args)

    push!(ctx.passes, CollectTopLevelNode(ctx.trans_units, dependent_headers, system_dirs))
    push!(ctx.passes, LinkTypedefToAnonymousTagType())
    push!(ctx.passes, LinkTypedefToAnonymousTagType(is_system=true))
    push!(ctx.passes, IndexDefinition())
    push!(ctx.passes, CollectDependentSystemNode())
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
    if get(general_options, "no_audit", false)
        @error "The generator is running in `no_audit` mode. It could generate invalid Julia code. You can remove the `no_audit` entry in the `.toml` file to exit this mode."
        get(general_options, "link_enum_alias", true) && push!(ctx.passes, LinkEnumAlias())
    else
        push!(ctx.passes, Audit())
    end
    push!(ctx.passes, Codegen())
    push!(ctx.passes, CodegenMacro())
    # push!(ctx.passes, CodegenPostprocessing())
    if get(general_options, "add_fptr_methods", false)
        push!(ctx.passes, AddFPtrMethods())
    end
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
        # let the user handle prologue and epilogue on their own
        push!(ctx.passes, FunctionPrinter(api_file))
        push!(ctx.passes, CommonPrinter(common_file))
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
        pass isa CollectDependentSystemNode && stage != BUILDSTAGE_PRINTING_ONLY && @info "Building the DAG..."
        pass isa Codegen && stage != BUILDSTAGE_PRINTING_ONLY && @info "Emit Julia expressions..."
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

function get_triple()
    is_libc_musl = occursin("musl", Base.BUILD_TRIPLET)
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

function get_default_args(triple=get_triple(); is_cxx=false)
    if is_cxx
        env = get_default_env(triple; version=GCC_MIN_VER, is_cxx)
        args = ["-isystem" * dir for dir in get_system_includes(env)]
        clang_inc = joinpath(LLVM_LIBDIR, "clang", string(Base.libllvm_version.major), "include")
        push!(args, "-isystem" * clang_inc)
        push!(args, "--target=$(target(env.platform))")
        return args
    else
        args = ["-isystem"*dir for dir in get_system_dirs(triple)]
        push!(args, "--target=$(triple2target(triple))")
        return args
    end
end

"""
    detect_headers(include_dir, args, options::Dict=Dict(), filter=(header)->false)
Detect a set of headers which can span the whole directory.
Use `filter` to filter out headers you don't want to consider as candidates
"""
function detect_headers(include_dir, args, options::Dict=Dict(), filter_op = (header)->false)
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
            filter_op(header) && continue
            try
                # FIXME: C++ could also be successful parsed, but that's not what we want
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
    return sort!(collect(setdiff(candidates, dependencies)))
end
