using Clang

const LIBCLANG_INCLUDE = joinpath(@__DIR__, "..", "deps", "usr", "include", "clang-c") |> normpath
const LIBCLANG_HEADERS = [joinpath(LIBCLANG_INCLUDE, header) for header in readdir(LIBCLANG_INCLUDE) if endswith(header, ".h")]


function rewrite!(e::Expr)
    # Add deprecated warning to some functions
    #   ref: [Remove unused CompilationDatabase::MappedSources](https://reviews.llvm.org/D32351)
    fname = e.args[1].args[1]
    deprecated_func = [
        # :clang_CompileCommand_getNumMappedSources, # not export
        :clang_CompileCommand_getMappedSourcePath,
        :clang_CompileCommand_getMappedSourceContent,
    ]
    
    if e.head == :function && fname in deprecated_func
        msg = """
        `$fname` Left here for backward compatibility.
        No mapped sources exists in the C++ backend anymore.
        This function just return Null `CXString`.
        
        See:
        - [Remove unused CompilationDatabase::MappedSources](https://reviews.llvm.org/D32351)
        """
        insert!(e.args[2].args, 1, Expr(:macrocall, Symbol("@warn"), :Base, msg))
    end
    e
end
rewrite!(x) = x
rewrite(v::Vector) = map(rewrite!, v)

# create a work context
ctx = DefaultContext()

# parse headers
parse_headers!(ctx, LIBCLANG_HEADERS,
               args=["-I", joinpath(LIBCLANG_INCLUDE, ".."), map(x->"-I"*x, find_std_headers())...],
               includes=vcat(LIBCLANG_INCLUDE, CLANG_INCLUDE),
               )

# settings
ctx.libname = "libclang"
ctx.options["is_function_strictly_typed"] = false
ctx.options["is_struct_mutable"] = false

# write output
api_file = joinpath(@__DIR__, "libclang_api.jl")
api_stream = open(api_file, "w")

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
        # choose which cursor to wrap
        startswith(child_name, "__") && continue  # skip compiler definitions
        child_name in keys(ctx.common_buffer) && continue  # already wrapped
        child_header != header && continue  # skip if cursor filename is not in the headers to be wrapped
        
        # issues#243
        if occursin("clang_CompileCommand_getNumMappedSources", child_name)
            @info "Ignore $child_name, because this function is not export anymore."
            continue
        end

        wrap!(ctx, child)
    end
    @info "writing $(api_file)"
    println(api_stream, "# Julia wrapper for header: $(basename(header))")
    println(api_stream, "# Automatically generated using Clang.jl\n")
    ctx.api_buffer = rewrite(ctx.api_buffer)
    print_buffer(api_stream, ctx.api_buffer)
    empty!(ctx.api_buffer)  # clean up api_buffer for the next header
end
close(api_stream)

# write "common" definitions: types, typealiases, etc.
common_file = joinpath(@__DIR__, "libclang_common.jl")
open(common_file, "w") do f
    println(f, "# Automatically generated using Clang.jl\n")
    print_buffer(f, dump_to_buffer(ctx.common_buffer))
end

# uncomment the following code to generate dependency and template files
# copydeps(dirname(api_file))
# print_template(joinpath(dirname(api_file), "LibTemplate.jl"))
