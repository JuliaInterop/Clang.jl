#Returns the path as determined by llvm-config, or throws an error if LLVM
#could not be found
function find_llvm()
    if haskey(ENV, "TRAVIS")
        return readchomp(`which llvm-config-3.4`)
    end
    tmp = joinpath(JULIA_HOME, "llvm-config")
    isfile(tmp) && return tmp
    #Get path from llvm-config
    try
        tmp = readchomp(`which llvm-config`)
    end
    isfile(tmp) && return tmp
    error("No useable llvm-config found")
end

#On OSX, install llvm automatically through Homebrew.jl if no llvm installation
#is found
@static if is_apple()
    using Homebrew

    try
        find_llvm()
    catch #Not installed on system
        info("Installing llvm through Homebrew.jl")
        if !Homebrew.installed("llvm")
            Homebrew.add("llvm")
        end
    end
end

if !haskey(ENV, "LLVM_CONFIG")
    ENV["LLVM_CONFIG"] = find_llvm()
end

# on travis and some other systems, the llvm lib may not be in the
# default path.
push!(Libdl.DL_LOAD_PATH, readchomp(`$(ENV["LLVM_CONFIG"]) --libdir`))

cd(joinpath(dirname(@__FILE__), "src"))
try
    run(`make`)
catch
    has_build_clang_flag=false
    julia_make_user = joinpath(JULIA_HOME, "..", "..", "Make.user")

    if isfile(julia_make_user)
        open(julia_make_user) do f
            for l in eachline(f)
                if startswith(l, "BUILD_LLVM_CLANG=1")
                    has_build_clang_flag = true
                    break
                end
            end
        end
    end

    if !has_build_clang_flag
        error("""clang headers could not be found and BUILD_LLVM_CLANG=1 not specified in Make.user
Try setting BUILD_LLVM_CLANG=1 in Make.user in $JULIA_HOME and try again.""")
    else
        exit()
    end
end

if (!ispath("../usr"))
    run(`mkdir ../usr`)
end
if (!ispath("../usr/lib"))
    run(`mkdir ../usr/lib`)
end

run(`mv libwrapclang.$(Libdl.dlext) ../usr/lib`)
