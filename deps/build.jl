find_llvm() = begin
    if haskey(ENV, "TRAVIS")
        return readchomp(`which llvm-config-3.3`)
    end
    tmp = joinpath(JULIA_HOME, "llvm-config")
    isfile(tmp) && return tmp
    tmp = readchomp(`which llvm-config`)
    isfile(tmp) && return tmp
end
if !haskey(ENV, "LLVM_CONFIG") ENV["LLVM_CONFIG"] = find_llvm() end

# on travis and some other systems, the llvm lib may not be in the
# default path.
push!(DL_LOAD_PATH, readchomp(`$(ENV["LLVM_CONFIG"]) --libdir`))

cd(joinpath(Pkg.dir(), "Clang", "deps", "src") )
run(`make`)
if (!ispath("../usr")) 
  run(`mkdir ../usr`)
end
if (!ispath("../usr/lib")) 
  run(`mkdir ../usr/lib`)
end

run(`mv libwrapclang.$(Base.Sys.shlib_ext) ../usr/lib`)
