using Clang.Generators
using Clang.LibClang.Clang_jll

cd(@__DIR__)

options = load_options(joinpath(@__DIR__, "generator.toml"))

# add extra definition
@add_def time_t AbstractJuliaSIT JuliaCtime_t Ctime_t

# custom rewriter
function rewrite!(e::Expr)
    Meta.isexpr(e, :function) || return e
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
    return e
end

function rewrite!(dag::ExprDAG)
    for node in get_nodes(dag)
        for expr in get_exprs(node)
            rewrite!(expr)
        end
    end
end

import Pkg
import BinaryBuilderBase: PkgSpec, Prefix, temp_prefix, setup_dependencies, cleanup_dependencies, destdir

const dependencies = PkgSpec[PkgSpec(; name = "Clang_jll")]

const libdir = joinpath(@__DIR__, "..", "lib")

for (llvm_version, julia_version) in (#=(v"12.0.1", v"1.7"),=#
                                      (v"13.0.1", v"1.8"),
                                      (v"14.0.5", v"1.9"))
    @info "Generating..." llvm_version julia_version
    temp_prefix() do prefix
    # let prefix = Prefix(mktempdir())
        platform = Pkg.BinaryPlatforms.HostPlatform()
        platform["llvm_version"] = string(llvm_version.major)
        platform["julia_version"] = string(julia_version)
        artifact_paths = setup_dependencies(prefix, dependencies, platform; verbose=true)

        let options = deepcopy(options)
            output_file_path = joinpath(libdir, string(llvm_version.major), options["general"]["output_file_path"])
            isdir(dirname(output_file_path)) || mkpath(dirname(output_file_path))
            options["general"]["output_file_path"] = output_file_path

            include_dir = joinpath(destdir(prefix, platform), "include")
            @show include_dir
            libclang_include_dir = joinpath(include_dir, "clang-c")
            args = Generators.get_default_args()
            push!(args, "-I$libclang_include_dir")

            headers = detect_headers(libclang_include_dir, args)
            ctx = create_context(headers, args, options)

            # build without printing so we can do custom rewriting
            build!(ctx, BUILDSTAGE_NO_PRINTING)

            rewrite!(ctx.dag)

            # print
            build!(ctx, BUILDSTAGE_PRINTING_ONLY)
        end

        cleanup_dependencies(prefix, artifact_paths, platform)
    end
end
