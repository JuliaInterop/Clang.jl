@static if Sys.isapple() SYSTEM_BREW = "/usr/local/Homebrew/bin/brew" end

#Returns the path as determined by llvm-config, or throws an error if LLVM
#could not be found
function find_llvm()
    @info "Called Clang.jl: find_llvm"
    if haskey(ENV, "TRAVIS")
        tmp = readchomp(Cmd(`which llvm-config-3.9`, ignorestatus=true))
        isfile(tmp) &&
            return tmp

        tmp = readchomp(Cmd(`which llvm-config-39`, ignorestatus=true))
        isfile(tmp) &&
            return tmp
    end

    # TODO improve this
    tmp = joinpath(Sys.BINDIR, "llvm-config")
    isfile(tmp) && return tmp

    #Get path from system llvm-config
    try
        tmp = readchomp(`which llvm-config`)
        isfile(tmp) &&
            return tmp
    catch err
        @info "No system llvm-config: $err"
    end

    # look for system Homebrew
    @static if Sys.isapple()
        try
            @info "Searching for LLVM in system Homebrew"
            if success(`$SYSTEM_BREW ls llvm`)
                llvmcf = filter(x -> occursin("bin/llvm-config", x),
                                chomp.( readlines(`$SYSTEM_BREW ls llvm`) ))
                length(llvmcf) >= 1 &&
                    return llvmcf[1]
            end
            @warn "No llvm or llvm-config found in system homebrew!"
        catch err
            @warn "Error using system Homebrew: $err"
        end

        try
            @info "Attempting install through Homebrew.jl"
            eval(quote
                   using Homebrew
                   if !Homebrew.installed("llvm")
                     Homebrew.add("llvm")
                   end
                   const HOMEBREW_PREFIX = Homebrew.prefix()
                 end)
            lcf = joinpath(HOMEBREW_PREFIX, "opt/llvm/bin/llvm-config")
            isfile(lcf) && return lcf
        catch err
            @warn "Error installing through Homebrew.jl: $err"
        end
    end

    error("No useable llvm-config found")
end

if !haskey(ENV, "LLVM_CONFIG")
    ENV["LLVM_CONFIG"] = find_llvm()
end

open(joinpath(dirname(@__FILE__), "deps.jl"), "w") do f
    LLVM_CONFIG = ENV["LLVM_CONFIG"]
    write(f, "LLVM_CONFIG=\"$(LLVM_CONFIG)\"")
end
