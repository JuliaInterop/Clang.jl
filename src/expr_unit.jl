struct Poisoned end

mutable struct ExprUnit
    items::Vector
    deps::OrderedSet{Symbol}
    state::Symbol
end

function ExprUnit(a::Array, deps=[]; state::Symbol=:new)
    ExprUnit(a, OrderedSet{Symbol}([target_type(dep) for dep in deps]), state)
end
function ExprUnit(e::Union{Expr,Symbol,String,Poisoned}, deps=[]; state::Symbol=:new)
    ExprUnit([e], OrderedSet{Symbol}([target_type(dep) for dep in deps]), state)
end
ExprUnit() = ExprUnit([], OrderedSet{Symbol}(), :new)


"""
Pretty-print a buffer of expressions (and comments) to an output stream
Adds blank lines at appropriate places for readability
"""
function print_buffer(out_stream, out_buffer)
    state = :comment
    for e in out_buffer
        isa(e, Poisoned) && continue
        prev_state = state
        state = (isa(e, AbstractString) ? :string :
                 isa(e, Expr) ? e.head :
                 error("output: can't handle type $(typeof(e))"))

        if state == :string && startswith(e, "# Skipping")
            state = :skipping
        end

        if ((state != prev_state && prev_state != :string) ||
            (state == prev_state && (state == :function || state == :struct)))
            println(out_stream)
        end

        if isa(e, Expr) && e.head == :macrocall && first(e.args) == Symbol("@cenum")
            println(out_stream, "@cenum($(e.args[3]),")
            for elem in e.args[4:end]
                println(out_stream, "    $elem,")
            end
            println(out_stream, ")")
            continue
        end
        println(out_stream, e)
    end
end

function dump_to_buffer!(buffer::Vector, expr_dict::OrderedDict{Symbol,ExprUnit}, item::ExprUnit)
    (item.state == :done || item.state == :processing) && return buffer
    item.state = :processing
    for dep in item.deps
        haskey(expr_dict, dep) || continue
        dump_to_buffer!(buffer, expr_dict, expr_dict[dep])
    end
    append!(buffer, item.items)
    item.state = :done
    return buffer
end

function dump_to_buffer(expr_dict::OrderedDict{Symbol,ExprUnit})
    buffer = []
    for item in values(expr_dict)
        item.state == :done && continue
        dump_to_buffer!(buffer, expr_dict, item)
    end
    return buffer
end
