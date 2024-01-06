const ESCAPE_PATTERN = r"""(\$|\\|"(?=""))"""

function print_documentation(io::IO, node::ExprNode, indent, options, members::Bool=false; 
        prologue::Vector{String}=String[], epilogue::Vector{String}=String[])

    fold_single_line_comment = get(options, "fold_single_line_comment", false)
    extract_c_comment_style = get(options, "extract_c_comment_style", "disable")
    show_c_function_prototype = get(options, "show_c_function_prototype", false)
    ids = get(options, "DAG_ids", Dict())

    callback_documentation = get(options, "callback_documentation", nothing)

    doc = String[]
    if extract_c_comment_style == "doxygen"
        doc = format_doxygen(node.cursor, options, members)
    elseif extract_c_comment_style == "raw"
        doc = format_raw(node.cursor, members)
    end

    if !isnothing(callback_documentation)
        doc = callback_documentation(node, doc)
    end
    
    prototype = if show_c_function_prototype && node.cursor isa Clang.CLFunctionDecl
        ["### Prototype", "```c", get_prototype(node), "```"]
    else
        String[]
    end
    
    # Do not print """ if no doc
    all(isempty, doc) && isempty(prototype) && return
    doc = [prologue; doc; prototype; epilogue]
    # _ is already escaped with one slash, here we add one more
    doc = replace.(doc, ESCAPE_PATTERN=>s"\\\1")
    last(doc) == "" && pop!(doc)
    if length(doc) == 1 && fold_single_line_comment
        line = only(doc)
        println(io, indent, '"'^3, line, '"'^3)
    else
        println(io, indent * '"'^3)
        for line in doc
            println(io, indent, line)
        end
        println(io, indent * '"'^3)
    end
end

get_prototype(node::ExprNode) = get_prototype(node.cursor)

function get_prototype(cursor::CLCursor)
    code = Clang.getSourceCode(cursor)
    code = replace(code, r"/\*.*?\*/|//.*?$"m=>"")
    code = replace(code, r"\s+"m=>" ")
    "$code;"
end

escape_underscore(word) = replace(word, "_"=>"\\_")

"Replace identifiers with @ref"
function gen_automatic_links(text, ids)
    result = []
    # ...`id`(...)
    ESCAPE_PATTERN = r"^(.*?)(%)?(\*{1,2}|`?)([\w_][\w\d_]*)\3((?:\(.*?\))?.*)$"
    while true
        m = match(ESCAPE_PATTERN, text)

        isnothing(m) && break
        prev, escape, marker, word, next = m[1], m[2], m[3], m[4], m[5]
        text = next

        if isnothing(escape) && Symbol(word) in keys(ids)
            ref = "[`$word`](@ref)"
        else
            word = marker == "`" ? word : escape_underscore(word)
            ref = marker * word * marker
        end

        push!(result, prev, ref)
    end
    push!(result, text)
    return join(result)
end


function format_raw(cursor, members=false)
    comment = Clang.getRawCommentText(cursor)
    doc = strip_comment_markers(comment)
    member_docs = members ? get_member_doc(format_raw, cursor) : String[]
    isempty(member_docs) ? doc : [doc; ""; member_docs]
end


function strip_comment_markers(s::AbstractString)::Vector
    # Assume the comments are either /**/ or //, 
    # although Clang may associate multiple consecutive comments as a whole

    # // /*
    first_line_pattern = r"^\s*(/{2,}!?|/\*+!?)\s*(.*)$"
    # // *
    middle_line_pattern = r"^\s*(/{2,}!?\s?|\*?\s?)(.*)$"
    # // */
    last_line_pattern = r"^\s*(/{2,}!?\s*(.*)|(.*?)\*+/)$"
    # // /**/
    single_line_pattern = r"^\s*(/\*+<?\s*(.*)\s*\*/|/{2,}!?<?\s*(.*))$"

    lines = split(s, '\n')
    if length(lines) == 0
        return String[]
    elseif length(lines) == 1
        m = match(single_line_pattern, only(lines))
        if isnothing(m)
            return [s]
        else
            return [isnothing(m[2]) ? m[3] : m[2]]
        end
    else
        first = lines[1]
        last = lines[end]
        middle = lines[2:end-1]
        stripped = SubString{String}[]
        m_first = match(first_line_pattern, first)
        m_last = match(last_line_pattern, last)
        if isnothing(m_first)
            push!(stripped, first)
        elseif !isempty(m_first[2])
            push!(stripped, m_first[2])
        end
        for line in middle
            m = match(middle_line_pattern, line)
            if isnothing(m)
                push!(stripped, line)
            else
                push!(stripped, m[2])
            end
        end
        if isnothing(m_last)
            push!(stripped, last)
        else
            m = isnothing(m_last[2]) ? m_last[3] : m_last[2]
            isempty(m) || push!(stripped, m)
        end
        return stripped
    end
