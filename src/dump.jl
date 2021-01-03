printind(ind::Int, st...) = println(join([repeat(" ", 2 * ind), st...]))

dumpobj(cursor::CLCursor) = dumpobj(0, cursor)
dumpobj(t::CLType) = "a " * string(typeof(t)) * " " * spelling(t)
dumpobj(t::CLPointer) = "a pointer to `" * string(getPointeeType(t)) * "`"
dumpobj(ind::Int, t::CLType) = printind(ind, dumpobj(t))

function dumpobj(ind::Int, cursor::Union{CLParmDecl,CLFieldDecl})
    return printind(ind + 1, typeof(cursor), " ", dumpobj(getCursorType(cursor)), " ", name(cursor))
end

function dumpobj(
    ind::Int, node::Union{CLCursor,CLCompoundStmt,CLFunctionDecl,CLBinaryOperator}
)
    printind(ind, " ", typeof(node), " ", name(node))
    for c in children(node)
        dumpobj(ind + 1, c)
    end
end

function dumpobj(ind::Int, node::Union{CLUnionDecl,CLStructDecl})
    printind(ind, " ", typeof(node), " ", name(node))
    for c in fields(getCursorType(node))
        dumpobj(ind + 1, c)
    end
end
