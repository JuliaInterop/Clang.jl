import ReTest: retest
import Clang

# Temporary hack to make @doc work in 1.11 for the documentation tests. See:
# https://github.com/JuliaLang/julia/issues/54664
using REPL

include("ClangTests.jl")

retest(Clang, ClangTests; stats=true, spin=false)
