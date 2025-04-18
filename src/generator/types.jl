"""
    AbstractExprNodeType
Supertype for expression node types.
"""
abstract type AbstractExprNodeType end

"""
    AbstractTagType <: AbstractExprNodeType
Supertype for tag-type nodes.
"""
abstract type AbstractTagType <: AbstractExprNodeType end

"""
    Removable <: AbstractExprNodeType
Nodes that marked with this type can be safely removed from the DAG.
"""
struct Removable <: AbstractExprNodeType end

"""
    AbstractSkip <: AbstractExprNodeType
Supertype for nodes that should be skipped in the codegen pass.
"""
abstract type AbstractSkip <: AbstractExprNodeType end

"""
    Skip <: AbstractSkip
Nodes that marked with this type will be skipped in the codegen pass.

Note that if a node refers to a `Skip`-node, it should be marked as `Skip` as well.
"""
struct Skip <: AbstractSkip end

"""
    SoftSkip <: AbstractSkip
Nodes that marked with this type will be skipped in the codegen pass.

Note that if a non-skip node refers to a `SoftSkip`-node, it's just fine.
"""
struct SoftSkip <: AbstractSkip end

"""
    AbstractFunctionNodeType <: AbstractExprNodeType
Supertype for function-decl nodes.
"""
abstract type AbstractFunctionNodeType <: AbstractExprNodeType end

struct FunctionProto <: AbstractFunctionNodeType end
struct FunctionNoProto <: AbstractFunctionNodeType end
struct FunctionVariadic <: AbstractFunctionNodeType end
struct FunctionDuplicated <: AbstractFunctionNodeType end
struct FunctionDefault <: AbstractFunctionNodeType end

"""
    AbstractTypedefNodeType <: AbstractExprNodeType
Supertype for typedef-decl nodes.
"""
abstract type AbstractTypedefNodeType <: AbstractExprNodeType end

"""
    TypedefElaborated <: AbstractTypedefNodeType
A typedef type which directly or indirectly(through pointer/array) refers to an elaborated type.
"""
struct TypedefElaborated <: AbstractTypedefNodeType end
"""
    TypedefFunction <: AbstractTypedefNodeType
A typedef type which directly or indirectly(through pointer/array) refers to a function.
"""
struct TypedefFunction <: AbstractTypedefNodeType end
struct TypedefDuplicated <: AbstractTypedefNodeType end
struct TypedefMutualRef <: AbstractTypedefNodeType end
struct TypedefDefault <: AbstractTypedefNodeType end
"""
    TypedefToAnonymous <: AbstractTypedefNodeType
A typedef type which directly or indirectly(through pointer/array) refers to an anonymous tagtype
"""
struct TypedefToAnonymous <: AbstractTypedefNodeType
    sym::Symbol
end

abstract type AbstractTypeAliasNodeType <: AbstractExprNodeType end

struct TypeAliasFunction <: AbstractTypeAliasNodeType end

"""
    AbstractMacroNodeType <: AbstractExprNodeType
Supertype for macro nodes.
"""
abstract type AbstractMacroNodeType <: AbstractExprNodeType end

struct MacroUnsupported <: AbstractMacroNodeType end
struct MacroDefinitionOnly <: AbstractMacroNodeType end
struct MacroFunctionLike <: AbstractMacroNodeType end
struct MacroBuiltIn <: AbstractMacroNodeType end
struct MacroDuplicated <: AbstractMacroNodeType end
struct MacroDefault <: AbstractMacroNodeType end

"""
    AbstractStructNodeType <: AbstractTagType
Supertype for struct nodes.
"""
abstract type AbstractStructNodeType <: AbstractTagType end

struct StructAnonymous <: AbstractStructNodeType end
struct StructForwardDecl <: AbstractStructNodeType end
struct StructOpaqueDecl <: AbstractStructNodeType end
struct StructDefinition <: AbstractStructNodeType end
struct StructMutualRef <: AbstractStructNodeType end
struct StructDuplicated <: AbstractStructNodeType end
struct StructDefault <: AbstractStructNodeType end

"""
    StructLayout{Attribute,NestedAnonymous,Bitfield} <: AbstractStructNodeType
Struct nodes that have special layout.
"""
struct StructLayout{Attribute,NestedAnonymous,Bitfield} <: AbstractStructNodeType end

"""
    AbstractUnionNodeType <: AbstractTagType
Supertype for union nodes.
"""
abstract type AbstractUnionNodeType <: AbstractTagType end

struct UnionAnonymous <: AbstractUnionNodeType end
struct UnionForwardDecl <: AbstractUnionNodeType end
struct UnionOpaqueDecl <: AbstractUnionNodeType end
struct UnionDefinition <: AbstractUnionNodeType end
struct UnionDuplicated <: AbstractUnionNodeType end
struct UnionDefault <: AbstractUnionNodeType end

