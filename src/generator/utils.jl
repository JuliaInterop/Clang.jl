"""
    is_same(cursor1, cursor2) -> Bool
Return true if the source codes are exactly the same.
"""
function is_same(cursor1, cursor2)
    tu1 = getTranslationUnit(cursor1)
    tu2 = getTranslationUnit(cursor2)
    if tu1 == tu2
        # if both cursors are in the same TU
        cursor1 == cursor2 && return true
    else
        # if not, compare code locations
        file1, line1, col1 = get_file_line_column(cursor1)
        file2, line2, col2 = get_file_line_column(cursor2)
        return normpath(file1) == normpath(file2) && line1 == line2 && col1 == col2
    end
    # FIXME: in other cases, the code might be just compatible with each other, where we
    # need to compare the tokens.
end

# global counter for generating deterministic symbols
const __JL_COUNTER = Threads.Atomic{Int}(0)

reset_counter() = Threads.atomic_sub!(__JL_COUNTER,  __JL_COUNTER[])
add_counter() = Threads.atomic_add!(__JL_COUNTER, 1)
get_counter() = __JL_COUNTER[]

function gensym_deterministic(x::AbstractString)
    add_counter()
    str = "__JL_" * x * "_" * string(get_counter())
    return Symbol(str)
end

function gensym_recorded(cursor::CLCursor, isdeterministic::Bool, record::Dict{CLCursor, Symbol})
    get!(record, cursor) do 
        isdeterministic ? gensym_deterministic("Ctag") : gensym("Ctag")
    end
end