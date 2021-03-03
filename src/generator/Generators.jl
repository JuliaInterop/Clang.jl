module Generators

using TOML

using ..Clang
using ..Clang.LibClang
using ..Clang:
    isBitField,
    isCursorDefinition,
    isMacroBuiltin,
    isMacroFunctionLike,
    isVariadic,
    getAlignOf,
    getArgType,
    getCursorType,
    getCanonicalType,
    getCursorResultType,
    getElementType,
    getEnumDeclIntegerType,
    getIncludedFile,
    getNamedType,
    getNumElements,
    getOffsetOf,
    getPointeeType,
    getSizeOf,
    getTranslationUnit,
    getTranslationUnitCursor,
    getTypedefDeclUnderlyingType,
    getTypeDeclaration,
    hasAttrs

include("utils.jl")

include("jltypes.jl")
export AbstractJuliaType, AbstractJuliaSIT, AbstractJuliaSDT
export tojulia

include("definitions.jl")
export get_definition
export add_definition
export @add_def

include("types.jl")
export AbstractExprNodeType
export AbstractFunctionNodeType, AbstractTypedefNodeType, AbstractMacroNodeType
export AbstractStructNodeType, AbstractUnionNodeType, AbstractEnumNodeType
export ExprNode, ExprDAG
export get_nodes, get_exprs

include("top_level.jl")
include("nested.jl")
include("resolve_deps.jl")
include("preprocessing.jl")

include("translate.jl")
export translate

include("codegen.jl")
export emit!

include("print.jl")
export pretty_print

include("audit.jl")
export report_default_tag_types

include("macro.jl")

include("passes.jl")
export AbstractPass
export Audit
export CatchDuplicatedAnonymousTags
export Codegen
export CodegenMacro
export CodegenPostprocessing
export CodegenPreprocessing
export CollectNestedRecord
export CollectTopLevelNode
export CommonPrinter
export DeAnonymize
export EpiloguePrinter
export FindOpaques
export FunctionPrinter
export GeneralPrinter
export IndexDefinition
export LinkTypedefToAnonymousTagType
export ProloguePrinter
export RemoveCircularReference
export ResolveDependency
export StdPrinter
export TopologicalSort

include("context.jl")
export AbstractContext, Context
export parse_header!, parse_headers!
export create_context
export build!, BUILDSTAGE_ALL, BUILDSTAGE_NO_PRINTING, BUILDSTAGE_PRINTING_ONLY
export find_std_headers, find_dependent_headers
export get_identifier_node, get_tagtype_node

load_options(path::AbstractString) = TOML.parse(read(path, String))
export load_options


function __init__()
   reset_definition()
end

end # module
