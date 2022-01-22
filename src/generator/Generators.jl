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
    getArgument,
    getCursorType,
    getCanonicalType,
    getCursorResultType,
    getElementType,
    getEnumDeclIntegerType,
    getFieldDeclBitWidth,
    getIncludedFile,
    getNamedType,
    getNumArguments,
    getNumElements,
    getOffsetOf,
    getOffsetOfField,
    getPointeeType,
    getSizeOf,
    getTranslationUnit,
    getTranslationUnitCursor,
    getTypedefDeclUnderlyingType,
    getTypeDeclaration,
    hasAttrs

using ..JLLEnvs
using ..JLLEnvs: get_system_dirs, triple2target

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

include("macro.jl")
include("top_level.jl")
include("system_deps.jl")
include("nested.jl")
include("resolve_deps.jl")
include("preprocessing.jl")
include("documentation.jl")

include("translate.jl")
export translate

include("codegen.jl")
export emit!

include("print.jl")
export pretty_print

include("audit.jl")
export report_default_tag_types

include("mutability.jl")

include("passes.jl")
export AbstractPass
export Audit
export CatchDuplicatedAnonymousTags
export Codegen
export CodegenMacro
export CodegenPostprocessing
export CodegenPreprocessing
export CollectDependentSystemNode
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
export TweakMutability
export TopologicalSort

include("context.jl")
export AbstractContext, Context
export parse_header!, parse_headers!
export create_context
export build!, BUILDSTAGE_ALL, BUILDSTAGE_NO_PRINTING, BUILDSTAGE_PRINTING_ONLY
export get_triple, get_default_args, detect_headers, find_dependent_headers
export get_identifier_node, get_tagtype_node

include("option.jl")
export load_options

function __init__()
   reset_definition()
end

end # module
