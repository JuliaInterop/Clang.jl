Basic API
---------
.. function:: parse_header(header::String;
                            index                           = None,
                            diagnostics::Bool               = false,
                            cplusplus::Bool                 = false,
                            clang_args                      = ASCIIString[""],
                            clang_includes                  = ASCIIString[],
                            clang_flags                     = TranslationUnit_Flags.None)

    Main entry-point to Clang.jl. The required ``header`` argument specifies a header to parse. Returns the top CLCursor in the resulting TranslationUnit. Optional (keyword) arguments are as follows:

        ``index``: Ptr{CXIndex}, may be passed to re-use a CXIndex over multiple runs.
        ``diagnostics``: Print Clang diagnostics to STDERR.
        ``cplusplus``: Parse as C++ file.
        ``clang_args``: Vector of arguments (strings) to pass to Clang.
        ``clang_includes``: Vector of include paths for Clang to search (note: path only, "-I" will be prepended automatically)
        ``clang_flags``: Bitwise OR of TranslationUnit_FLags enum. Not required in typical use; see libclang manual for more information.

.. function:: children(c::CLCursor)

    Retrieve child nodes for given CLCursor. Julia's iterator protocol is supported, allowing constructs such as:
        
        ```
        for node in children(cursor)
            ...
        end
        ```

.. function:: cu_type(c::CLCursor)

    Get associated CLType for a given CLCursor.

.. function:: return_type(c::{FunctionDecl, CXXMethod})

    Get the CLType returned by the function or method.

.. function:: name(c::CLCursor)

    Return the display name of a given CLCursor. This is the "long name", and for a FunctionDecl will be the full function call signature (function name and argument types).

.. function:: spelling(t::CLCursor)
              spelling(t::CLType)

    Return the spelling of a given CLCursor or CLType. Spelling is the "short name" of a given element. For a FunctionDecl the spelling will be the function name only (similarly the identifier name for a RecordDecl or TypedefDecl cursor).

.. function:: value(c::EnumConstantDecl)

    Returns the value of a given EnumConstantDecl, automatically using correct call for signed/unsigned types (note: there are enum value getter functions in libclang API).

.. function:: pointee_type(t::Pointer)

    Returns the pointed-to type of a Pointer <: CLType.

.. function:: typedef_type(t::TypedefDecl)

    Returns the underlying type for a given TypedefDecl.

Tokenizer API
-------------

In some situations it is useful to retrieve the underlying tokens from a cursor.

.. function:: tokenize(c::CLCursor)

    Return a TokenList for the source range underlying the given CLCursor.

.. type:: TokenList

    Iterable type representing a collection of tokens, returned by the ``tokenize`` function.

    For a given tl <: TokenList, tl[index] returns the CLToken at the given position. The token's contents can be retrieved as a string using tl[i].text.

Types
-----

.. type:: CLType

    Datatype representation. Derived types:
    
        Invalid                Invalid cursor
        Unexposed               Not exposed via libclang API
        VoidType                C void
        BoolType               C bool
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
        Overload
        Dependent
        ObjCId
        ObjCClass
        ObjCSel
        FirstBuiltin
        LastBuiltin
        Complex
        Pointer
        BlockPointer
        LValueReference
        RValueReference
        Record
        Enum
        Typedef
        ObjCInterface
        ObjCObjectPointer
        FunctionNoProto
        FunctionProto
        ConstantArray
        Vector

.. type:: CLCursor

    Typed AST node:

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