"""
    UnionLayout{Attribute,NestedAnonymous} <: AbstractStructNodeType
Union nodes that have special layout.
"""
struct UnionLayout{Attribute,NestedAnonymous} <: AbstractUnionNodeType end

"""
    AbstractEnumNodeType <: AbstractTagType
Supertype for enum nodes.
"""
abstract type AbstractEnumNodeType <: AbstractTagType end

struct EnumAnonymous <: AbstractEnumNodeType end
struct EnumForwardDecl <: AbstractEnumNodeType end
struct EnumOpaqueDecl <: AbstractEnumNodeType end
struct EnumDefinition <: AbstractEnumNodeType end
struct EnumDuplicated <: AbstractEnumNodeType end
struct EnumDefault <: AbstractEnumNodeType end

"""
    EnumLayout{Attribute} <: AbstractEnumNodeType
Enum nodes that have special layout.
"""
struct EnumLayout{Attribute} <: AbstractEnumNodeType end

"""
    AbstractObjCObjNodeType <: AbstractExprNodeType
Supertype for ObjectiveC Object declarations nodes.
"""
abstract type AbstractObjCObjNodeType <: AbstractTagType end

struct ObjCObjProtocolDecl <: AbstractObjCObjNodeType end
struct ObjCObjInterfaceDecl <: AbstractObjCObjNodeType end
struct ObjCObjDuplicated <: AbstractObjCObjNodeType end

# helper type unions
const ForwardDecls = Union{StructForwardDecl,UnionForwardDecl,EnumForwardDecl}
const OpaqueTags = Union{StructOpaqueDecl,UnionOpaqueDecl,EnumOpaqueDecl}
const UnknownDefaults = Union{FunctionDefault,StructDefault,UnionDefault,EnumDefault}
const RecordLayouts = Union{<:AbstractUnionNodeType,<:StructLayout}
const DuplicatedTags = Union{EnumDuplicated,UnionDuplicated,StructDuplicated, ObjCObjDuplicated}
const NestedRecords = Union{UnionAnonymous,UnionDefinition,StructAnonymous,StructDefinition}
const ObjCClassLikeDecl = Union{ObjCObjInterfaceDecl, ObjCObjProtocolDecl}

"""
    ExprNode{T<:AbstractExprNodeType,S<:CLCursor}
An expression node in the expression DAG.
"""
struct ExprNode{T<:AbstractExprNodeType,S<:CLCursor}
    id::Symbol
    type::T
    cursor::S
    exprs::Vector{Expr}
    premature_exprs::Vector{Expr}
    adj::Vector{Int}
end

# Outer constructor that sets `premature_exprs` to an empty vector
ExprNode(id, type, cursor, exprs, adj) = ExprNode(id, type, cursor, exprs, Expr[], adj)

"""
    ExprDAG
An expression DAG.
"""
Base.@kwdef struct ExprDAG
    nodes::Vector{ExprNode} = ExprNode[]
    partially_emitted_nodes::Dict{Symbol, ExprNode} = Dict{Symbol, ExprNode}()
    sys::Vector{ExprNode} = ExprNode[]
    tags::Dict{Symbol,Int} = Dict{Symbol,Int}()
    ids::Dict{Symbol,Int} = Dict{Symbol,Int}()
    ids_extra::Dict{Symbol,AbstractJuliaType} = EXTRA_DEFINITIONS
end

get_nodes(x::ExprDAG) = x.nodes
get_exprs(x::ExprNode) = x.exprs

# helper functions
is_removable(::ExprNode) = false
is_removable(::ExprNode{Removable}) = true

is_hardskip(::ExprNode) = false
is_hardskip(::ExprNode{Skip}) = true

is_anonymous(::ExprNode) = false
is_anonymous(::ExprNode{<:Union{StructAnonymous,UnionAnonymous,EnumAnonymous}}) = true

is_function(::ExprNode) = false
is_function(::ExprNode{<:AbstractFunctionNodeType}) = true

is_macrofunctionlike(::ExprNode) = false
is_macrofunctionlike(::ExprNode{MacroFunctionLike}) = true

is_variadic_function(::ExprNode) = false
is_variadic_function(::ExprNode{FunctionVariadic}) = true

is_typedef(::ExprNode) = false
is_typedef(::ExprNode{<:AbstractTypedefNodeType}) = true

is_typedef_elaborated(::ExprNode) = false
is_typedef_elaborated(::ExprNode{TypedefElaborated}) = true

is_typedef_to_anonymous(::ExprNode) = false
is_typedef_to_anonymous(::ExprNode{TypedefToAnonymous}) = true

