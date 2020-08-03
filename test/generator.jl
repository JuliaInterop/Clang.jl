using Clang
using Test

# LIBCLANG_HEADERS are those headers to be wrapped.
const LIBCLANG_INCLUDE = joinpath(dirname(Clang.LibClang.Clang_jll.libclang_path), "..", "include", "clang-c") |> normpath
const LIBCLANG_HEADERS = [joinpath(LIBCLANG_INCLUDE, header) for header in readdir(LIBCLANG_INCLUDE) if endswith(header, ".h")]

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
        wrap!(ctx, child)
    end
    @info "writing $(api_file)"
    println(api_stream, "# Julia wrapper for header: $(basename(header))")
    println(api_stream, "# Automatically generated using Clang.jl\n")
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

@testset "generator" begin
    api_path = joinpath(@__DIR__, "libclang_api.jl")
    common_path = joinpath(@__DIR__, "libclang_common.jl")
    test_api_path = joinpath(@__DIR__, "test_api.jl")
    test_common_path = joinpath(@__DIR__, "test_common.jl")
    wc = init(; headers = LIBCLANG_HEADERS,
                output_file = test_api_path,
                common_file = test_common_path,
                clang_includes = vcat(LIBCLANG_INCLUDE, CLANG_INCLUDE),
                clang_args = ["-I", joinpath(LIBCLANG_INCLUDE, ".."), map(x->"-I"*x, find_std_headers())...],
                header_wrapped = (root, current)->root == current,
                header_library = x->"libclang",
                clang_diagnostics = true)
    run(wc, false)
    @test read(test_api_path, String) == read(api_path, String)
    @test read(test_common_path, String) == read(common_path, String)
end
