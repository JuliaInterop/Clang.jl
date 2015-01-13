strip_line_numbers!(arg) = arg
function strip_line_numbers!(ex::Expr)
    keep = trues(length(ex.args))
    for i = 1:length(ex.args)
        if isa(ex.args[i], LineNumberNode)
            keep[i] = false
        end
        isa(ex.args[i], Expr) || continue
        if ex.args[i].head == :line
            keep[i] = false
        else
            ex.args[i] = strip_line_numbers!(ex.args[i])
        end
    end
    ex.args = ex.args[keep]
    ex
end
