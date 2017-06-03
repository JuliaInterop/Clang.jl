@static if is_apple() SYSTEM_BREW = "/usr/local/Homebrew/bin/brew" end

#Returns the path as determined by llvm-config, or throws an error if LLVM
#could not be found
function find_llvm()
    info("Called Clang.jl:find_llvm")
    if haskey(ENV, "TRAVIS")
        tmp = readchomp(Cmd(`which llvm-config-3.9`, ignorestatus=true))
        isfile(tmp) &&
            return tmp

        tmp = readchomp(Cmd(`which llvm-config-39`, ignorestatus=true))
        isfile(tmp) &&
            return tmp
    end

    # TODO improve this
    tmp = joinpath(JULIA_HOME, "llvm-config")
    isfile(tmp) && return tmp

    #Get path from system llvm-config
    try
        tmp = readchomp(`which llvm-config`)
        isfile(tmp) &&
            return tmp
    catch err
        info("No system llvm-config: ")
        info(err)
    end

    # look for system Homebrew
    @static if is_apple()
        try
            info("Searching for LLVM in system Homebrew")
            if success(`$SYSTEM_BREW ls llvm`)
                llvmcf = filter(x -> contains(x, "bin/llvm-config"),
                                chomp.( readlines(`$SYSTEM_BREW ls llvm`) ))
                length(llvmcf) >= 1 &&
                    return llvmcf[1]
            end
            warn("No llvm or llvm-config found in system homebrew!")
        catch err
            warn("Error using system Homebrew: ", err)
        end

        try
            info("Attempting install through Homebrew.jl")
            eval(quote
                   using Homebrew
                   if !Homebrew.installed("llvm")
                     Homebrew.add("llvm")
                   end
                 end)
            if (lcf = isfile(joinpath(prefix, "llvm-config")))
                return lcf
            end
        end
    end

    error("No useable llvm-config found")
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
open(Pkg.dir("Clang", "deps", "deps.jl"), "w") do f
    LLVM_CONFIG = ENV["LLVM_CONFIG"]
    write(f, "LLVM_CONFIG=\"$(LLVM_CONFIG)\"")
    write(f, "LIBCLANG=\"$(LIBCLANG)\"")
end
