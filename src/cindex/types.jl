# Types and global definitions

export Cursor, CXCursor
export CXType

export # TypeKind
    Invalid,
    Unexposed,
    VoidType,
    BoolType,
    Char_U,
    UChar,
    Char16,
    Char32,
    UShort,
    UInt,
    ULong,
    ULongLong,
    #UInt128,
    Char_S,
    SChar,
    WChar,
    Short,
    IntType,
    Long,
    LongLong,
    Int128,
    Float,
    Double,
    LongDouble,
    NullPtr,
    Overload,
    Dependent,
    ObjCId,
    ObjCClass,
    ObjCSel,
    FirstBuiltin,
    LastBuiltin,
    Complex,
    Pointer,
    BlockPointer,
    LValueReference,
    RValueReference,
    Record,
    Enum,
    Typedef,
    ObjCInterface,
    ObjCObjectPointer,
    FunctionNoProto,
    FunctionProto,
    ConstantArray,
    CLVector,
    IncompleteArray

export # CursorKind
    UnexposedDecl,
    StructDecl,
    UnionDecl,
    ClassDecl,
    EnumDecl,
    FieldDecl,
    EnumConstantDecl,
    FunctionDecl,
    VarDecl,
    ParmDecl,
    ObjCInterfaceDecl,
    ObjCCategoryDecl,
    ObjCProtocolDecl,
    ObjCPropertyDecl,
    ObjCIvarDecl,
    ObjCInstanceMethodDecl,
    ObjCClassMethodDecl,
    ObjCImplementationDecl,
    ObjCCategoryImplDecl,
    TypedefDecl,
    CXXMethod,
    Namespace,
    LinkageSpec,
    Constructor,
    Destructor,
    ConversionFunction,
    TemplateTypeParameter,
    NonTypeTemplateParameter,
    TemplateTemplateParameter,
    FunctionTemplate,
    ClassTemplate,
    ClassTemplatePartialSpecialization,
    NamespaceAlias,
    UsingDirective,
    UsingDeclaration,
    TypeAliasDecl,
    ObjCSynthesizeDecl,
    ObjCDynamicDecl,
    CXXAccessSpecifier,
    FirstDecl,
    LastDecl,
    FirstRef,
    ObjCSuperClassRef,
    ObjCProtocolRef,
    ObjCClassRef,
    TypeRef,
    CXXBaseSpecifier,
    TemplateRef,
    NamespaceRef,
    MemberRef,
    LabelRef,
    OverloadedDeclRef,
    VariableRef,
    LastRef,
    FirstInvalid,
    InvalidFile,
    NoDeclFound,
    NotImplemented,
    InvalidCode,
    LastInvalid,
    FirstExpr,
    UnexposedExpr,
    DeclRefExpr,
    MemberRefExpr,
    CallExpr,
    ObjCMessageExpr,
    BlockExpr,
    IntegerLiteral,
    FloatingLiteral,
    ImaginaryLiteral,
    StringLiteral,
    CharacterLiteral,
    ParenExpr,
    UnaryOperator,
    ArraySubscriptExpr,
    BinaryOperator,
    CompoundAssignOperator,
    ConditionalOperator,
    CStyleCastExpr,
    CompoundLiteralExpr,
    InitListExpr,
    AddrLabelExpr,
    StmtExpr,
    GenericSelectionExpr,
    GNUNullExpr,
    CXXStaticCastExpr,
    CXXDynamicCastExpr,
    CXXReinterpretCastExpr,
    CXXConstCastExpr,
    CXXFunctionalCastExpr,
    CXXTypeidExpr,
    CXXBoolLiteralExpr,
    CXXNullPtrLiteralExpr,
    CXXThisExpr,
    CXXThrowExpr,
    CXXNewExpr,
    CXXDeleteExpr,
    UnaryExpr,
    ObjCStringLiteral,
    ObjCEncodeExpr,
    ObjCSelectorExpr,
    ObjCProtocolExpr,
    ObjCBridgedCastExpr,
    PackExpansionExpr,
    SizeOfPackExpr,
    LambdaExpr,
    ObjCBoolLiteralExpr,
    ObjCSelfExpr,
    LastExpr,
    FirstStmt,
    UnexposedStmt,
    LabelStmt,
    CompoundStmt,
    CaseStmt,
    DefaultStmt,
    IfStmt,
    SwitchStmt,
    WhileStmt,
    DoStmt,
    ForStmt,
    GotoStmt,
    IndirectGotoStmt,
    ContinueStmt,
    BreakStmt,
    ReturnStmt,
    GCCAsmStmt,
    AsmStmt,
    ObjCAtTryStmt,
    ObjCAtCatchStmt,
    ObjCAtFinallyStmt,
    ObjCAtThrowStmt,
    ObjCAtSynchronizedStmt,
    ObjCAutoreleasePoolStmt,
    ObjCForCollectionStmt,
    CXXCatchStmt,
    CXXTryStmt,
    CXXForRangeStmt,
    SEHTryStmt,
    SEHExceptStmt,
    SEHFinallyStmt,
    MSAsmStmt,
    NullStmt,
    DeclStmt,
    LastStmt,
    TranslationUnit,
    FirstAttr,
    UnexposedAttr,
    IBActionAttr,
    IBOutletAttr,
    IBOutletCollectionAttr,
    CXXFinalAttr,
    CXXOverrideAttr,
    AnnotateAttr,
    AsmLabelAttr,
    LastAttr,
    PreprocessingDirective,
    MacroDefinition,
    MacroExpansion,
    MacroInstantiation,
    InclusionDirective,
    FirstPreprocessing,
    LastPreprocessing,
    ModuleImportDecl,
    FirstExtraDecl,
    LastExtraDecl

