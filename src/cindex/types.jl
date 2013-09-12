# Types and global definitions

# Type definitions for wrapped types
typealias CXIndex Ptr{Void}
typealias CXUnsavedFile Ptr{Void}
typealias CXFile Ptr{Void}
typealias CXTypeKind Int32
typealias CXCursorKind Int32
typealias CXTranslationUnit Ptr{Void}
const CXString_size = ccall( ("wci_size_CXString", libwci), Int, ())

# Work-around: ccall followed by composite_type in @eval gives error.
get_sz(sym) = @eval ccall( ($(string("wci_size_", sym)), :($(libwci))), Int, ())

###############################################################################
# Container types
#   for now we use these as the element type of the target array
###############################################################################

immutable _CXSourceLocation
    ptr_data1::Cptrdiff_t
    ptr_data2::Cptrdiff_t
    int_data::Cuint
    _CXSourceLocation() = new(0,0,0)
end

immutable _CXSourceRange
    ptr_data1::Cptrdiff_t
    ptr_data2::Cptrdiff_t
    begin_int_data::Cuint
    end_int_data::Cuint
    _CXSourceRange() = new(0,0,0,0)
end

immutable _CXTUResourceUsageEntry
    kind::Cint
    amount::Culong
    _CXTUResourceUsageEntry() = new(0,0)
end

immutable _CXTUResourceUsage
    data::Void
    numEntries::Cuint
    entries::Ptr{Cptrdiff_t}
    _CXTUResourceUsage() = new(0,0,0)
end

# Generate container types
for st in Any[
        :CXSourceLocation, :CXSourceRange,
        :CXTUResourceUsageEntry, :CXTUResourceUsage ]
    sz_name = symbol(string(st,"_size"))
    st_base = symbol(string("_", st))
    @eval begin
        const $sz_name = get_sz($("$st"))
        immutable $(st)
            data::Array{$st_base,1}
            $st(d) = new(d)
        end
        $st() = $st(Array($st_base, 1))
        $st(d::$st_base) = $st([d])
    end
end

immutable CXCursor
    kind::Cint
    xdata::Cint
    data1::Cptrdiff_t
    data2::Cptrdiff_t
    data3::Cptrdiff_t
    CXCursor() = new(0,0,0,0,0)
end

immutable CXString
    data::Array{Uint8,1}
    str::ASCIIString
    CXString() = new(Array(Uint8, CXString_size), "")
end

immutable CursorList
    ptr::Ptr{Void}
    size::Int
end

function get_string(cx::CXString)
    p::Ptr{Uint8} = ccall( (:wci_getCString, libwci), 
        Ptr{Uint8}, (Ptr{Void},), cx.data)
    if (p == C_NULL)
        return ""
    end
    bytestring(p)
end

###############################################################################
# Set up CXToken wrapping
#   Note that this low-level interface should be used with care.
#   Accessing a CXToken after the originating TokenList has been
#   finalized is undefined and will most likely segfault.
#   The high-level TokenList[] and CLToken interface is preferred.
###############################################################################

immutable _CXToken
    int_data1::Cuint
    int_data2::Cuint
    int_data3::Cuint
    int_data4::Cuint
    ptr_data::Cptrdiff_t
    _CXToken() = new(0,0,0,0,C_NULL)
end

# We generate this here manually because it has an extra field to keep
# track of the TranslationUnit.
immutable CXToken
    data::Array{_CXToken,1}
    CXToken(d) = new(d)
end
CXToken() = CXToken(Array(_CXToken, 1))
CXToken(d::_CXToken) = CXToken([d])

immutable TokenList
    ptr::Ptr{_CXToken}
    size::Cuint
    tunit::CXTranslationUnit
end

abstract CLToken
for sym in names(TokenKind, true)
    if(sym == :TokenKind) continue end
    @eval begin
        immutable $sym <: CLToken
            text::ASCIIString
        end
    end
end

function finalizer(l::TokenList)
    cindex.disposeTokens(l)
end

###############################################################################
# Set up CXCursor wrapping
#
#   Each CXCursorKind enum gets a specific Julia type wrapping
#   so that we can dispatch directly on node kinds.
###############################################################################

abstract CLCursor
CXCursorMap = Dict{Int32,Any}()
const CXCursor_size = get_sz(:CXCursor)

immutable TmpCursor <: CLCursor
    data::Array{CXCursor,1}
    TmpCursor() = new(Array(CXCursor,1))
end

for sym in names(CursorKind, true)
    if(sym == :CursorKind) continue end
    rval = eval(CursorKind.(sym))
    @eval begin
        immutable $(sym) <: CLCursor
            data::Array{CXCursor,1}
        end
        CXCursorMap[int32($rval)] = $sym
        Expr(:toplevel, Expr(:export, Any[$sym]))
    end
end

function CXCursor(c::TmpCursor)
    return CXCursorMap[c.data[1].kind](c.data)
end

###############################################################################
# Set up CXType wrapping
#
#   Each CXTypeKind enum gets a specific Julia type wrapping
#   so that we can dispatch directly on node kinds.
###############################################################################

abstract CLType
CLTypeMap = Dict{Int32,Any}()

immutable CXType
    kind::Int32
    data1::Cptrdiff_t
    data2::Cptrdiff_t
    CXType() = new(0,0,0)
end
immutable TmpType
    data::Array{CXType,1}
    TmpType() = new(Array(CXType,1))
end

for sym in names(TypeKind, true)
    if(sym == :TypeKind) continue end
    rval = eval(TypeKind.(sym))
    @eval begin
        immutable $(sym) <: CLType
            data::Array{CXType,1}
        end
        CLTypeMap[int32($rval)] = $sym
    end
end

function CXType(c::TmpType)
    return CLTypeMap[c.data[1].kind](c.data)
end
