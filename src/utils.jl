"""
Reserved Julia identifiers will be prepended with "_"
"""
const RESERVED_WORDS = ["begin", "while", "if", "for", "try", "return", "break", "continue",
                        "function", "macro", "quote", "let", "local", "global", "const", "do",
                        "struct", "module", "baremodule", "using", "import", "export", "end",
                        "else", "elseif", "catch", "finally", "true", "false"]

"""
    name_safe(name::AbstractString)
Return a valid Julia variable name, prefixed with "_" if the `name` is conflict with Julia's
reserved words.
"""
name_safe(name::AbstractString) = (name in RESERVED_WORDS) ? "_"*name : name

"""
    symbol_safe(name::AbstractString)
Same as [`name_safe`](@ref), but return a Symbol.
"""
symbol_safe(name::AbstractString) = Symbol(name_safe(name))

"""
    copydeps(dst)
Copy dependencies to `dst`.
"""
function copydeps(dst)
    cp(joinpath(@__DIR__, "CEnum.jl"), joinpath(dst, "CEnum.jl"), force=true)
    cp(joinpath(@__DIR__, "ctypes.jl"), joinpath(dst, "ctypes.jl"), force=true)
end

function print_template(path, libname="LibXXX")
    open(path, "w") do io
        print(io, """
        module $libname

        import Libdl

        # Load in `deps.jl`, complaining if it does not exist
        const depsjl_path = joinpath(@__DIR__, "..", "deps", "deps.jl")
        if !isfile(depsjl_path)
            error("$libname was not build properly. Please run Pkg.build(\"$libname\").")
        end
        include(depsjl_path)
        # Module initialization function
        function __init__()
            check_deps()
        end

        include("CEnum.jl")
        using .CEnum

        include("ctypes.jl")
        export Ctm, Ctime_t, Cclock_t

        include(joinpath(@__DIR__, "..", "gen", "$(lowercasefirst(libname))_common.jl"))
        include(joinpath(@__DIR__, "..", "gen", "$(lowercasefirst(libname))_api.jl"))

        # export everything
        #foreach(names(@__MODULE__, all=true)) do s
        #    if startswith(string(s), "SOME_PREFIX")
        #        @eval export \$s
        #    end
        #end

        end # module
        """)
    end
end

strip_line_numbers!(arg) = arg

function strip_line_numbers!(ex::Expr)
    keep = trues(length(ex.args))
    for i = 1:length(ex.args)
        if isa(ex.args[i], LineNumberNode)
            keep[i] = false
        end
        isa(ex.args[i], Expr) || continue
        if ex.args[i].head == :line
            keep[i] = false
        else
            ex.args[i] = strip_line_numbers!(ex.args[i])
        end
    end
    ex.args = ex.args[keep]
    ex
end
