
print_documentation(io::IO, node::ExprNode, indent, options; kwargs...) = print_documentation(io, node.cursor, indent, options; kwargs...)
function print_documentation(io::IO, cursor::Union{CLCursor, CXCursor}, indent, options; prologue::Vector{String}=String[], epilogue::Vector{String}=String[])
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
    doc = [prologue; doc; epilogue]
    doc = replace.(doc, r"""([\\$]|"(?=""))"""=>s"\\\1")
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
        t = format_block(p)
        append!(lines, t)
        push!(lines, "")
    end
    if !isempty(parameters)
        push!(lines, "### Parameters")
        for p in parameters
            append!(lines, format_parameter(p))
            push!(lines, "")
        end
    end
    if !ismissing(returns)
        push!(lines, "### Returns")
        append!(lines, format_block(Clang.getParagraph(returns)))
    end
    lines
end

"""
    format_block(comment) -> Vector{String}
Format block elements, return a collection of lines.
"""
function format_block end

function format_block(t::Clang.VerbatimLine)
    # this command is usually a result of parse error
    ["`" * Clang.getText(t) * "`"]
end

function format_block(x::Clang.Paragraph)
    t = format_inline(x)
    # Remove leading space
    if startswith(t, ' ')
        t = t[2:end]
    end
    [t]
end

function format_block(t::Clang.VerbatimBlockCommand)
    lines = Clang.getText.(children(t))
    # Clang does not parse its own documentation right
    # This is a quick fix for it
    lines = filter(x->!occursin('\n', x), lines)
    ["```c++"; lines; "```"]
end


function format_block(x::Clang.BlockCommand)
    name = Clang.getCommandName(x)
    args = join(Clang.getArguments(x), ' ')
    content = format_inline(Clang.getParagraph(x))
    name in ["li", "arg"] && return ["*$content"]
    name in ["brief", "details"] && return [" $content"]
    ["\\$name$args$content"]
end


function format_parameter(p)
    name = Clang.getParamName(p)
    # TODO: escape all markdown symbols
    # name = replace(name, "_"=>"\\_")
    dir = parameter_pass_direction_name(Clang.getDirection(p))
    content = format_inline.(children(p))
    ["* `$name`:$dir$(content[1])"; @view content[2:end]]
end

"""
    format_inline(comment) -> String
Format inline elements, return a string.
"""
function format_inline end

function format_inline(t::Clang.Text)
    Clang.getText(t)
end

function format_inline(t::Clang.VerbatimLine)
    "`" * Clang.getText(t) * "`"
end

function format_inline(t::Clang.VerbatimBlockCommand)
    lines = Clang.getText.(children(t))
    # Clang does not parse its own documentation right
    # This is a quick fix for it
    lines = filter(x->!occursin('\n', x), lines)
    ["```c++"; lines; "```"]
end

"""Render a "word" argument respecting C's identifier definition."""
function render_argument(raw, marker)
    # libclang thinks "(\c code)" is (`code)`
    m = match(r"^([\w\d_ ]+)(.*)$", raw)
    if isnothing(m)
        "$marker$raw$marker"
    else
        code = m[1]
        text = m[2]
        "$marker$code$marker$text"
    end
end

function format_inline(c::Clang.InlineCommand)
    k = Clang.getRenderKind(c)
    args = join(Clang.getArguments(c), ' ')
    if k == Clang.CXCommentInlineCommandRenderKind_Normal
        return args
    elseif k == Clang.CXCommentInlineCommandRenderKind_Bold
        return render_argument(args, "**")
    elseif k == Clang.CXCommentInlineCommandRenderKind_Monospaced
        return render_argument(args, "`")
    elseif k == Clang.CXCommentInlineCommandRenderKind_Emphasized
        return render_argument(args, "*")
    elseif k == Clang.CXCommentInlineCommandRenderKind_Anchor
        return ""
    end
end

format_inline(p::Clang.Paragraph) = join(format_inline.(children(p)))

function parameter_pass_direction_name(d)
    ismissing(d) && return ""
    d == Clang.CXCommentParamPassDirection_In && return raw"\[in\]"
    d == Clang.CXCommentParamPassDirection_Out && return raw"\[out\]"
    d == Clang.CXCommentParamPassDirection_InOut && return raw"\[in,out\]"
end

function format_inline(p::Clang.ParamCommand)
    name = Clang.getParamName(p)
    name = replace(name, "_"=>"\\_")
    dir = parameter_pass_direction_name(Clang.getDirection(p))
    content = join(format_inline.(children(p)))
    "\\param$dir $name$content"
end

function format_inline(c::Clang.BlockCommand)
    name = Clang.getCommandName(c)
    args = join(Clang.getArguments(c), ' ')
    content = format_inline(Clang.getParagraph(c))
    "\\$name$args$content"
end

format_inline(t::Clang.HTMLStartTag) = Clang.getAsString(t)

format_inline(t::Clang.HTMLEndTag) = Clang.getAsString(t)