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

# Generate container types
for st in Any[
        :CXSourceLocation, :CXSourceRange,
        :CXTUResourceUsageEntry, :CXTUResourceUsage, :CXToken ]
    sz_name = symbol(string(st,"_size"))
    @eval begin
        const $sz_name = get_sz($("$st"))
        immutable $(st)
            data::Array{Uint8,1}
            $st() = new(Array(Uint8, $sz_name))
        end
    end
end

immutable _CXSourceLocation
    ptr_data1::Cptrdiff_t
    ptr_data2::Cptrdiff_t
    int_data::Cuint
end

immutable _CXSourceRange
    ptr_data1::Cptrdiff_t
    ptr_data2::Cptrdiff_t
    begin_int_data::Cuint
    end_int_data::Cuint
    foo::_CXSourceLocation
end

immutable CXCursor
    kind::Int32
    xdata::Int32
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

type CursorList
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
# Set up CXCursor wrapping
#
#   Each CXCursorKind enum gets a specific Julia type wrapping
#   so that we can dispatch directly on node kinds.
###############################################################################

abstract CLNode
CXCursorMap = Dict{Int32,Any}()
const CXCursor_size = get_sz(:CXCursor)

immutable TmpCursor <: CLNode
    data::Array{CXCursor,1}
    TmpCursor() = new(Array(CXCursor,1))
end

for sym in names(CursorKind, true)
    if(sym == :CursorKind) continue end
    rval = eval(CursorKind.(sym))
    @eval begin
        immutable $(sym) <: CLNode
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
