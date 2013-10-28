.. _doc-types:

Types
-----

.. type:: CLType

    Datatype representation.
    
    =================== ==
    Intrinsic datatypes   
    =================== ==
    VoidType
    BoolType
    Char_U         
    UChar
    Char16
    Char32
    UShort
    UInt
    ULong
    ULongLong
    UInt128
    Char_S
    SChar
    WChar
    Short
    IntType
    Long
    LongLong
    Int128
    Float
    Double
    LongDouble
    NullPtr
    =================== ==

    =================== ==
    Other useful types   
    =================== ==
    Invalid
    Unexposed
    Record
    Pointer
    Typedef
    Enum
    Vector
    ConstantArray

    Overload
    Dependent
    FirstBuiltin
    LastBuiltin
    Complex
    BlockPointer
    LValueReference
    RValueReference
    FunctionNoProto
    FunctionProto
    =================== ==

.. type:: CLCursor

    AST node types:

    ====================================== ==
    UnexposedDecl
    StructDecl
    UnionDecl
    ClassDecl
    EnumDecl
    FieldDecl
    EnumConstantDecl
    FunctionDecl
    VarDecl
    ParmDecl
    TypedefDecl
    CXXMethod
    Namespace
    LinkageSpec
    Constructor
    Destructor
    ConversionFunction
    TemplateTypeParameter
    NonTypeTemplateParameter
    TemplateTemplateParameter
    FunctionTemplate
    ClassTemplate
    ClassTemplatePartialSpecialization
    NamespaceAlias
    UsingDirective
    UsingDeclaration
    TypeAliasDecl
    CXXAccessSpecifier
    FirstDecl
    LastDecl
    FirstRef
    TypeRef
    CXXBaseSpecifier
    TemplateRef
    NamespaceRef
    MemberRef
    LabelRef
    OverloadedDeclRef
    VariableRef
    LastRef
    FirstInvalid
    InvalidFile
    NoDeclFound
    NotImplemented
    InvalidCode
    LastInvalid
    FirstExpr
    UnexposedExpr
    DeclRefExpr
    MemberRefExpr
    CallExpr
    BlockExpr
    IntegerLiteral
    FloatingLiteral
    ImaginaryLiteral
    StringLiteral
    CharacterLiteral
    ParenExpr
    UnaryOperator
    ArraySubscriptExpr
    BinaryOperator
    CompoundAssignOperator
    ConditionalOperator
    CStyleCastExpr
    CompoundLiteralExpr
    InitListExpr
    AddrLabelExpr
    StmtExpr
    GenericSelectionExpr
    GNUNullExpr
    CXXStaticCastExpr
    CXXDynamicCastExpr
    CXXReinterpretCastExpr
    CXXConstCastExpr
    CXXFunctionalCastExpr
    CXXTypeidExpr
    CXXBoolLiteralExpr
    CXXNullPtrLiteralExpr
    CXXThisExpr
    CXXThrowExpr
    CXXNewExpr
    CXXDeleteExpr
    UnaryExpr
    PackExpansionExpr
    SizeOfPackExpr
    LambdaExpr
    LastExpr
    FirstStmt
    UnexposedStmt
    LabelStmt
    CompoundStmt
    CaseStmt
    DefaultStmt
    IfStmt
    SwitchStmt
    WhileStmt
    DoStmt
    ForStmt
    GotoStmt
    IndirectGotoStmt
    ContinueStmt
    BreakStmt
    ReturnStmt
    GCCAsmStmt
    AsmStmt
    CXXCatchStmt
    CXXTryStmt
    CXXForRangeStmt
    SEHTryStmt
    SEHExceptStmt
    SEHFinallyStmt
    MSAsmStmt
    NullStmt
    DeclStmt
    LastStmt
    TranslationUnit
    FirstAttr
    UnexposedAttr
    IBActionAttr
    IBOutletAttr
    IBOutletCollectionAttr
    CXXFinalAttr
    CXXOverrideAttr
    AnnotateAttr
    AsmLabelAttr
    LastAttr
    PreprocessingDirective
    MacroDefinition
    MacroExpansion
    MacroInstantiation
    InclusionDirective
    FirstPreprocessing
    LastPreprocessing
    ModuleImportDecl
    FirstExtraDecl
    LastExtraDecl
    ====================================== ==
