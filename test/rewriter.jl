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
