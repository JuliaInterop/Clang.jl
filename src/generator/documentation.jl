
print_documentation(io::IO, node::ExprNode, indent, options) = print_documentation(io, node.cursor, indent, options)
function print_documentation(io::IO, cursor::Union{CLCursor, CXCursor}, indent, options)
    fold_single_line_comment = get(options, "fold_single_line_comment", false)
    extract_c_comment_style = get(options, "extract_c_comment_style", missing)
    if ismissing(extract_c_comment_style)
        return
    elseif extract_c_comment_style == "doxygen"
        comment = Clang.getParsedComment(cursor)
        doc = format_doxygen(comment)
    elseif extract_c_comment_style == "raw"
        comment = Clang.getRawCommentText(cursor)
        doc = strip_comment_markers(comment)
    end
    
    # Do not print """ if no doc
    all(isempty, doc) && return
    doc = replace.(doc, r"([\\$\"])"=>s"\\\1")
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
    single_line_pattern = r"^\s*(/\*+<?\s*(.*)\s*\*/|/{2,}!?\s*(.*))$"

    lines = split(s, '\n')
    if length(lines) == 0
        return []
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


format_doxygen(c::Clang.Null) = []

function format_doxygen(comment::Clang.FullComment)
    child_nodes = children(comment)
    # Collect parameters
    parameters, paragraphs = [], []
    returns = missing
    for c in child_nodes
        if c isa Clang.ParamCommand
            push!(parameters, c)
        elseif c isa Clang.BlockCommand
            if Clang.getCommandName(c) == "returns"
                returns = c
            else
                push!(paragraphs, c)
            end
        elseif c isa Union{Clang.Paragraph,Clang.VerbatimLine,Clang.VerbatimBlockCommand}
            push!(paragraphs, c)
        else
            @info "Unhandled toplevel element: $c $(children(c))"
        end
    end
    lines = String[]
    for p in paragraphs
        Clang.isWhiteSpace(p) && continue
        t = format_fallback(p)
        if t isa String
            push!(lines, t)
        else
            append!(lines, t)
        end
    end
    if !isempty(parameters)
        push!(lines, "### Parameters:")
        append!(lines, format_parameter.(parameters))
    end
    if !ismissing(returns)
        push!(lines, "### Returns")
        push!(lines, format_fallback(Clang.getParagraph(returns)))
    end
    lines
end

function format_parameter(p)
    name = Clang.getParamName(p)
    name = replace(name, "_"=>"\\_")
    content = join(format_fallback.(children(p)))
    # Markdown lists seem to need a newline as separator
    "* **$name**:$content\n"
end

format_fallback(t::Clang.Text) = Clang.getText(t)
function format_fallback(t::Clang.VerbatimLine)
    "`" * Clang.getText(t) * "`"
end
function format_fallback(t::Clang.VerbatimBlockCommand)
    lines = Clang.getText.(children(t))
    # I don't know but Clang does not parse its own documentation right
    lines = filter(x->!occursin('\n', x), lines)
    ["```c++", lines..., "```"]
end
function format_fallback(c::Clang.InlineCommand)
    k = Clang.getRenderKind(c)
    args = join(Clang.getArguments(c), ' ')
    if k == Clang.CXCommentInlineCommandRenderKind_Normal
        return args
    elseif k == Clang.CXCommentInlineCommandRenderKind_Bold
        return "**" * args * "**"
    elseif k == Clang.CXCommentInlineCommandRenderKind_Monospaced
        return "`" * args * "`"
    elseif k == Clang.CXCommentInlineCommandRenderKind_Emphasized
        return "*" * args * "*"
    elseif k == Clang.CXCommentInlineCommandRenderKind_Anchor
        return ""
    end
end
format_fallback(p::Clang.Paragraph) = join(format_fallback.(children(p)))
function format_fallback(p::Clang.ParamCommand)
    name = Clang.getParamName(p)
    name = replace(name, "_"=>"\\_")
    dir = Clang.getDirection(p)
    content = join(format_fallback.(children(p)))
    "\\param $name$content"
end
function format_fallback(c::Clang.BlockCommand)
    name = Clang.getCommandName(c)
    args = join(Clang.getArguments(c), ' ')
    content = format_fallback(Clang.getParagraph(c))
    name == "li" && return "*$content"
    "\\$name$args$content"
end
function format_fallback(t::Clang.HTMLStartTag)
    name = Clang.getTagName(t)
    attrs = Clang.getAttributes(t)
    pairs = String[]
    for (k, v) in attrs
        push!(pairs, " ", k, "=", escape_string(v))
    end
    tag_start = "<"
    tag_end = Clang.isSelfClosing(t) ? "/>" : ">"
    tag = join([tag_start, name, pairs..., tag_end])
    return tag
end
format_fallback(t::Clang.HTMLEndTag) = "</" * Clang.getTagName(t) * ">"