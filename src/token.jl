# basic
"""
    kind(token::CXToken) -> CXTokenKind
Return the kind of the given token.
"""
kind(token::CXToken) = clang_getTokenKind(token)

"""
    spelling(tu::TranslationUnit, token::CXToken) -> String
    spelling(tu::CXTranslationUnit, token::CXToken) -> String
Return the spelling of the given token. The spelling of a token is the textual
representation of that token, e.g., the text of an identifier or keyword.
"""
function spelling(tu::CXTranslationUnit, token::CXToken)
    GC.@preserve c begin
        cxstr = clang_getTokenSpelling(tu, token)
        ptr = clang_getCString(cxstr)
        s = unsafe_string(ptr)
        clang_disposeString(cxstr)
    end
    return s
end
spelling(tu::TranslationUnit, token::CXToken) = spelling(tu.ptr, token)

"""
    location(tu::TranslationUnit, token::CXToken) -> CXSourceLocation
    location(tu::CXTranslationUnit, token::CXToken) -> CXSourceLocation
Return the source location of the given token.
"""
location(tu::CXTranslationUnit, token::CXToken) = clang_getTokenLocation(tu, token)
location(tu::TranslationUnit, token::CXToken) = location(tu.ptr, token)

"""
    extent(tu::TranslationUnit, token::CXToken) -> CXSourceRange
    extent(tu::CXTranslationUnit, token::CXToken) -> CXSourceRange
Return a source range that covers the given token.
"""
extent(tu::CXTranslationUnit, token::CXToken) = clang_getTokenExtent(tu, token)
extent(tu::TranslationUnit, token::CXToken) = extent(tu.ptr, token)

"""
    tokenize(c::CXCursor) -> TokenList
Return a TokenList from the given cursor.
"""
function tokenize(c::CXCursor)
    tu = clang_Cursor_getTranslationUnit(c)
    sourcerange = clang_getCursorExtent(c)
    return TokenList(tu, sourcerange)
end

# clang_annotateTokens

# helper
"""
Tokenizer access
"""
struct TokenList
    ptr::Ptr{CXToken}
    size::Cuint
    tu::TranslationUnit
    function TokenList(tu::TranslationUnit, sr::CXSourceRange)
        GC.@preserve tu sr begin
            ptr = Ref{Ptr{CXToken}}(C_NULL)
            num = Ref{Cuint}(0)
            clang_tokenize(tu.ptr, sr, ptr, num)
            @assert ptr != C_NULL
            obj = new(ptr, num[], tu)
        end
        finalizer(obj) do x
            if x.ptr != C_NULL
                clang_disposeTokens(x.tu.ptr, x.ptr, x.size)
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
    checkindex(Bool, 1:length(x), i) && throw(ArgumentError("BoundsError: TokenList miss at index $i"))
    GC.@preserve x begin
        token = unsafe_load(x.ptr, i)
    end
    return token
end
