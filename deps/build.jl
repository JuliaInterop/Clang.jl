using BinDeps

cd(joinpath(Pkg.dir(), "Clang", "deps", "src") )
run(`make`)
if (!ispath("../usr")) 
  run(`mkdir ../usr`)
end
if (!ispath("../usr/lib")) 
  run(`mkdir ../usr/lib`)
end
run(`mv libwrapclang.$(BinDeps.shlib_ext) ../usr/lib`)
