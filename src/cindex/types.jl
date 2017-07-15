# Types and global definitions

export CLType, CLCursor

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
const CXIndex = Ptr{Void}
const CXUnsavedFile = Ptr{Void}
const CXFile = Ptr{Void}
const CXTypeKind = Int32
const CXCursorKind = Int32
const CXTranslationUnit = Ptr{Void}
const CXString_size = ccall( ("wci_size_CXString", libwci), Int, ())

# The content is not valid after deserializing and before `__init__` is called.
const libwci_hdl = Ref{Ptr{Void}}(Libdl.dlopen(libwci))

function __init__()
    libwci_hdl[] = Libdl.dlopen(libwci)
    nothing
end

function get_sz(sym)
    fsym = Symbol("wci_size_", sym)
    fptr = Libdl.dlsym(libwci_hdl[], fsym)
    ccall(fptr, Int, ())
end

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
    sz_name = Symbol(st, "_size")
    st_base = Symbol("_", st)
    @eval begin
        const $sz_name = get_sz($("$st"))
        immutable $(st)
            data::Array{$st_base,1}
            $st(d) = new(d)
        end
        $st() = $st(Array{$st_base}(1))
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
    data::Array{UInt8,1}
    str::Compat.ASCIIString
    CXString() = new(Array{UInt8}(CXString_size), "")
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

abstract type CLToken end
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

abstract type CLCursor end
CXCursorMap = Dict{Int32,Any}()
const CXCursor_size = get_sz(:CXCursor)

immutable TmpCursor <: CLCursor
    data::Array{CXCursor,1}
    TmpCursor() = new(Array{CXCursor}(1))
end

for sym in names(CursorKind, true)
    if(sym == :CursorKind) continue end
    rval = getfield(CursorKind, sym)
    @eval begin
        immutable $(sym) <: CLCursor
            data::Array{CXCursor,1}
        end
        CXCursorMap[Int32($rval)] = $sym
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

abstract type CLType end
CLTypeMap = Dict{Int32,Any}()

immutable CXType
    kind::Int32
    data1::Cptrdiff_t
    data2::Cptrdiff_t
    CXType() = new(0,0,0)
end
immutable TmpType
    data::Array{CXType,1}
    TmpType() = new(Array{CXType}(1))
end

for sym in names(TypeKind, true)
    if(sym == :TypeKind) continue end
    rval = getfield(TypeKind, sym)
    @eval begin
        immutable $(sym) <: CLType
            data::Array{CXType,1}
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
