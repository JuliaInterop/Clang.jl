# InternalOptions
mutable struct InternalOptions
    wrap_structs::Bool
    ismutable::Bool
end
InternalOptions() = InternalOptions(true, false)

"""
    WrapContext
Store shared information about the wrapping session.
"""
mutable struct WrapContext
    index::Index
    headers::Vector{String}
    output_file::String
    common_file::String
    clang_includes::Vector{String}               # clang include paths
    clang_args::Vector{String}                   # additional {"-Arg", "value"} pairs for clang
    header_library::Function                     # called to determine shared library for given header
    common_buf::OrderedDict{Symbol, ExprUnit}    # output buffer for common items: typedefs, enums, etc.
    output_bufs::DefaultOrderedDict{String, Array{Any}}
    options::InternalOptions
    rewriter::Function
end

### Convenience function to initialize wrapping context with defaults
function init(; headers::Vector{String}                    = String[],
                index::Union{Index,Nothing}                = nothing,
                output_dir::String                         = "",
                output_file::String                        = "",
                common_file::String                        = "",
                clang_args::Vector{String}                 = String[],
                clang_includes::Vector{String}             = String[],
                clang_diagnostics::Bool                    = true,
                header_library                             = nothing,
                options                                    = InternalOptions(),
                rewriter                                   = x -> x)

    # Set up some optional args if they are not explicitly passed.
    index == nothing && (index = Index(clang_diagnostics);)

    if output_file == ""
        output_file = joinpath(output_dir, strip(splitext(basename(x))[1]) * ".jl")
    end

    if common_file == ""
        common_file = joinpath(output_dir, common_file)
    end

    if header_library == nothing
        header_library = strip(splitext(basename(x))[1])
    elseif isa(header_library, String)
        libname = copy(header_library)
        header_library = x->libname
    end

    # Instantiate and return the WrapContext
    global context = WrapContext(index,
                                 headers,
                                 output_file,
                                 common_file,
                                 clang_includes,
                                 clang_args,
                                 header_library,
                                 OrderedDict{Symbol,ExprUnit}(),
                                 DefaultOrderedDict{String, Array{Any}}(()->Any[]),
                                 options,
                                 rewriter)
    return context
end

function Base.run(wc::WrapContext, generate_template=true)
    # parse headers
    ctx = DefaultContext(wc.index)
    parse_headers!(ctx, wc.headers, args=wc.clang_args, includes=wc.clang_includes)
    ctx.options["is_function_strictly_typed"] = false
    # Helper to store file handles
    filehandles = Dict{String,IOStream}()
    getfile(f) = (f in keys(filehandles)) ? filehandles[f] : (filehandles[f] = open(f, "w"))

    # First pass on the AST, add declarations to be translated to the queue.
    # Declarations to be translated include:
    # - enumerations
    # - structures
    # - unions
    # - functions
    # and consists only in declarations from selected headers.
    # Types on which these declarations depend (e.g. parameters and return types of functions,
    # types of fields in structures) will be added to the queue during the traversal.
    for trans_unit in ctx.trans_units
        root_cursor = getcursor(trans_unit)
        header = spelling(root_cursor)

        root_children = children(root_cursor)
        for (i, child) in enumerate(root_children)

            # Save next cursor.
            ctx.next_cursor[child] = length(root_children) < i+1 ? nothing : root_children[i+1]

            child_kind = kind(child)
            child_name = name(child)
            child_header = filename(child)

            # Skip irrelevant cursors.
            if child in ctx.visited || # already added to the queue
                (is_forward_declaration(child) && child_kind != CXCursor_FunctionDecl) || # forward type declaration
                startswith(child_name, "__") || # compiler definitions
                child_header != header || # cursors from other headers
                (child_kind != CXCursor_EnumDecl &&
                 child_kind !=  CXCursor_StructDecl &&
                 child_kind != CXCursor_UnionDecl &&
                 child_kind != CXCursor_EnumConstantDecl &&
                 child_kind != CXCursor_FunctionDecl)
                continue
            end

            enqueue!(ctx.queue, child)
            push!(ctx.visited, child)
        end
    end

    # Wrap all cursors until the queue is empty.
    # For each declaration wrapped, other declarations on which it depends will be added to the queue.
    while !isempty(ctx.queue)
        cursor = dequeue!(ctx.queue)
        ctx.libname = wc.header_library(filename(cursor))
        try
            wrap!(ctx, cursor)
        catch err
            @error "error thrown."
            rethrow(err)
        end
    end

    # apply user-supplied transformation
    ctx.api_buffer = wc.rewriter(ctx.api_buffer)

    # write output
    out_file = wc.output_file
    @info "writing $(out_file)"

    out_stream = getfile(out_file)
    println(out_stream, "# Julia wrapper automatically generated using Clang.jl\n")
    print_buffer(out_stream, ctx.api_buffer)
    ctx.api_buffer = Expr[]  # clean api_buffer for the next header

    common_buf = dump_to_buffer(ctx.common_buffer)

    # apply user-supplied transformation
    common_buf = wc.rewriter(common_buf)

    # write "common" definitions: types, typealiases, etc.
    open(wc.common_file, "w") do f
        println(f, "# Automatically generated using Clang.jl\n")
        print_buffer(f, common_buf)
    end

    map(close, values(filehandles))

    if generate_template
        copydeps(dirname(wc.common_file))
        print_template(joinpath(dirname(wc.common_file), "LibTemplate.jl"))
    end
end
