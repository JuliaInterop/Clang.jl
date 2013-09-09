using Clang.cindex
using Base.Test

top = cindex.parse("cxx/cbasic.h")

###############################################################################
# Test tokenizer interface


CONST = tokenize(cindex.search(
                    top,
                    x-> (isa(x, cindex.MacroDefinition) && name(x) == "CONST"))[1])
CONSTADD = tokenize(cindex.search(
                    top,
                    x-> (isa(x, cindex.MacroDefinition) && name(x) == "CONSTADD"))[1])

@test (typeof(CONST[1]) == cindex.Identifier && typeof(CONST[2]) == cindex.Literal)
@test (CONSTADD[1].text == "CONSTADD" && CONSTADD[2].text == "CONST" &&
       CONSTADD[3].text == "+" && CONSTADD[4].text == "2") 
