using Clang.cindex
using Base.Test

top = cindex.parse_header("cxx/cbasic.h",
                          flags = TranslationUnit_Flags.DetailedPreprocessingRecord |
                          TranslationUnit_Flags.SkipFunctionBodies)

# Tokenizer

CONST = tokenize(cindex.search(
                    top,
                    x-> (isa(x, cindex.MacroDefinition) && name(x) == "CONST") )[1])
CONSTADD = tokenize(cindex.search(
                    top,
                    x-> (isa(x, cindex.MacroDefinition) && name(x) == "CONSTADD"))[1])

@test (typeof(CONST[1]) == cindex.Identifier && typeof(CONST[2]) == cindex.Literal)
@test (CONSTADD[1].text == "CONSTADD" && CONSTADD[2].text == "CONST" &&
       CONSTADD[3].text == "+" && CONSTADD[4].text == "2")
 
# Function arguments

func1 = cindex.search(top, "func1")[1]
@test cindex.getNumArgTypes(cu_type(func1)) == 4
func1_args = cindex.function_args(func1)
@test map(spelling, func1_args) == ASCIIString["a","b","c","d"]
