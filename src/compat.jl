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
    header_wrapped::Function                     # called to determine header inclusion status
                                                 #   (top_header, cursor_header) -> Bool
    header_library::Function                     # called to determine shared library for given header
                                                 #   (header_name) -> library_name::AbstractString
    header_outputfile::Function                  # called to determine output file group for given header
                                                 #   (header_name) -> output_file::AbstractString
    cursor_wrapped::Function                     # called to determine cursor inclusion status
                                                 #   (cursor_name, cursor) -> Bool
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
                header_wrapped                             = (header, cursorname) -> true,
                header_library                             = nothing,
                header_outputfile::Union{Function,Nothing} = nothing,
                cursor_wrapped                             = (cursorname, cursor) -> true,
                options                                    = InternalOptions(),
                rewriter                                   = x -> x)

    # Set up some optional args if they are not explicitly passed.
    index == nothing && (index = Index(clang_diagnostics);)

    if output_file == "" && header_outputfile == nothing
        header_outputfile = x->joinpath(output_dir, strip(splitext(basename(x))[1]) * ".jl")
    end

    common_file == "" && (common_file = output_file;)
    common_file = joinpath(output_dir, common_file)

    if header_library == nothing
        header_library = x->strip(splitext(basename(x))[1])
    elseif isa(header_library, String)
        libname = copy(header_library)
        header_library = x->libname
    end
    if header_outputfile == nothing
        header_outputfile = x->joinpath(output_dir, output_file)
    end

    # Instantiate and return the WrapContext
    global context = WrapContext(index,
                                 headers,
                                 output_file,
                                 common_file,
                                 clang_includes,
                                 clang_args,
                                 header_wrapped,
                                 header_library,
                                 header_outputfile,
                                 cursor_wrapped,
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
    ctx.options["is_struct_mutable"] = wc.options.ismutable
    # Helper to store file handles
    filehandles = Dict{String,IOStream}()
    getfile(f) = (f in keys(filehandles)) ? filehandles[f] : (filehandles[f] = open(f, "w"))

    for trans_unit in ctx.trans_units
        root_cursor = getcursor(trans_unit)
        push!(ctx.cursor_stack, root_cursor)
        header = spelling(root_cursor)
        @info "wrapping header: $header ..."

        # loop over all of the child cursors and wrap them, if appropriate.
        ctx.children = children(root_cursor)
        for (i, child) in enumerate(ctx.children)
            child_name = name(child)
            child_header = filename(child)
            ctx.children_index = i
            # what should be wrapped:
            #   1. wrap if context.header_wrapped(header, child_header) == True
            #   2. wrap if context.cursor_wrapped(cursor_name, cursor) == True
            #   3. skip compiler defs and cursors already wrapped
            if !wc.header_wrapped(header, child_header) ||
               !wc.cursor_wrapped(child_name, child) ||       # client callbacks
               startswith(child_name, "__")          ||       # skip compiler definitions
               child_name in keys(ctx.common_buffer)          # already wrapped
                continue
            end
            ctx.libname = wc.header_library(child_header)

            try
                wrap!(ctx, child)
            catch err
                push!(ctx.cursor_stack, child)
                @error "error thrown. Last cursor available in context.cursor_stack."
                rethrow(err)
            end
        end

        # apply user-supplied transformation
        ctx.api_buffer = wc.rewriter(ctx.api_buffer)

        # write output
        out_file = wc.header_outputfile(header)
        @info "writing $(out_file)"

        out_stream = getfile(out_file)
        println(out_stream, "# Julia wrapper for header: $(basename(header))")
        println(out_stream, "# Automatically generated using Clang.jl\n")
        print_buffer(out_stream, ctx.api_buffer)
        ctx.api_buffer = Expr[]  # clean api_buffer for the next header
    end

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
