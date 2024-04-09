"""
    collect_top_level_nodes!
To build an expression DAG, we need to collect all of the symbols in advance.
"""
function collect_top_level_nodes! end

function collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLCursor, options)
    dumpobj(cursor)
    file, line, col = get_file_line_column(cursor)
    error("No support for code at $file:$line:$col, please file an issue to Clang.jl.")
    return nodes
end

function collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLFunctionDecl, options)
    skip_static_func = get(options, "skip_static_functions", false)
    skip_static_func && getCursorLinkage(cursor) == CXLinkage_Internal && return nodes

    func_type = getCursorType(cursor)

    if kind(func_type) == CXType_FunctionNoProto
        ty = FunctionNoProto()
    elseif isVariadic(func_type)
        ty = FunctionVariadic()
    elseif kind(func_type) == CXType_FunctionProto
        ty = FunctionProto()
    else
        ty = FunctionDefault()
    end

    id = Symbol(spelling(cursor))

    push!(nodes, ExprNode(id, ty, cursor, Expr[], Int[]))

    return nodes
end

function collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLTypedefDecl, options)
    lhs_type = getTypedefDeclUnderlyingType(cursor)

    if has_elaborated_tag_reference(lhs_type)
        ty = TypedefElaborated()
    elseif has_function_reference(lhs_type)
        ty = TypedefFunction()
    else
        ty = TypedefDefault()
    end

    id = Symbol(spelling(cursor))

    push!(nodes, ExprNode(id, ty, cursor, Expr[], Int[]))

    return nodes
end

function collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLTypeAliasDecl, options)
    ty = TypeAliasFunction()

    id = Symbol(spelling(cursor))

    push!(nodes, ExprNode(id, ty, cursor, Expr[], Int[]))

    return nodes
end

function collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLMacroDefinition, options)
    is_macro_no_op(cursor) && return nodes

    if isMacroBuiltin(cursor)
        ty = MacroBuiltIn()
    elseif isMacroFunctionLike(cursor)
        ty = MacroFunctionLike()
    elseif is_macro_definition_only(cursor)
        ty = MacroDefinitionOnly()
    elseif is_macro_unsupported(cursor)
        ty = MacroUnsupported()
    else
        ty = MacroDefault()
    end

    id = Symbol(spelling(cursor))

    push!(nodes, ExprNode(id, ty, cursor, Expr[], Int[]))

    return nodes
end

function collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLStructDecl, options)
    use_deterministic_sym = get(options, "use_deterministic_symbol", false)

    str = spelling(cursor)

    if isempty(str) || occursin(__ANONYMOUS_MARKER, str) || occursin(__UNNAMED_MARKER, str)
        @assert isCursorDefinition(cursor)
        ty = StructAnonymous()
        id = use_deterministic_sym ? gensym_deterministic("Ctag") : gensym("Ctag")
    elseif is_forward_declaration(cursor)
        ty = StructForwardDecl()
        id = Symbol(str)
    elseif isCursorDefinition(cursor)
        ty = StructDefinition()
        id = Symbol(str)
    else
        ty = StructDefault()
        id = Symbol(str)
    end

    push!(nodes, ExprNode(id, ty, cursor, Expr[], Int[]))

    return nodes
end

function collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLUnionDecl, options)
    use_deterministic_sym = get(options, "use_deterministic_symbol", false)

    str = spelling(cursor)

    if isempty(str) || occursin(__ANONYMOUS_MARKER, str) || occursin(__UNNAMED_MARKER, str)
        @assert isCursorDefinition(cursor)
        ty = UnionAnonymous()
        id = use_deterministic_sym ? gensym_deterministic("Ctag") : gensym("Ctag")
    elseif is_forward_declaration(cursor)
        ty = UnionForwardDecl()
        id = Symbol(str)
    elseif isCursorDefinition(cursor)
        ty = UnionDefinition()
        id = Symbol(str)
    else
        ty = UnionDefault()
        id = Symbol(str)
    end

    push!(nodes, ExprNode(id, ty, cursor, Expr[], Int[]))

    return nodes
end

function collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLEnumDecl, options)
    use_deterministic_sym = get(options, "use_deterministic_symbol", false)

    str = spelling(cursor)

    if isempty(str) || occursin(__ANONYMOUS_MARKER, str) || occursin(__UNNAMED_MARKER, str)
        @assert isCursorDefinition(cursor)
        ty = EnumAnonymous()
        id = use_deterministic_sym ? gensym_deterministic("Ctag") : gensym("Ctag")
    elseif is_forward_declaration(cursor)
        ty = EnumForwardDecl()
        id = Symbol(str)
    elseif isCursorDefinition(cursor)
        ty = EnumDefinition()
        id = Symbol(str)
    else
        ty = EnumDefault()
        id = Symbol(str)
    end

    push!(nodes, ExprNode(id, ty, cursor, Expr[], Int[]))

    return nodes
end

# skip macro expansion since the expanded info is already embedded in the AST
collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLMacroInstantiation, options) = nodes
collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLMacroExpansion, options) = nodes

# skip variable definition for now
# isn't it insane to define a variable in an interface header file? what's the use case?
collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLVarDecl, options) = nodes

# skip `#include <...>`
collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLInclusionDirective, options) = nodes
collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLLastPreprocessing, options) = nodes  # FIXME: fix cltype.jl


collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLFirstDecl, options) = nodes  # FIXME: fix cltype.jl

# skip C11's `_Static_assert`
collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLStaticAssert, options) = nodes

# C++ experimental support
collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLNamespace, options) = nodes
collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLUsingDeclaration, options) = nodes

# unexposed decl
function collect_top_level_nodes!(nodes::Vector{ExprNode}, cursor::CLUnexposedDecl, options)
    for child in children(cursor)
        collect_top_level_nodes!(nodes, child, options)
    end
    nodes
end