end

function join_row(row)
    parts = ["|"]
    for i in row
        push!(parts, " ", i, " |")
    end
    join(parts)
end

function render_table(table::AbstractMatrix{<:AbstractString})
    size(table, 2) <= 1 && return String[]
    slash_width = count.(ESCAPE_PATTERN, table) .* textwidth('\\')
    raw_width = textwidth.(table)
    widths = maximum(raw_width .+ slash_width, dims=2)
    cell_widths = max.(widths, 4)
    lines = String[]
    titles = rpad.(table[:, 1], cell_widths  .- slash_width[:, 1])

    push!(lines, join_row(titles))
    length_row = rpad.(":", cell_widths, '-')
    push!(lines, join_row(length_row))
    last_col = fill("", size(table, 1))
    for (col,slash_col) in Iterators.drop(zip(eachcol(table), eachcol(slash_width)), 1)
        for i in eachindex(col)
            if col[i] == last_col[i]
                col[i] = ""
                slash_col[i] = 0
            else
                last_col[i] = col[i]
            end
        end
        row = rpad.(col, cell_widths .- slash_col)
        push!(lines, join_row(row))
    end
    lines
end

get_member_doc(f, cursor::CLCursor) = String[]

function get_member_doc(f, cursor::CLEnumDecl)
    table = ["Enumerator", "Note"]
    for c in children(cursor)
        c isa CLEnumConstantDecl || continue
        name = escape_underscore(spelling(c))
        doc = join(f(c), ' ')
        doc = replace(doc, '\n'=>' ')
        isempty(doc) || push!(table, name, doc)
    end
    return render_table(reshape(table, 2, :))
end

function get_member_doc(f, cursor::CLStructDecl)
    table = ["Field", "Note"]
    for c in children(cursor)
        c isa CLFieldDecl || continue
        name = escape_underscore(spelling(c))
        doc = join(f(c), ' ')
        doc = replace(doc, '\n'=>' ')
        isempty(doc) || push!(table, name, doc)
    end
    return render_table(reshape(table, 2, :))
end


function format_doxygen(cursor, options, members=false)
    comment = Clang.getParsedComment(cursor)
    child_nodes = children(comment)
    # Collect parameters
    parameters, paragraphs = [], []
    returns = missing
    seealso = String[]
    for c in child_nodes
        if c isa Clang.ParamCommand
            push!(parameters, c)
        elseif c isa Clang.BlockCommand
            name = Clang.getCommandName(c)
            if name in ["returns", "return"]
                returns = c
            elseif name in ["sa", "see"]
                append!(seealso, format_block(Clang.getParagraph(c), options))
            else
                push!(paragraphs, c)
            end
        elseif c isa Union{Clang.Paragraph,Clang.VerbatimLine,Clang.VerbatimBlockCommand}
            push!(paragraphs, c)
        else
            @info "Unhandled toplevel element: $c $(children(c))"
        end
    end

    member_docs = members ? get_member_doc(x->format_doxygen(x, options, false), cursor) : String[]

    lines = String[]
    for p in paragraphs
        Clang.isWhiteSpace(p) && continue
        t = format_block(p, options)
        append!(lines, t)
        push!(lines, "")
    end
    if !isempty(parameters)
        push!(lines, "### Parameters")
        for p in parameters
            append!(lines, format_parameter(p, options))
        end
    end
    if !ismissing(returns)
        push!(lines, "### Returns")
        append!(lines, format_block(Clang.getParagraph(returns), options))
    end
    if !isempty(member_docs)
        append!(lines, member_docs)
    end
    if !isempty(seealso)
        push!(lines, "### See also")
        push!(lines, join(strip.(seealso), ", "), "")
    end
    lines
end


function format_parameter(p, options)
    name = Clang.getParamName(p)
    dir = parameter_pass_direction_name(Clang.getDirection(p))
    content = format_inline.(children(p), Ref(options))
    content[end] = rstrip(content[end])
    ["* `$name`:$dir$(content[1])"; @view content[2:end]]
end