# Type definitions for wrapped types
typealias CXIndex Ptr{Void}
typealias CXUnsavedFile Ptr{Void}
typealias CXFile Ptr{Void}
typealias CXTypeKind Int32
typealias CXCursorKind Int32
typealias CXTranslationUnit Ptr{Void}

#const CXString_size = ccall( ("wci_size_CXString", libwci), Int, ())
#
## The content is not valid after deserializing and before `__init__` is called.
#const libwci_hdl = Ref{Ptr{Void}}(Libdl.dlopen(libwci))

#function __init__()
#    libwci_hdl[] = Libdl.dlopen(libwci)
#    nothing
#end

#function get_sz(sym)
#    fsym = Symbol("wci_size_", sym)
#    fptr = Libdl.dlsym(libwci_hdl[], fsym)
#    ccall(fptr, Int, ())
#end

###############################################################################
# Container types
#   for now we use these as the element type of the target array
###############################################################################

immutable CXSourceLocation
    ptr_data::NTuple{2, Csize_t}
    int_data::Cuint
    CXSourceLocation() = new(0,0)
end

immutable CXSourceRange
    ptr_data::NTuple{2, Csize_t}
    begin_int_data::Cuint
    end_int_data::Cuint
    CXSourceRange() = new(0,0,0)
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
#for st in Any[
#        :CXTUResourceUsageEntry, :CXTUResourceUsage ]
#    sz_name = Symbol(st, "_size")
#    st_base = Symbol("_", st)
#    @eval begin
#        const $sz_name = get_sz($("$st"))
#        immutable $(st)
#            data::Array{$st_base,1}
#            $st(d) = new(d)
#        end
#        $st() = $st(Array($st_base, 1))
#        $st(d::$st_base) = $st([d])
#    end
#end

immutable CXString
    data::Ptr{UInt8}
    private_flags::Cuint
    CXString() = new(C_NULL,0)
end

immutable CursorList
    ptr::Ptr{Void}
    size::Int
end

function get_string(cx::CXString)
    p::Ptr{UInt8} = ccall( (:wci_getCString, libwci),
        Ptr{UInt8}, (Ptr{Void},), cx.data)
    if (p == C_NULL)
        return ""
    end
    unsafe_string(p)
end

###############################################################################
# Set up CXToken wrapping
#   Note that this low-level interface should be used with care.
#   Accessing a CXToken after the originating TokenList has been
#   finalized is undefined and will most likely segfault.
#   The high-level TokenList[] and CLToken interface is preferred.
###############################################################################

immutable CXToken
    int_data::NTuple{4, Csize_t}
    ptr_data::Csize_t
    CXToken() = new(0,0)
end

# We generate this here manually because it has an extra field to keep
# track of the TranslationUnit.
#=
immutable CXToken
    data::Array{_CXToken,1}
    CXToken(d) = new(d)
end
CXToken() = CXToken(Array(_CXToken, 1))
CXToken(d::_CXToken) = CXToken([d])
=#

immutable TokenList
    ptr::Ptr{CXToken}
    size::Cuint
    tunit::CXTranslationUnit
end

abstract CLToken
for sym in names(TokenKind, true)
    if(sym == :TokenKind) continue end
    @eval begin
        immutable $sym <: CLToken
            text::Compat.ASCIIString
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

abstract Cursor

immutable _CXCursor <: Cursor
    kind::Cint
    xdata::Cint
    data::NTuple{3, Csize_t}
    _CXCursor() = new(0,0,0)
end

const CXCursorMap = Dict{Int32,Any}()

for sym in names(CursorKind, true)
    if(sym == :CursorKind) continue end
    rval = getfield(CursorKind, sym)
    @eval begin
        immutable $(sym) <: Cursor
            data::_CXCursor
        end
        CXCursorMap[Int32($rval)] = $sym
    end
end

immutable CXCursor <: Cursor
    data::_CXCursor
    CXCursor(x::_CXCursor) = CXCursorMap[x.kind](x)
end


function CXCursor(c::CXCursor)
    return CXCursorMap[c.kind](c)
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
    data::NTuple{2, Csize_t}
    CXType() = new(0,0)
end

immutable TmpType
    data::Array{CXType,1}
    TmpType() = new(Array(CXType,1))
end

for sym in names(TypeKind, true)
    if(sym == :TypeKind) continue end
    rval = getfield(TypeKind, sym)
    @eval begin
        immutable $(sym) <: CLType
            data::CXType
        end
        CLTypeMap[Int32($rval)] = $sym
    end
end

function CXType(c::TmpType)
    return CLTypeMap[c.data[1].kind](c.data)
end

# Duplicates
const LastDecl = CXXAccessSpecifier
const ObjCSuperClassRef = FirstRef
const LastRef = VariableRef
const InvalidFile = FirstInvalid
const LastInvalid=InvalidCode
const LastExpr = ObjCSelfExpr
const AsmStmt = GCCAsmStmt
const UnexposedAttr = FirstAttr
const LastPreprocessing = InclusionDirective
