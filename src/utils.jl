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


## dumpobj
printind(ind::Int, st...) = println(join([repeat(" ", 2*ind), st...]))

dumpobj(cursor::CLCursor) = dumpobj(0, cursor)
dumpobj(t::CLType) = join(typeof(t), " ", spelling(t))
dumpobj(t::CLInt) = t
dumpobj(t::CLPointer) = pointee_type(t)
dumpobj(ind::Int, t::CLType) = printind(ind, dumpobj(t))

function dumpobj(ind::Int, cursor::Union{CLFieldDecl, CLParmDecl})
    printind(ind+1, typeof(cursor), " ", dumpobj(type(cursor)), " ", name(cursor))
end

function dumpobj(ind::Int, node::Union{CLCursor,CLStructDecl,CLCompoundStmt,CLFunctionDecl,CLBinaryOperator})
    printind(ind, " ", typeof(node), " ", name(node))
    for c in children(node)
        dumpobj(ind + 1, c)
    end
end


"""
    copydeps(dst)
Copy dependencies to `dst`.
"""
function copydeps(dst)
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
            error("$libname was not build properly. Please run Pkg.build(\\"$libname\\").")
        end
        include(depsjl_path)
        # Module initialization function
        function __init__()
            check_deps()
        end

        using CEnum

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

function find_std_headers()
    headers = String[]
    @static if Sys.isapple()
        cmd_path = strip(read(`xcode-select --print-path`, String))
        sdk_path = joinpath(cmd_path, "SDKs", "MacOSX.sdk")
        xcode_path = cmd_path
        occursin("Xcode", xcode_path) && (xcode_path *= "/Toolchains/XcodeDefault.xctoolchain/")
        didfind = false
        lib = joinpath(xcode_path, "usr", "lib", "c++", "v1")
        inc = joinpath(xcode_path, "usr", "include", "c++", "v1")
        isdir(lib) && (push!(headers, lib); didfind = true;)
        isdir(inc) && (push!(headers, inc); didfind = true;)
        if isdir("/usr/include")
            push!(headers, "/usr/include")
        else isdir(joinpath(sdk_path, "usr", "include"))
            push!(headers, joinpath(sdk_path, "usr", "include"))
        end
        didfind || error("Could not find C++ standard library. Is XCode or CommandLineTools installed?")
    end
    return headers
end