"""
    format_block(comment) -> Vector{String}
Format block elements, return a collection of lines.
"""
function format_block end

function format_block(t::Clang.VerbatimLine, options)
    # this command is usually a result of parse error
    ["`" * Clang.getText(t) * "`"]
end

function format_block(x::Clang.Paragraph, options)
    t = format_inline(x, options)
    # Remove leading and trailing whitespace
    t = strip(t)
    [t]
end

function format_block(t::Clang.VerbatimBlockCommand, options)
    lines = Clang.getText.(children(t))
    # Clang does not parse its own documentation right
    # This is a quick fix for it
    lines = filter(x->!occursin('\n', x), lines)
    ["```c++"; lines; "```"]
end


function format_block(x::Clang.BlockCommand, options)
    name = Clang.getCommandName(x)
    args = join(Clang.getArguments(x), ' ')
    content = only(format_block(Clang.getParagraph(x), options))
    name in ["li", "arg"] && return ["* $content"]
    name in ["brief", "details"] && return [content]
    name in ["note", "warning"] && return ["!!! $name", "", "    $content"]
    name in ["deprecated"] && return ["!!! compat \"Deprecated\"", "", "    $content"]
    name in ["bug"] && return ["!!! danger \"Known bug\"", "", "    $content"]
    ["\\$name$args $content"]
end


"""
    format_inline(comment) -> String
Format inline elements, return a string.
"""
function format_inline end

function format_inline(t::Clang.Text, options)
    text = Clang.getText(t)
    # Fold consecutive space
    text = replace(text, r"(\s)\s+"=>s"\1")
    gen_automatic_links(text, get(options, "DAG_ids", Dict()))
end

function format_inline(t::Clang.VerbatimLine, options)
    "`" * Clang.getText(t) * "`"
end

function format_inline(t::Clang.VerbatimBlockCommand, options)
    lines = Clang.getText.(children(t))
    # Clang does not parse its own documentation right
    # This is a quick fix for it
    lines = filter(x->!occursin('\n', x), lines)
    ["```c++"; lines; "```"]
end

"""Render a "word" argument respecting C's identifier definition."""
function render_argument(raw, options, marker_begin, marker_end=marker_begin)
    # libclang thinks "(\c code)" is (`code)` instead of (`code`)
    m = match(r"^([\w\d_ ]+)(.*)$", raw)
    ids = get(options, "DAG_ids", Dict())
    if isnothing(m)
        "$marker_begin$raw$marker_end"
    else
        code = m[1]
        text = m[2]
        # Replace code with a link
        if Symbol(code) in keys(ids)
            "[`$code`](@ref)$text"
        else
            "$marker_begin$code$marker_end$text"
        end
    end
end

function format_inline(c::Clang.InlineCommand, options)
    k = Clang.getRenderKind(c)
    args = join(Clang.getArguments(c), ' ')
    if k == Clang.CXCommentInlineCommandRenderKind_Normal
        return args
    elseif k == Clang.CXCommentInlineCommandRenderKind_Bold
        return render_argument(args, options, "**")
    elseif k == Clang.CXCommentInlineCommandRenderKind_Monospaced
        return render_argument(args, options, "`")
    elseif k == Clang.CXCommentInlineCommandRenderKind_Emphasized
        return render_argument(args, options, "*")
    elseif k == Clang.CXCommentInlineCommandRenderKind_Anchor
        return ""
    end
end

function format_inline(p::Clang.Paragraph, options)
    join(format_inline.(children(p), Ref(options)))
end

function parameter_pass_direction_name(d)
    ismissing(d) && return ""
    d == Clang.CXCommentParamPassDirection_In && return raw"\[in\]"
    d == Clang.CXCommentParamPassDirection_Out && return raw"\[out\]"
    d == Clang.CXCommentParamPassDirection_InOut && return raw"\[in,out\]"
end

function format_inline(p::Clang.ParamCommand, options)
    name = Clang.getParamName(p)
    name = escape_underscore(name)
    dir = parameter_pass_direction_name(Clang.getDirection(p))
    content = join(format_inline.(children(p), Ref(options)))
    "\\param$dir $name$content"
end

function format_inline(c::Clang.BlockCommand, options)
    name = Clang.getCommandName(c)
    args = join(Clang.getArguments(c), ' ')
    content = format_inline(Clang.getParagraph(c), options)
    "\\$name$args$content"
end

function format_inline(t::Union{Clang.HTMLStartTag, Clang.HTMLEndTag}, options)
    Clang.getAsString(t)
end
