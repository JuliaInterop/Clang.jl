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
        # we compare file locations
        file1, line1, col1 = get_file_line_column(cursor1)
        file2, line2, col2 = get_file_line_column(cursor2)
        return file1 == file2 && line1 == line2 && col1 == col2
    end
    # FIXME: in other cases, the code might be just compatible with each other.
end
