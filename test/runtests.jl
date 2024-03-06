import ReTest: retest
import Clang

include("ClangTests.jl")

retest(Clang, ClangTests)
