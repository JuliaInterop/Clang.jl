using Libdl

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
const CXIndex = Ptr{Nothing}
const CXUnsavedFile = Ptr{Nothing}
const CXFile = Ptr{Nothing}
const CXTypeKind = Int32
const CXCursorKind = Int32
const CXTranslationUnit = Ptr{Nothing}

###############################################################################
# Container types
#   for now we use these as the element type of the target array
###############################################################################

struct CXSourceLocation
    ptr_data::NTuple{2, Csize_t}
    int_data::Cuint
    CXSourceLocation() = new(0,0)
end

struct CXSourceRange
    ptr_data::NTuple{2, Csize_t}
    begin_int_data::Cuint
    end_int_data::Cuint
    CXSourceRange() = new(0,0,0)
end

struct CXTUResourceUsageEntry
    kind::Cint
    amount::Culong
    CXTUResourceUsageEntry() = new(0,0)
end

struct CXTUResourceUsage
    data::Nothing
    numEntries::Cuint
    entries::Ptr{Cptrdiff_t}
    CXTUResourceUsage() = new(0,0,0)
end

# Generate container types
#for st in Any[
#        :CXTUResourceUsageEntry, :CXTUResourceUsage ]
#    sz_name = Symbol(st, "_size")
#    st_base = Symbol("_", st)
#    @eval begin
#        const $sz_name = get_sz($("$st"))
#        struct $(st)
#            data::Array{$st_base,1}
#            $st(d) = new(d)
#        end
#        $st() = $st(Array($st_base, 1))
#        $st(d::$st_base) = $st([d])
#    end
#end

struct CXCursor
    kind::Cint
    xdata::Cint
    data::NTuple{3, Csize_t}
    CXCursor() = new(0,0,0)
end

struct CXType
    kind::Int32
    data::NTuple{2, Csize_t}
    CXType() = new(0,(0,0))
end

struct CXString
    data::Ptr{UInt8}
    private_flags::Cuint
    CXString() = new(C_NULL,0)
end
Base.convert(::Type{String}, x::CXString) = unsafe_string(x.data)

###############################################################################
# Set up CXToken wrapping
#   Note that this low-level interface should be used with care.
#   Accessing a CXToken after the originating TokenList has been
#   finalized is undefined and will most likely segfault.
#   The high-level TokenList[] and CLToken interface is preferred.
###############################################################################

struct CXToken
    int_data::NTuple{4, Cuint}
    ptr_data::Csize_t
    CXToken() = new((0,0,0,0),0)
end

struct TokenList
    ptr::Ptr{CXToken}
    size::Cuint
    tunit::CXTranslationUnit
end

abstract type CLToken end
for sym in names(TokenKind, all=true)
    if(sym == :TokenKind) continue end
    @eval begin
        struct $sym <: CLToken
            text::String
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
const CXCursorMap = Dict{Int32,Any}()

# create the typed wrapper cursors
for sym in names(CursorKind, all=true)
    if(sym == :CursorKind) continue end

    rval = getfield(CursorKind, sym)

    @eval begin
        struct $(sym) <: CLCursor
            cursor::CXCursor
        end
        CXCursorMap[Int32($rval)] = $sym
    end
end

function CLCursor(c::CXCursor)
    return CXCursorMap[c.kind](c)
end

function Base.convert(::Type{CXCursor}, x::T) where T <: CLCursor
    return x.cursor
end

###############################################################################
# Set up CXType wrapping
#
#   Each CXTypeKind enum gets a specific Julia type wrapping
#   so that we can dispatch directly on node kinds.
###############################################################################

abstract type CLType end
CLTypeMap = Dict{Int32,Any}()

for sym in names(TypeKind, all=true)
    if(sym == :TypeKind) continue end

    rval = getfield(TypeKind, sym)

    @eval begin
        struct $(sym) <: CLType
            typ::CXType
        end
        CLTypeMap[Int32($rval)] = $sym;
    end
end

function CLType(t::CXType)
    return CLTypeMap[t.kind](t)
end

function Base.convert(::Type{CXType}, x::T) where T <: CLType
    return x.typ
end

function Base.convert(::Type{CLType}, x::CXType)
    return CLType(x)
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