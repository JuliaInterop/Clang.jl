using Clang.Generators
using Clang.LibClang.Clang_jll

cd(@__DIR__)

const INCLUDE_DIR = normpath(Clang_jll.artifact_dir, "include")
const CLANG_C_DIR = joinpath(INCLUDE_DIR, "clang-c")

options = load_options(joinpath(@__DIR__, "generator.toml"))

# add compiler flags
args = get_default_args()
push!(args, "-I$INCLUDE_DIR")

headers = detect_headers(CLANG_C_DIR, args)

# add extra definition
@add_def time_t AbstractJuliaSIT JuliaCtime_t Ctime_t

# create context
ctx = create_context(headers, args, options)

# build without printing so we can do custom rewriting
build!(ctx, BUILDSTAGE_NO_PRINTING)

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

rewrite!(ctx.dag)

# print
build!(ctx, BUILDSTAGE_PRINTING_ONLY)