is_tagtype(::ExprNode) = false
is_tagtype(::ExprNode{<:AbstractTagType}) = true

is_forward_decl(::ExprNode) = false
is_forward_decl(::ExprNode{StructForwardDecl}) = true
is_forward_decl(::ExprNode{UnionForwardDecl}) = true
is_forward_decl(::ExprNode{EnumForwardDecl}) = true

is_tag_def(::ExprNode) = false
is_tag_def(::ExprNode{StructForwardDecl}) = false
is_tag_def(::ExprNode{UnionForwardDecl}) = false
is_tag_def(::ExprNode{EnumForwardDecl}) = false
is_tag_def(::ExprNode{<:AbstractTagType}) = true

# note we treat opaques as valid definitions instead of decls
is_tag_def(::ExprNode{StructOpaqueDecl}) = true
is_tag_def(::ExprNode{UnionOpaqueDecl}) = true
is_tag_def(::ExprNode{EnumOpaqueDecl}) = true

is_identifier(::ExprNode) = false
is_identifier(::ExprNode{<:AbstractMacroNodeType}) = true
is_identifier(::ExprNode{<:AbstractTypedefNodeType}) = true
is_identifier(::ExprNode{<:AbstractFunctionNodeType}) = true

is_dup_identifier(::ExprNode) = false
is_dup_identifier(::ExprNode{FunctionDuplicated}) = true
is_dup_identifier(::ExprNode{TypedefDuplicated}) = true
is_dup_identifier(::ExprNode{MacroDuplicated}) = true

is_dup_tagtype(::ExprNode) = false
is_dup_tagtype(::ExprNode{StructDuplicated}) = true
is_dup_tagtype(::ExprNode{UnionDuplicated}) = true
is_dup_tagtype(::ExprNode{EnumDuplicated}) = true
is_dup_tagtype(::ExprNode{ObjCObjDuplicated}) = true

is_record(::ExprNode) = false
is_record(::ExprNode{<:AbstractStructNodeType}) = true
is_record(::ExprNode{<:AbstractUnionNodeType}) = true
is_record(::ExprNode{<:AbstractObjCObjNodeType}) = true

dup_type(::AbstractFunctionNodeType) = FunctionDuplicated()
dup_type(::AbstractTypedefNodeType) = TypedefDuplicated()
dup_type(::AbstractMacroNodeType) = MacroDuplicated()
dup_type(::AbstractObjCObjNodeType) = ObjCObjDuplicated()

# tag-types are possiblely duplicated because we are doing CTU analysis
dup_type(::AbstractStructNodeType) = StructDuplicated()
dup_type(::AbstractUnionNodeType) = UnionDuplicated()
dup_type(::AbstractEnumNodeType) = EnumDuplicated()

default_type(::AbstractTypedefNodeType) = TypedefDefault()
default_type(::AbstractMacroNodeType) = MacroDefault()
default_type(::AbstractStructNodeType) = StructDefault()
default_type(::AbstractUnionNodeType) = UnionDefault()
default_type(::AbstractEnumNodeType) = EnumDefault()

definition_type(::AbstractStructNodeType) = StructDefinition()
definition_type(::AbstractUnionNodeType) = UnionDefinition()
definition_type(::AbstractEnumNodeType) = EnumDefinition()

opaque_type(::AbstractStructNodeType) = StructOpaqueDecl()
opaque_type(::AbstractUnionNodeType) = UnionOpaqueDecl()
opaque_type(::AbstractEnumNodeType) = EnumOpaqueDecl()

attribute_type(::AbstractStructNodeType) = StructLayout{true,false,false}()
attribute_type(::StructLayout{A,N,B}) where {A,N,B} = StructLayout{true,N,B}()
attribute_type(::AbstractUnionNodeType) = UnionLayout{true,false}()
attribute_type(::UnionLayout{A,N}) where {A,N} = UnionLayout{true,N}()
attribute_type(::AbstractEnumNodeType) = EnumLayout{true}()
attribute_type(::EnumLayout{A}) where {A} = EnumLayout{true}()

nested_anonymous_type(::AbstractStructNodeType) = StructLayout{false,true,false}()
nested_anonymous_type(::StructLayout{A,N,B}) where {A,N,B} = StructLayout{A,true,B}()
nested_anonymous_type(::AbstractUnionNodeType) = UnionLayout{false,true}()
nested_anonymous_type(::UnionLayout{A,N}) where {A,N} = UnionLayout{A,true}()

bitfield_type(::AbstractStructNodeType) = StructLayout{false,false,true}()
bitfield_type(::StructLayout{A,N,B}) where {A,N,B} = StructLayout{A,N,true}()

is_bitfield_type(::AbstractExprNodeType) = false
is_bitfield_type(::StructLayout{A,N,B}) where {A,N,B} = B
