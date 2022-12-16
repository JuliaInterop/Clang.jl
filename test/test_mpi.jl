using Clang.Generators

@testset "MPI.jl" begin
    @info "Testing generator for JuliaParallel/MPI.jl"
    args = get_default_args()
    headers = joinpath(@__DIR__, "mpi", "mpi.h")
    options = load_options(joinpath(@__DIR__, "mpi", "generator.toml"))
    options["general"]["callback_documentation"] = node -> String["Fancy MPI doc for $(node.id) generated by Clang.jl"]
    ctx = create_context(headers, args, options)
    build!(ctx)

    @info "Testing correctness of the MPI generated files"
    content = read("mpi_api.jl", String)

    # excluded by pattern in `output_ignorelist` of `generator.toml`
    @test !occursin("PMPI_Barrier", content)

    # wrong prototypes, see github.com/JuliaParallel/MPI.jl/issues/688
    @test occursin("MPI_Type_copy_attr_function", content)
    @test occursin("MPI_Type_delete_attr_function", content)

    # custom documentaton callback
    @test occursin("Fancy MPI doc for MPI_Barrier generated by Clang.jl", content)

    @info "Cleanup auto-generated files"
    rm("mpi_common.jl")
    rm("mpi_api.jl")
end
