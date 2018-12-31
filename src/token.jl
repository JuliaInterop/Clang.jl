# for manipulating CXTokens
"""
Tokenizer access
"""
mutable struct TokenList
    ptr::Ptr{CXToken}
    size::Cuint
    tu::CXTranslationUnit
    function TokenList(tu::CXTranslationUnit, sr::CXSourceRange)
        GC.@preserve tu sr begin
            ptr_ref = Ref{Ptr{CXToken}}(C_NULL)
            num_ref = Ref{Cuint}(0)
            clang_tokenize(tu, sr, ptr_ref, num_ref)
            @assert ptr_ref[] != C_NULL
            obj = new(ptr_ref[], num_ref[], tu)
        end
        finalizer(obj) do x
            if x.ptr != C_NULL
                clang_disposeTokens(x.tu, x.ptr, x.size)
                x.ptr = C_NULL
            end
        end
        return obj
    end
end

Base.firstindex(x::TokenList) = 1
Base.lastindex(x::TokenList) = length(x)
Base.length(x::TokenList) = x.size
Base.iterate(x::TokenList, state=1) = state > x.size ? nothing : (x[state], state+1)

function Base.getindex(x::TokenList, i::Integer)
    !checkindex(Bool, 1:length(x), i) && throw(ArgumentError("BoundsError: TokenList miss at index $i"))
    GC.@preserve x begin
        token = unsafe_load(x.ptr, i)
        token_kind = kind(token)
        token_content = spelling(x.tu, token)
    end
    return CLTokenMap[token_kind](token, token_kind, token_content)
end

"""
    kind(t::CXToken) -> CXTokenKind
    kind(t::CLToken) -> CXTokenKind
Return the kind of the given token.
"""
kind(t::CXToken) = clang_getTokenKind(t)
kind(t::CLToken) = t.kind

"""
    spelling(tu::TranslationUnit, t::CLToken) -> String
    spelling(tu::TranslationUnit, t::CXToken) -> String
    spelling(tu::CXTranslationUnit, t::CXToken) -> String
Return the spelling of the given token. The spelling of a token is the textual
representation of that token, e.g., the text of an identifier or keyword.
"""
function spelling(tu::CXTranslationUnit, t::CXToken)
    GC.@preserve tu begin
        cxstr = clang_getTokenSpelling(tu, t)
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end
spelling(tu::TranslationUnit, t::CXToken) = spelling(tu.ptr, t)
spelling(tu::TranslationUnit, t::CLToken) = spelling(tu.ptr, t.token)

"""
    location(tu::TranslationUnit, t::CLToken) -> CXSourceLocation
    location(tu::TranslationUnit, t::CXToken) -> CXSourceLocation
    location(tu::CXTranslationUnit, t::CXToken) -> CXSourceLocation
Return the source location of the given token.
"""
location(tu::CXTranslationUnit, t::CXToken) = clang_getTokenLocation(tu, t)
location(tu::TranslationUnit, t::CXToken) = location(tu.ptr, t)
location(tu::TranslationUnit, t::CLToken) = location(tu.ptr, t.token)

"""
    extent(tu::TranslationUnit, t::CLToken) -> CXSourceRange
    extent(tu::TranslationUnit, t::CXToken) -> CXSourceRange
    extent(tu::CXTranslationUnit, t::CXToken) -> CXSourceRange
Return a source range that covers the given token.
"""
extent(tu::CXTranslationUnit, t::CXToken) = clang_getTokenExtent(tu, t)
extent(tu::TranslationUnit, t::CXToken) = extent(tu.ptr, t)
extent(tu::TranslationUnit, t::CLToken) = extent(tu.ptr, t.token)

"""
    tokenize(c::CXCursor) -> TokenList
    tokenize(c::CLCursor) -> TokenList
Return a TokenList from the given cursor.
"""
function tokenize(c::CXCursor)
    tu = clang_Cursor_getTranslationUnit(c)
    source_range = clang_getCursorExtent(c)
    range_start = clang_getRangeStart(source_range)
    range_end = clang_getRangeEnd(source_range)

    file = Ref{CXFile}(C_NULL)
    start_line = Ref{Cuint}(0)
    end_line = Ref{Cuint}(0)
    start_column = Ref{Cuint}(0)
    end_column = Ref{Cuint}(0)
    offset = Ref{Cuint}(0)
    clang_getExpansionLocation(range_start, file, start_line, start_column, offset)
    clang_getExpansionLocation(range_end, file, end_line, end_column, offset)

    expanded_start = clang_getLocation(tu, file[], start_line[], start_column[])
    expanded_end = clang_getLocation(tu, file[], end_line[], end_column[])
    expanded_range = clang_getRange(expanded_start, expanded_end)
    return TokenList(tu, expanded_range)
end
tokenize(c::CLCursor) = tokenize(c.cursor)

"""
    annotate(tu::TranslationUnit, tokens, token_num, cursors)
    annotate(tu::CXTranslationUnit, tokens, token_num, cursors)
Annotate the given set of tokens by providing cursors for each token that can be mapped to
a specific entity within the abstract syntax tree.
"""
annotate(tu::CXTranslationUnit, tokens, token_num, cursors) = clang_annotateTokens(tu, tokens, Unsigned(token_num), cursors)
annotate(tu::TranslationUnit, tokens, token_num, cursors) = annotate(tu.ptr, tokens, token_num, cursors)
