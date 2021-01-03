"""
    collect_top_level_nodes!
To build an expression DAG, we need to collect all of the symbols in advance.
"""
function collect_top_level_nodes! end

function collect_top_level_nodes!(dag::ExprDAG, cursor::CLCursor)
    dumpobj(cursor)
    file, line, col = get_file_line_column(cursor)
    error("No support for code at $file:$line:$col, please file an issue to Clang.jl.")
    return dag
end

function collect_top_level_nodes!(dag::ExprDAG, cursor::CLFunctionDecl)
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

    push!(dag.nodes, ExprNode(id, ty, cursor, Expr[], Int[]))

    return dag
end

function collect_top_level_nodes!(dag::ExprDAG, cursor::CLTypedefDecl)
    lhs_type = getTypedefDeclUnderlyingType(cursor)

    if has_elaborated_reference(lhs_type)
        ty = TypedefElaborated()
    elseif has_function_reference(lhs_type)
        ty = TypedefFunction()
    else
        ty = TypedefDefault()
    end

    id = Symbol(spelling(cursor))

    push!(dag.nodes, ExprNode(id, ty, cursor, Expr[], Int[]))

    return dag
end

function collect_top_level_nodes!(dag::ExprDAG, cursor::CLMacroDefinition)
    if isMacroBuiltin(cursor)
        ty = MacroBuiltIn()
    elseif isMacroFunctionLike(cursor)
        ty = MacroFunctionLike()
    else
        ty = MacroDefault()
    end

    id = Symbol(spelling(cursor))

    push!(dag.nodes, ExprNode(id, ty, cursor, Expr[], Int[]))

    return dag
end

function collect_top_level_nodes!(dag::ExprDAG, cursor::CLStructDecl)
    str = spelling(cursor)

    if isempty(str)
        @assert isCursorDefinition(cursor)
        ty = StructAnonymous()
        id = gensym("Ctag")
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

    push!(dag.nodes, ExprNode(id, ty, cursor, Expr[], Int[]))

    return dag
end

function collect_top_level_nodes!(dag::ExprDAG, cursor::CLUnionDecl)
    str = spelling(cursor)

    if isempty(str)
        @assert isCursorDefinition(cursor)
        ty = UnionAnonymous()
        id = gensym()
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

    push!(dag.nodes, ExprNode(id, ty, cursor, Expr[], Int[]))

    return dag
end

function collect_top_level_nodes!(dag::ExprDAG, cursor::CLEnumDecl)
    str = spelling(cursor)

    if isempty(str)
        @assert isCursorDefinition(cursor)
        ty = EnumAnonymous()
        id = gensym()
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

    push!(dag.nodes, ExprNode(id, ty, cursor, Expr[], Int[]))

    return dag
end

# skip macro expansion since the expanded info is already embedded in the AST
collect_top_level_nodes!(dag::ExprDAG, cursor::CLMacroInstantiation) = dag
collect_top_level_nodes!(dag::ExprDAG, cursor::CLMacroExpansion) = dag

# skip variable definition for now
# isn't it insane to define a variable in an interface header file? what's the use case?
collect_top_level_nodes!(dag::ExprDAG, cursor::CLVarDecl) = dag

# skip `#include <...>`
collect_top_level_nodes!(dag::ExprDAG, cursor::CLInclusionDirective) = dag
collect_top_level_nodes!(dag::ExprDAG, cursor::CLLastPreprocessing) = dag  # FIXME: fix cltype.jl
