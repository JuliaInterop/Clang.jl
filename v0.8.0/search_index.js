var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": ""
},

{
    "location": "#Clang-1",
    "page": "Introduction",
    "title": "Clang",
    "category": "section",
    "text": "This package provides a Julia language wrapper for libclang: the stable, C-exported interface to the LLVM Clang compiler. The libclang API documentation provides background on the functionality available through libclang, and thus through the Julia wrapper. The repository also hosts related tools built on top of libclang functionality."
},

{
    "location": "#Installation-1",
    "page": "Introduction",
    "title": "Installation",
    "category": "section",
    "text": "Now, the package provides an out-of-box installation experience on Linux, macOS and Windows. You could simply install it by running:pkg> add Clang"
},

{
    "location": "#C-bindings-generator-1",
    "page": "Introduction",
    "title": "C-bindings generator",
    "category": "section",
    "text": "The package includes a generator to create Julia wrappers for C libraries from a collection of header files. The following declarations are currently supported:constants: translated to Julia const declarations\npreprocessor constants: translated to const declarations\nfunction: translated to Julia ccall(va_list and vararg argument are not supported)\nstruct: translated to Julia struct\nenum: translated to CEnum\nunion: translated to Julia struct\ntypedef: translated to Julia type alias to underlying intrinsic typeHere is a simple example:using Clang\n\nconst LIBCLANG_INCLUDE = joinpath(@__DIR__, \"..\", \"deps\", \"usr\", \"include\", \"clang-c\") |> normpath\nconst LIBCLANG_HEADERS = [joinpath(LIBCLANG_INCLUDE, header) for header in readdir(LIBCLANG_INCLUDE) if endswith(header, \".h\")]\n\nwc = init(; headers = CLANG_HEADERS,\n            output_file = joinpath(@__DIR__, \"libclang_api.jl\"),\n            common_file = joinpath(@__DIR__, \"libclang_common.jl\"),\n            clang_includes = vcat(LIBCLANG_INCLUDE, CLANG_INCLUDE),\n            clang_args = [\"-I\", joinpath(LIBCLANG_INCLUDE, \"..\")],\n            header_wrapped = (root, current)->root == current,\n            header_library = x->\"libclang\",\n            clang_diagnostics = true,\n            )\n\nrun(wc)"
},

{
    "location": "#Backward-compatibility-1",
    "page": "Introduction",
    "title": "Backward compatibility",
    "category": "section",
    "text": "If you miss those old behaviors before v0.8, you could simply make the following change in your old generator script:using Clang: CLANG_INCLUDE\nusing Clang.Deprecated.wrap_c\nusing Clang.Deprecated.cindex"
},

{
    "location": "#Build-a-custom-C-bindings-generator-1",
    "page": "Introduction",
    "title": "Build a custom C-bindings generator",
    "category": "section",
    "text": "A custom C-bindings generator tends to be used on large codebases, often with multiple API versions to support. Building a generator requires some customization effort, so for small libraries the initial investment may not pay off.The above-mentioned C-bindings generator only exposes several entry points for customization. In fact, it\'s actually not that hard to directly build your own C-bindings generator, for example, the following script is used for generating LibClang, you could refer to Tutorial for further details.using Clang\n\nconst LIBCLANG_INCLUDE = joinpath(@__DIR__, \"..\", \"deps\", \"usr\", \"include\", \"clang-c\") |> normpath\nconst LIBCLANG_HEADERS = [joinpath(LIBCLANG_INCLUDE, header) for header in readdir(LIBCLANG_INCLUDE) if endswith(header, \".h\")]\n\n# create a work context\nctx = DefaultContext()\n\n# parse headers\nparse_headers!(ctx, LIBCLANG_HEADERS,\n               args=[\"-I\", joinpath(LIBCLANG_INCLUDE, \"..\")],\n               includes=vcat(LIBCLANG_INCLUDE, CLANG_INCLUDE),\n               )\n\n# settings\nctx.libname = \"libclang\"\nctx.options[\"is_function_strictly_typed\"] = false\nctx.options[\"is_struct_mutable\"] = false\n\n# write output\napi_file = joinpath(@__DIR__, \"libclang_api.jl\")\napi_stream = open(api_file, \"w\")\n\nfor trans_unit in ctx.trans_units\n    root_cursor = getcursor(trans_unit)\n    push!(ctx.cursor_stack, root_cursor)\n    header = spelling(root_cursor)\n    @info \"wrapping header: $header ...\"\n    # loop over all of the child cursors and wrap them, if appropriate.\n    ctx.children = children(root_cursor)\n    for (i, child) in enumerate(ctx.children)\n        child_name = name(child)\n        child_header = filename(child)\n        ctx.children_index = i\n        # choose which cursor to wrap\n        startswith(child_name, \"__\") && continue  # skip compiler definitions\n        child_name in keys(ctx.common_buffer) && continue  # already wrapped\n        child_header != header && continue  # skip if cursor filename is not in the headers to be wrapped\n\n        wrap!(ctx, child)\n    end\n    @info \"writing $(api_file)\"\n    println(api_stream, \"# Julia wrapper for header: $header\")\n    println(api_stream, \"# Automatically generated using Clang.jl\\n\")\n    print_buffer(api_stream, ctx.api_buffer)\n    empty!(ctx.api_buffer)  # clean up api_buffer for the next header\nend\nclose(api_stream)\n\n# write \"common\" definitions: types, typealiases, etc.\ncommon_file = joinpath(@__DIR__, \"libclang_common.jl\")\nopen(common_file, \"w\") do f\n    println(f, \"# Automatically generated using Clang.jl\\n\")\n    print_buffer(f, dump_to_buffer(ctx.common_buffer))\nend\n\n# uncomment the following code to generate dependency and template files\n# copydeps(dirname(api_file))\n# print_template(joinpath(dirname(api_file), \"LibTemplate.jl\"))"
},

{
    "location": "#LibClang-1",
    "page": "Introduction",
    "title": "LibClang",
    "category": "section",
    "text": "LibClang is a thin wrapper over libclang. It\'s one-to-one mapped to the libclang APIs. By using Clang.LibClang, all of the CX/clang_-prefixed libclang APIs are imported into the current namespace, with which you could build up your own tools from the scratch. If you are unfamiliar with the Clang AST, a good starting point is the Introduction to the Clang AST."
},

{
    "location": "tutorial/#",
    "page": "Tutorial",
    "title": "Tutorial",
    "category": "page",
    "text": ""
},

{
    "location": "tutorial/#Tutorial-1",
    "page": "Tutorial",
    "title": "Tutorial",
    "category": "section",
    "text": "Clang is an open-source compiler built on the LLVM framework and targeting C, C++, and Objective-C (LLVM is also the JIT backend for Julia). Due to a highly modular design, Clang has in recent years become the core of a growing number of projects utilizing pieces of the compiler, such as tools for source-to-source translation, static analysis and security evaluation, and editor tools for code completion, formatting, etc.While LLVM and Clang are written in C++, the Clang project maintains a C-exported interface called \"libclang\" which provides access to the abstract syntax tree and type representations. Thanks to the ubiquity of support for C calling conventions, a number of languages have utilized libclang as a basis for tooling related to C and C++.The Clang.jl Julia package wraps libclang, provides a small convenience API for Julia-style programming, and provides a C-to-Julia wrapper generator built on libclang functionality.Here is the header file example.h used in the following examples:  // example.h\nstruct ExStruct {\n    int    kind;\n    char*  name;\n    float* data;\n};\n\nvoid* ExFunction (int kind, char* name, float* data) {\n    struct ExStruct st;\n    st.kind = kind;\n    st.name = name;\n    st.data = data;\n}"
},

{
    "location": "tutorial/#Printing-Struct-Fields-1",
    "page": "Tutorial",
    "title": "Printing Struct Fields",
    "category": "section",
    "text": "To motivate the discussion with a succinct example, consider this struct:struct ExStruct {\n    int    kind;\n    char*  name;\n    float* data;\n};Parsing and querying the fields of this struct requires just a few lines of code:julia> using Clang\n\njulia> trans_unit = parse_header(\"example.h\")\nTranslationUnit(Ptr{Nothing} @0x00007fe13cdc8a00, Index(Ptr{Nothing} @0x00007fe13cc8dde0, 0, 1))\n\njulia> root_cursor = getcursor(trans_unit)\nCLCursor (CLTranslationUnit) example.h\n\njulia> struct_cursor = search(root_cursor, \"ExStruct\")[1]\nCLCursor (CLStructDecl) ExStruct\n\njulia> for c in children(struct_cursor)  # print children\n           println(\"Cursor: \", c, \"\\n  Kind: \", kind(c), \"\\n  Name: \", name(c), \"\\n  Type: \", type(c))\n       end\nCursor: CLCursor (CLFieldDecl) kind\n  Kind: CXCursor_FieldDecl(6)\n  Name: kind\n  Type: CLType (CLInt)\nCursor: CLCursor (CLFieldDecl) name\n  Kind: CXCursor_FieldDecl(6)\n  Name: name\n  Type: CLType (CLPointer)\nCursor: CLCursor (CLFieldDecl) data\n  Kind: CXCursor_FieldDecl(6)\n  Name: data\n  Type: CLType (CLPointer)"
},

{
    "location": "tutorial/#AST-Representation-1",
    "page": "Tutorial",
    "title": "AST Representation",
    "category": "section",
    "text": "Let\'s examine the example above, starting with the variable trans_unit:julia> trans_unit\nTranslationUnit(Ptr{Nothing} @0x00007fa9ac6a9f90, Index(Ptr{Nothing} @0x00007fa9ac6b4080, 0, 1))A TranslationUnit is the entry point to the libclang AST. In the example above, trans_unit is a TranslationUnit for the parsed file example.h. The libclang AST is represented as a directed acyclic graph of cursor nodes carrying three pieces of essential information:Kind: purpose of cursor node\nType: type of the object represented by cursor\nChildren: list of child nodesjulia> root_cursor\nCLCursor (CLTranslationUnit) example.hroot_cursor is the root cursor node of the TranslationUnit.In Clang.jl the cursor type is encapsulated by a Julia type deriving from the abstract type CLCursor. Under the hood, libclang represents each cursor (CXCursor) kind and type (CXType) as an enum value. These enum values are used to automatically map all CXCursor and CXType objects to Julia types. Thus, it is possible to write multiple-dispatch methods against CLCursor or CLType variables.julia> dump(root_cursor)\nCLTranslationUnit\n  cursor: Clang.LibClang.CXCursor\n    kind: Clang.LibClang.CXCursorKind CXCursor_TranslationUnit(300)\n    xdata: Int32 0\n    data: Tuple{Ptr{Nothing},Ptr{Nothing},Ptr{Nothing}}\n      1: Ptr{Nothing} @0x00007fe13b3552e8\n      2: Ptr{Nothing} @0x0000000000000001\n      3: Ptr{Nothing} @0x00007fe13cdc8a00Under the hood, libclang represents each cursor kind and type as an enum value. These enums are translated into Julia as a subtype of Cenum:julia> dump(Clang.LibClang.CXCursorKind)\nClang.LibClang.CXCursorKind <: Clang.LibClang.CEnum.Cenum{UInt32}The example demonstrates two different ways of accessing child nodes of a given cursor. Here, the children function returns an iterator over the child nodes of the given cursor:julia> children(struct_cursor)\n3-element Array{CLCursor,1}:\n CLCursor (CLFieldDecl) kind\n CLCursor (CLFieldDecl) name\n CLCursor (CLFieldDecl) dataAnd here, the search function returns a list of child node(s) matching the given name:julia> search(root_cursor, \"ExStruct\")\n1-element Array{CLCursor,1}:\n CLCursor (CLStructDecl) ExStruct"
},

{
    "location": "tutorial/#Type-representation-1",
    "page": "Tutorial",
    "title": "Type representation",
    "category": "section",
    "text": "The above example also demonstrates querying of the type associated with a given cursor using the helper function type. In the output:Cursor: CLCursor (CLFieldDecl) kind\n  Kind: CXCursor_FieldDecl(6)\n  Name: kind\n  Type: CLType (CLInt)\nCursor: CLCursor (CLFieldDecl) name\n  Kind: CXCursor_FieldDecl(6)\n  Name: name\n  Type: CLType (CLPointer)\nCursor: CLCursor (CLFieldDecl) data\n  Kind: CXCursor_FieldDecl(6)\n  Name: data\n  Type: CLType (CLPointer)Each CLFieldDecl cursor has an associated CLType object, with an identity reflecting the field type for the given struct member. It is critical to note the difference between the representation for the kind field and the name and data fields. kind is represented directly as an CLInt object, but name and data are represented as CLPointer CLTypes. As explored in the next section, the full type of the CLPointer can be queried to retrieve the full char * and float * types of these members. User-defined types are captured using a similar scheme."
},

{
    "location": "tutorial/#Function-Arguments-and-Types-1",
    "page": "Tutorial",
    "title": "Function Arguments and Types",
    "category": "section",
    "text": "To further explore type representations, consider the following function (included in example.h):void* ExFunction (int kind, char* name, float* data) {\n    struct ExStruct st;\n    st.kind = kind;\n    st.name = name;\n    st.data = data;\n}To find the cursor for this function declaration, we use function search to retrieve nodes of kind  CXCursor_FunctionDecl , and select the final one in the list:julia> using Clang.LibClang  # CXCursor_FunctionDecl is exposed from LibClang\n\njulia> fdecl = search(root_cursor, CXCursor_FunctionDecl)[end]\nCLCursor (CLFunctionDecl) ExFunction(int, char *, float *)\n\njulia> fdecl_children = [c for c in children(fdecl)]\n4-element Array{CLCursor,1}:\n CLCursor (CLParmDecl) kind\n CLCursor (CLParmDecl) name\n CLCursor (CLParmDecl) data\n CLCursor (CLCompoundStmt)The first three children are CLParmDecl cursors with the same name as the arguments in the function signature. Checking the types of the CLParmDecl cursors indicates a similarity to the function signature:julia> [type(t) for t in fdecl_children[1:3]]\n3-element Array{CLType,1}:\n CLType (CLInt)     \n CLType (CLPointer)\n CLType (CLPointer)And, finally, retrieving the target type of each CLPointer argument confirms that these cursors represent the function argument type declaration:julia> [pointee_type(type(t)) for t in fdecl_children[2:3]]\n2-element Array{CLType,1}:\n CLType (CLChar_S)\n CLType (CLFloat)  "
},

{
    "location": "tutorial/#Printing-Indented-Cursor-Hierarchy-1",
    "page": "Tutorial",
    "title": "Printing Indented Cursor Hierarchy",
    "category": "section",
    "text": "As a closing example, here is a simple, indented AST printer using CLType- and CLCursor-related functions, and utilizing various aspects of Julia\'s type system.printind(ind::Int, st...) = println(join([repeat(\" \", 2*ind), st...]))\n\nprintobj(cursor::CLCursor) = printobj(0, cursor)\nprintobj(t::CLType) = join(typeof(t), \" \", spelling(t))\nprintobj(t::CLInt) = t\nprintobj(t::CLPointer) = pointee_type(t)\nprintobj(ind::Int, t::CLType) = printind(ind, printobj(t))\n\nfunction printobj(ind::Int, cursor::Union{CLFieldDecl, CLParmDecl})\n    printind(ind+1, typeof(cursor), \" \", printobj(type(cursor)), \" \", name(cursor))\nend\n\nfunction printobj(ind::Int, node::Union{CLCursor, CLStructDecl, CLCompoundStmt,\n                                        CLFunctionDecl, CLBinaryOperator})\n    printind(ind, \" \", typeof(node), \" \", name(node))\n    for c in children(node)\n        printobj(ind + 1, c)\n    end\nendjulia> printobj(root_cursor)\n CLTranslationUnit example.h\n   CLStructDecl ExStruct\n      CLFieldDecl CLType (CLInt)  kind\n      CLFieldDecl CLType (CLChar_S)  name\n      CLFieldDecl CLType (CLFloat)  data\n   CLFunctionDecl ExFunction(int, char *, float *)\n      CLParmDecl CLType (CLInt)  kind\n      CLParmDecl CLType (CLChar_S)  name\n      CLParmDecl CLType (CLFloat)  data\n     CLCompoundStmt\n       CLDeclStmt\n         CLVarDecl st\n           CLTypeRef struct ExStruct\n       CLBinaryOperator\n         CLMemberRefExpr kind\n           CLDeclRefExpr st\n         CLUnexposedExpr kind\n           CLDeclRefExpr kind\n       CLBinaryOperator\n         CLMemberRefExpr name\n           CLDeclRefExpr st\n         CLUnexposedExpr name\n           CLDeclRefExpr name\n       CLBinaryOperator\n         CLMemberRefExpr data\n           CLDeclRefExpr st\n         CLUnexposedExpr data\n           CLDeclRefExpr dataNote that a generic printobj function has been defined for the abstract CLType and CLCursor types, and multiple dispatch is used to define the printers for various specific types needing custom behavior. In particular, the following function handles all cursor types for which recursive printing of child nodes is required:function printobj(ind::Int, node::Union{CLCursor, CLStructDecl, CLCompoundStmt, CLFunctionDecl})Now, printobj has been moved into Clang.jl with a new name: dumpobj."
},

{
    "location": "tutorial/#Parsing-Summary-1",
    "page": "Tutorial",
    "title": "Parsing Summary",
    "category": "section",
    "text": "As discussed above, there are several key aspects of the Clang.jl/libclang API:tree of Cursor nodes representing the AST, notes have unique children.\neach Cursor node has a Julia type identifying the syntactic construct represented by the node.\neach node also has an associated CLType referencing either intrinsic or user-defined datatypes.There are a number of details omitted from this post, especially concerning the full variety of CLCursor and CLType representations available via libclang. For further information, please see the libclang documentation."
},

{
    "location": "tutorial/#Acknowledgement-1",
    "page": "Tutorial",
    "title": "Acknowledgement",
    "category": "section",
    "text": "Eli Bendersky\'s post Parsing C++ in Python with Clang has been an extremely helpful reference."
},

{
    "location": "api/#",
    "page": "API Reference",
    "title": "API Reference",
    "category": "page",
    "text": ""
},

{
    "location": "api/#Clang.address_space-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.address_space",
    "category": "method",
    "text": "address_space(t::CXType)\naddress_space(t::CLType)\n\nReturns the address space of the given type. Wrapper for libclang\'s clang_getAddressSpace.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.annotate-Tuple{Ptr{Nothing},Any,Any,Any}",
    "page": "API Reference",
    "title": "Clang.annotate",
    "category": "method",
    "text": "annotate(tu::TranslationUnit, tokens, token_num, cursors)\nannotate(tu::CXTranslationUnit, tokens, token_num, cursors)\n\nAnnotate the given set of tokens by providing cursors for each token that can be mapped to a specific entity within the abstract syntax tree.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.argnum-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.argnum",
    "category": "method",
    "text": "argnum(c::CXCursor) -> Int\nargnum(c::CLCXXMethod) -> Int\nargnum(c::CLFunctionDecl) -> Int\n\nReturn the number of non-variadic arguments associated with a given cursor. Wrapper for libclang\'s clang_Cursor_getNumArguments.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.argnum-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.argnum",
    "category": "method",
    "text": "argnum(t::CXType) -> Int\nargnum(t::CLFunctionProto) -> Int\nargnum(t::CLFunctionNoProto) -> Int\n\nReturn the number of non-variadic parameters associated with a function type. Wrapper for libclang\'s clang_getNumArgTypes.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.argtype-Tuple{Clang.LibClang.CXType,Unsigned}",
    "page": "API Reference",
    "title": "Clang.argtype",
    "category": "method",
    "text": "argtype(t::CXType, i::Unsigned) -> CXType\nargtype(t::CLFunctionProto, i::Integer) -> CLType\nargtype(t::CLFunctionNoProto, i::Integer) -> CLType\n\nReturn the type of a parameter of a function type. Wrapper for libclang\'s clang_getArgType.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.argument-Tuple{Clang.LibClang.CXCursor,Unsigned}",
    "page": "API Reference",
    "title": "Clang.argument",
    "category": "method",
    "text": "argument(c::CXCursor, i::Unsigned) -> CXCursor\nargument(c::CLFunctionDecl, i::Integer) -> CLCursor\nargument(c::CLCXXMethod, i::Integer) -> CLCursor\n\nReturn the argument cursor of a function or method. Wrapper for libclang\'s clang_Cursor_getArgument.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.bitwidth-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.bitwidth",
    "category": "method",
    "text": "bitwidth(c::CLFieldDecl) -> Int\n\nReturn the bit width of a bit field declaration as an integer. Wrapper for libclang\'s clang_getFieldDeclBitWidth.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.canonical-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.canonical",
    "category": "method",
    "text": "canonical(c::CXCursor) -> CXCursor\ncanonical(c::CLCursor) -> CLCursor\n\nReturn the canonical cursor corresponding to the given cursor. Wrapper for libclang\'s clang_getCanonicalCursor.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.canonical-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.canonical",
    "category": "method",
    "text": "canonical(t::CXType) -> CXType\ncanonical(t::CLType) -> CLType\n\nReturn the canonical type for a CXType.\n\nClang\'s type system explicitly models typedefs and all the ways a specific type can be represented. The canonical type is the underlying type with all the \"sugar\" removed. For example, if \'T\' is a typedef for \'int\', the canonical type for \'T\' would be \'int\'. Wrapper for libclang\'s clang_getCanonicalType.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.children-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.children",
    "category": "method",
    "text": "children(cursor::CXCursor) -> Vector{CXCursor}\nchildren(cursor::CLCursor) -> Vector{CLCursor}\n\nReturn a child cursor vector of the given cursor.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.clang2julia-Tuple{CLCursor}",
    "page": "API Reference",
    "title": "Clang.clang2julia",
    "category": "method",
    "text": "clang2julia(c::CLCursor) -> Symbol/Expr\n\nConvert libclang cursor/type to Julia.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.clang2julia-Tuple{CLType}",
    "page": "API Reference",
    "title": "Clang.clang2julia",
    "category": "method",
    "text": "clang2julia(t::CLType) -> Symbol/Expr\n\nConvert libclang cursor/type to Julia.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.copydeps-Tuple{Any}",
    "page": "API Reference",
    "title": "Clang.copydeps",
    "category": "method",
    "text": "copydeps(dst)\n\nCopy dependencies to dst.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.element_num-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.element_num",
    "category": "method",
    "text": "element_num(t::CXType) -> Int\nelement_num(t::CLVector) -> Int\nelement_num(t::CLConstantArray) -> Int\nelement_num(t::CLIncompleteArray) -> Int\nelement_num(t::CLVariableArray) -> Int\nelement_num(t::CLDependentSizedArray) -> Int\n\nReturn the number of elements of an array or vector type. Wrapper for libclang\'s clang_getNumElements.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.element_type-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.element_type",
    "category": "method",
    "text": "element_type(t::CXType) -> CXType\nelement_type(t::CLVector) -> CLType\nelement_type(t::CLConstantArray) -> CLType\nelement_type(t::CLIncompleteArray) -> CLType\nelement_type(t::CLVariableArray) -> CLType\nelement_type(t::CLDependentSizedArray) -> CLType\nelement_type(t::CLComplex) -> CLType\n\nReturn the element type of an array, complex, or vector type. Wrapper for libclang\'s clang_getElementType.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.extent-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.extent",
    "category": "method",
    "text": "extent(c::CXCursor) -> CXSourceRange\nextent(c::CLCursor) -> CXSourceRange\n\nReturn the physical extent of the source construct referenced by the given cursor.\n\nThe extent of a cursor starts with the file/line/column pointing at the first character within the source construct that the cursor refers to and ends with the last character within that source construct. For a declaration, the extent covers the declaration itself. For a reference, the extent covers the location of the reference (e.g., where the referenced entity was actually used). Wrapper for libclang\'s clang_getCursorExtent.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.extent-Tuple{Ptr{Nothing},Clang.LibClang.CXToken}",
    "page": "API Reference",
    "title": "Clang.extent",
    "category": "method",
    "text": "extent(tu::TranslationUnit, t::CLToken) -> CXSourceRange\nextent(tu::TranslationUnit, t::CXToken) -> CXSourceRange\nextent(tu::CXTranslationUnit, t::CXToken) -> CXSourceRange\n\nReturn a source range that covers the given token.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.filename-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.filename",
    "category": "method",
    "text": "filename(c::CXCursor) -> String\nfilename(c::CLCursor) -> String\n\nReturn the complete file and path name of the given file referenced by the input cursor.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.function_args-Tuple{CLCursor}",
    "page": "API Reference",
    "title": "Clang.function_args",
    "category": "method",
    "text": "function_args(cursor::CLCursor) -> Vector{CLCursor}\n\nReturn function arguments for a given cursor.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.get_included_file-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.get_included_file",
    "category": "method",
    "text": "get_included_file(c::CXCursor) -> CXFile\nget_included_file(c::CLCursor) -> CXFile\n\nReturn the file that is included by the given inclusion directive cursor. Wrapper for libclang\'s clang_getIncludedFile.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.get_lexical_parent-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.get_lexical_parent",
    "category": "method",
    "text": "get_lexical_parent(c::CXCursor) -> CXCursor\nget_lexical_parent(c::CLCursor) -> CLCursor\n\nReturn the lexical parent of the given cursor. Please checkout libclang\'s doc to know more. Wrapper for libclang\'s clang_getCursorLexicalParent.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.get_named_type-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.get_named_type",
    "category": "method",
    "text": "get_named_type(t::CXType) -> CXType\nget_named_type(t::CLElaborated) -> CLType\n\nReturn the type named by the qualified-id. Wrapper for libclang\'s clang_Type_getNamedType.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.get_semantic_parent-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.get_semantic_parent",
    "category": "method",
    "text": "get_semantic_parent(c::CXCursor) -> CXCursor\nget_semantic_parent(c::CLCursor) -> CLCursor\n\nReturn the semantic parent of the given cursor. Please checkout libclang\'s doc to know more. Wrapper for libclang\'s clang_getCursorSemanticParent.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.get_translation_unit-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.get_translation_unit",
    "category": "method",
    "text": "get_translation_unit(c::CXCursor) -> CXTranslationUnit\nget_translation_unit(c::CLCursor) -> CXTranslationUnit\n\nReturns the translation unit that a cursor originated from. Wrapper for libclang\'s clang_Cursor_getTranslationUnit.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.getcursor-Tuple{Ptr{Nothing}}",
    "page": "API Reference",
    "title": "Clang.getcursor",
    "category": "method",
    "text": "getcursor(tu::TranslationUnit) -> CXCursor\ngetcursor(tu::CXTranslationUnit) -> CLCursor\n\nReturn the cursor that represents the given translation unit.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.getcursor-Tuple{}",
    "page": "API Reference",
    "title": "Clang.getcursor",
    "category": "method",
    "text": "getcursor() -> (NULL)CXCursor\n\nReturn the NULL CXCursor. Wrapper for libclang\'s clang_getNullCursor.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.getdef-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.getdef",
    "category": "method",
    "text": "getdef(c::CXCursor) -> CXCursor\ngetdef(c::CLCursor) -> CLCursor\n\nFor a cursor that is either a reference to or a declaration of some entity, retrieve a cursor that describes the definition of that entity. Wrapper for libclang\'s clang_getCursorDefinition.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.getref-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.getref",
    "category": "method",
    "text": "getref(c::CXCursor) -> CXCursor\ngetref(c::CLCursor) -> CLCursor\n\nFor a cursor that is a reference, retrieve a cursor representing the entity that it references. Wrapper for libclang\'s clang_getCursorReferenced.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.hasattr-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.hasattr",
    "category": "method",
    "text": "hasattr(c::CXCursor) -> Bool\nhasattr(c::CLCursor) -> Bool\n\nDetermine whether the given cursor has any attributes. Wrapper for libclang\'s clang_Cursor_hasAttrs.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.integer_type-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.integer_type",
    "category": "method",
    "text": "integer_type(c::CLEnumDecl) -> CLType\n\nRetrieve the integer type of an enum declaration. Wrapper for libclang\'s clang_getEnumDeclIntegerType.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.is_plain_old_data-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.is_plain_old_data",
    "category": "method",
    "text": "is_plain_old_data(t::CXType) -> Bool\nis_plain_old_data(t::CLType) -> Bool\n\nReturn true if the CXType is a plain old data type. Wrapper for libclang\'s clang_isPODType.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.is_translation_unit-Tuple{Clang.LibClang.CXCursorKind}",
    "page": "API Reference",
    "title": "Clang.is_translation_unit",
    "category": "method",
    "text": "is_translation_unit(k::CXcursorKind) -> Bool\nis_translation_unit(c::CLCursor) -> Bool\n\nReturn true if the given cursor kind represents a translation unit. Wrapper for libclang\'s clang_isTranslationUnit.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.is_typedef_anon-Tuple{CLCursor,CLCursor}",
    "page": "API Reference",
    "title": "Clang.is_typedef_anon",
    "category": "method",
    "text": "is_typedef_anon(current::CLCursor, next::CLCursor) -> Bool\n\nReturn true if the current cursor is an typedef anonymous struct/enum.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isattr-Tuple{Clang.LibClang.CXCursorKind}",
    "page": "API Reference",
    "title": "Clang.isattr",
    "category": "method",
    "text": "isattr(k::CXcursorKind) -> Bool\nisattr(c::CLCursor) -> Bool\n\nReturn true if the given cursor kind represents an attribute. Wrapper for libclang\'s clang_isAttribute.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isbit-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.isbit",
    "category": "method",
    "text": "isbit(c::CXCursor) -> Bool\nisbit(c::CLCursor) -> Bool\n\nReturn true if the cursor specifies a Record member that is a bitfield. Wrapper for libclang\'s clang_Cursor_isBitField.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isbuiltin-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.isbuiltin",
    "category": "method",
    "text": "isbuiltin(c::CXCursor) -> Bool\nisbuiltin(c::CLCursor) -> Bool\n\nDetermine whether a  CXCursor that is a macro, is a builtin one. Wrapper for libclang\'s clang_Cursor_isMacroBuiltin.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isdecl-Tuple{Clang.LibClang.CXCursorKind}",
    "page": "API Reference",
    "title": "Clang.isdecl",
    "category": "method",
    "text": "isdecl(k::CXcursorKind) -> Bool\nisdecl(c::CLCursor) -> Bool\n\nReturn true if the given cursor kind represents a declaration. Wrapper for libclang\'s clang_isDeclaration.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isdef-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.isdef",
    "category": "method",
    "text": "isdef(c::CXCursor) -> Bool\nisdef(c::CLCursor) -> Bool\n\nReturn true if the declaration pointed to by this cursor is also a definition of that entity. Wrapper for libclang\'s clang_isCursorDefinition.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isexpr-Tuple{Clang.LibClang.CXCursorKind}",
    "page": "API Reference",
    "title": "Clang.isexpr",
    "category": "method",
    "text": "isexpr(k::CXcursorKind) -> Bool\nisexpr(c::CLCursor) -> Bool\n\nReturn true if the given cursor kind represents an expression. Wrapper for libclang\'s clang_isExpression.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isfunctionlike-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.isfunctionlike",
    "category": "method",
    "text": "isfunctionlike(c::CXCursor) -> Bool\nisfunctionlike(c::CLCursor) -> Bool\n\nDetermine whether a CXCursor that is a macro, is function like. Wrapper for libclang\'s clang_Cursor_isMacroFunctionLike.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isinlined-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.isinlined",
    "category": "method",
    "text": "isinlined(c::CXCursor) -> Bool\nisinlined(c::CLCursor) -> Bool\n\nDetermine whether a CXCursor that is a function declaration, is an inline declaration. Wrapper for libclang\'s clang_Cursor_isFunctionInlined.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isnull-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.isnull",
    "category": "method",
    "text": "isnull(c::CXCursor) -> Bool\nisnull(c::CLCursor) -> Bool\n\nReturn true if cursor is null. Wrapper for libclang\'s clang_Cursor_isNull.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.ispreprocessing-Tuple{Clang.LibClang.CXCursorKind}",
    "page": "API Reference",
    "title": "Clang.ispreprocessing",
    "category": "method",
    "text": "ispreprocessing(k::CXcursorKind) -> Bool\nispreprocessing(c::CLCursor) -> Bool\n\nReturn true if the given cursor kind represents a preprocessing element, such as a preprocessor directive or macro instantiation. Wrapper for libclang\'s clang_isPreprocessing.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isref-Tuple{Clang.LibClang.CXCursorKind}",
    "page": "API Reference",
    "title": "Clang.isref",
    "category": "method",
    "text": "isref(k::CXcursorKind) -> Bool\nisref(c::CLCursor) -> Bool\n\nReturn true if the given cursor kind represents a simple reference. Note that other kinds of cursors (such as expressions) can also refer to other cursors. Use getref to determine whether a particular cursor refers to another entity. Wrapper for libclang\'s clang_isReference.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isrestrict-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.isrestrict",
    "category": "method",
    "text": "isrestrict(t::CXType) -> Bool\nisrestrict(t::CLType) -> Bool\n\nDetermine whether a CXType has the \"restrict\" qualifier set, without looking through typedefs that may have added \"restrict\" at a different level. Wrapper for libclang\'s clang_isRestrictQualifiedType.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isstmt-Tuple{Clang.LibClang.CXCursorKind}",
    "page": "API Reference",
    "title": "Clang.isstmt",
    "category": "method",
    "text": "isstmt(k::CXcursorKind) -> Bool\nisstmt(c::CLCursor) -> Bool\n\nReturn true if the given cursor kind represents a statement. Wrapper for libclang\'s clang_isStatement.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isunexposed-Tuple{Clang.LibClang.CXCursorKind}",
    "page": "API Reference",
    "title": "Clang.isunexposed",
    "category": "method",
    "text": "isunexposed(k::CXcursorKind) -> Bool\n\nReturn true if the given cursor kind represents a currently unexposed piece of the AST (e.g., CXCursorUnexposedStmt). Wrapper for libclang\'s `clangisUnexposed`.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isvariadic-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.isvariadic",
    "category": "method",
    "text": "isvariadic(c::CXCursor) -> Bool\nisvariadic(c::CLCursor) -> Bool\n\nReturn true if the given cursor is a variadic function or method. Wrapper for libclang\'s clang_Cursor_isVariadic.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isvariadic-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.isvariadic",
    "category": "method",
    "text": "isvariadic(t::CXType) -> Bool\nisvariadic(t::CLType) -> Bool\n\nReturn true if the CXType is a variadic function type. Wrapper for libclang\'s clang_isFunctionTypeVariadic.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isvolatile-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.isvolatile",
    "category": "method",
    "text": "isvolatile(t::CXType) -> Bool\nisvolatile(t::CLType) -> Bool\n\nDetermine whether a CXType has the \"volatile\" qualifier set, without looking through typedefs that may have added \"volatile\" at a different level. Wrapper for libclang\'s clang_isVolatileQualifiedType.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.kind-Tuple{CLCursor}",
    "page": "API Reference",
    "title": "Clang.kind",
    "category": "method",
    "text": "kind(c::CLCursor) -> CXCursorKind\n\nReturn the kind of the given cursor. Note this method directly reads CXCursor\'s kind field, which won\'t invoke additional clang_getCursorKind function calls.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.kind-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.kind",
    "category": "method",
    "text": "kind(c::CXCursor) -> CXCursorKind\n\nReturn the kind of the given cursor. Wrapper for libclang\'s clang_getCursorKind.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.kind-Tuple{Clang.LibClang.CXToken}",
    "page": "API Reference",
    "title": "Clang.kind",
    "category": "method",
    "text": "kind(t::CXToken) -> CXTokenKind\nkind(t::CLToken) -> CXTokenKind\n\nReturn the kind of the given token.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.kind-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.kind",
    "category": "method",
    "text": "kind(t::CXType) -> CXTypeKind\nkind(t::CLType) -> CXTypeKind\n\nReturn the kind of the given type.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.location-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.location",
    "category": "method",
    "text": "location(c::CXCursor) -> CXSourceLocation\nlocation(c::CLCursor) -> CXSourceLocation\n\nReturn the physical location of the source constructor referenced by the given cursor. Wrapper for libclang\'s clang_getCursorLocation.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.location-Tuple{Ptr{Nothing},Clang.LibClang.CXToken}",
    "page": "API Reference",
    "title": "Clang.location",
    "category": "method",
    "text": "location(tu::TranslationUnit, t::CLToken) -> CXSourceLocation\nlocation(tu::TranslationUnit, t::CXToken) -> CXSourceLocation\nlocation(tu::CXTranslationUnit, t::CXToken) -> CXSourceLocation\n\nReturn the source location of the given token.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.name-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.name",
    "category": "method",
    "text": "name(c::CXCursor) -> String\nname(c::CLCursor) -> String\n\nReturn the display name for the entity referenced by this cursor.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.name_safe-Tuple{AbstractString}",
    "page": "API Reference",
    "title": "Clang.name_safe",
    "category": "method",
    "text": "name_safe(name::AbstractString)\n\nReturn a valid Julia variable name, prefixed with \"_\" if the name is conflict with Julia\'s reserved words.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.parse_header-Tuple{AbstractString}",
    "page": "API Reference",
    "title": "Clang.parse_header",
    "category": "method",
    "text": "parse_header(header::AbstractString; index::Index=Index(), args::Vector{String}=String[],\n             includes::Vector{String}=String[], flags=CXTranslationUnit_None) -> TranslationUnit\n\nReturn the TranslationUnit for a given header. This is the main entry point for parsing. See also parse_headers.\n\nArguments\n\nheader::AbstractString: the header file to parse.\nindex::Index: CXIndex pointer (pass to avoid re-allocation).\nargs::Vector{String}: compiler switches as string array, eg: [\"-x\", \"c++\", \"-fno-elide-type\"].\nincludes::Vector{String}: vector of extra include directories to search.\nflags: bitwise OR of CXTranslationUnit_Flags.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.parse_headers-Tuple{Array{String,1}}",
    "page": "API Reference",
    "title": "Clang.parse_headers",
    "category": "method",
    "text": "parse_headers(headers::Vector{String}; index::Index=Index(), args::Vector{String}=String[], includes::Vector{String}=String[],\n    flags = CXTranslationUnit_DetailedPreprocessingRecord | CXTranslationUnit_SkipFunctionBodies) -> Dict\n\nReturn a TranslationUnit Dict for the given headers. See also parse_header.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.pointee_type-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.pointee_type",
    "category": "method",
    "text": "pointee_type(t::CXType) -> CXType\npointee_type(t::CLType) -> CLType\n\nReturn the type of the pointee for pointer types. Wrapper for libclang\'s clang_getPointeeType.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.print_buffer-Tuple{Any,Any}",
    "page": "API Reference",
    "title": "Clang.print_buffer",
    "category": "method",
    "text": "Pretty-print a buffer of expressions (and comments) to an output stream Adds blank lines at appropriate places for readability\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.resolve_type-Tuple{CLType}",
    "page": "API Reference",
    "title": "Clang.resolve_type",
    "category": "method",
    "text": "resolve_type(t::CLType) -> CLType\n\nThis function attempts to work around some limitations of the current libclang API.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.result_type-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.result_type",
    "category": "method",
    "text": "result_type(c::CXCursor) -> CXType\nresult_type(c::CLFunctionDecl) -> CLType\nresult_type(c::CLCXXMethod) -> CLType\n\nReturn the return type associated with a given cursor. This only returns a valid type if the cursor refers to a function or method. Wrapper for libclang\'s clang_getCursorResultType.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.result_type-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.result_type",
    "category": "method",
    "text": "result_type(t::CXType) -> CXType\nresult_type(t::CLFunctionProto) -> CLType\nresult_type(t::CLFunctionNoProto) -> CLType\n\nReturn the return type associated with a function type. Wrapper for libclang\'s clang_getResultType.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.return_type",
    "page": "API Reference",
    "title": "Clang.return_type",
    "category": "function",
    "text": "return_type(c::CLCursor, resolve::Bool=true) -> CXtype\n\nReturn the return type associated with a function/method cursor.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.search-Tuple{Array{CLCursor,1},Function}",
    "page": "API Reference",
    "title": "Clang.search",
    "category": "method",
    "text": "search(cursors::Vector{CLCursor}, ismatch::Function) -> Vector{CLCursor}\n\nReturn vector of CLCursors that match predicate. ismatch is a function that accepts a CLCursor argument.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.spelling-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.spelling",
    "category": "method",
    "text": "spelling(c::CXCursor) -> String\nspelling(c::CLCursor) -> String\n\nReturn a name for the entity referenced by this cursor.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.spelling-Tuple{Clang.LibClang.CXTypeKind}",
    "page": "API Reference",
    "title": "Clang.spelling",
    "category": "method",
    "text": "spelling(kind::CXTypeKind) -> String\n\nReturn the spelling of a given CXTypeKind.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.spelling-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.spelling",
    "category": "method",
    "text": "spelling(t::CXType) -> String\nspelling(t::CLType) -> String\n\nPretty-print the underlying type using the rules of the language of the translation unit from which it came. If the type is invalid, an empty string is returned. Wrapper for libclang\'s clang_getTypeSpelling.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.spelling-Tuple{Ptr{Nothing},Clang.LibClang.CXToken}",
    "page": "API Reference",
    "title": "Clang.spelling",
    "category": "method",
    "text": "spelling(tu::TranslationUnit, t::CLToken) -> String\nspelling(tu::TranslationUnit, t::CXToken) -> String\nspelling(tu::CXTranslationUnit, t::CXToken) -> String\n\nReturn the spelling of the given token. The spelling of a token is the textual representation of that token, e.g., the text of an identifier or keyword.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.spelling-Tuple{TranslationUnit}",
    "page": "API Reference",
    "title": "Clang.spelling",
    "category": "method",
    "text": "spelling(tu::TranslationUnit) -> String\n\nReturn the original translation unit source file name.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.symbol_safe-Tuple{AbstractString}",
    "page": "API Reference",
    "title": "Clang.symbol_safe",
    "category": "method",
    "text": "symbol_safe(name::AbstractString)\n\nSame as name_safe, but return a Symbol.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.tokenize-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.tokenize",
    "category": "method",
    "text": "tokenize(c::CXCursor) -> TokenList\ntokenize(c::CLCursor) -> TokenList\n\nReturn a TokenList from the given cursor.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.type-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.type",
    "category": "method",
    "text": "type(c::CXCursor) -> CXType\ntype(c::CLCursor) -> CLType\n\nReturn the type of a CXCursor (if any). To get the cursor from a type, see typedecl. Wrapper for libclang\'s clang_getCursorType.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.typedecl-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.typedecl",
    "category": "method",
    "text": "typedecl(t::CXType) -> CXCursor\ntypedecl(t::CLType) -> CLCursor\n\nReturn the cursor for the declaration of the given type. To get the type of the cursor, see type. Wrapper for libclang\'s clang_getTypeDeclaration.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.typedef_name-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.typedef_name",
    "category": "method",
    "text": "typedef_name(t::CXType) -> String\ntypedef_name(t::CLType) -> String\n\nReturn the typedef name of the given type. Wrapper for libclang\'s clang_getTypedefName.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.typedef_type-Tuple{CLCursor}",
    "page": "API Reference",
    "title": "Clang.typedef_type",
    "category": "method",
    "text": "typedef_type(c::CLCursor) -> CXType\n\nReturn the underlying type of a typedef declaration.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.typesize-Tuple{CLType}",
    "page": "API Reference",
    "title": "Clang.typesize",
    "category": "method",
    "text": "typesize(t::CLType) -> Int\ntypesize(c::CLCursor) -> Int\n\nReturn field declaration size.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.underlying_type-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.underlying_type",
    "category": "method",
    "text": "underlying_type(c::CLTypedefDecl) -> CLType\n\nReturn the underlying type of a typedef declaration. Wrapper for libclang\'s clang_getTypedefDeclUnderlyingType.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.value-Tuple{CLEnumConstantDecl}",
    "page": "API Reference",
    "title": "Clang.value",
    "category": "method",
    "text": "value(c::CLCursor) -> Int\n\nReturn the integer value of an enum constant declaration.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.wrap!-Tuple{AbstractContext,CLEnumDecl}",
    "page": "API Reference",
    "title": "Clang.wrap!",
    "category": "method",
    "text": "wrap!(ctx::AbstractContext, cursor::CLEnumDecl)\n\nSubroutine for handling enum declarations.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.wrap!-Tuple{AbstractContext,CLFunctionDecl}",
    "page": "API Reference",
    "title": "Clang.wrap!",
    "category": "method",
    "text": "wrap!(ctx::AbstractContext, cursor::CLFunctionDecl)\n\nSubroutine for handling function declarations. Note that VarArg functions are not supported.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.wrap!-Tuple{AbstractContext,CLMacroDefinition}",
    "page": "API Reference",
    "title": "Clang.wrap!",
    "category": "method",
    "text": "wrap!(ctx::AbstractContext, cursor::CLMacroDefinition)\n\nSubroutine for handling macro declarations.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.wrap!-Tuple{AbstractContext,CLStructDecl}",
    "page": "API Reference",
    "title": "Clang.wrap!",
    "category": "method",
    "text": "wrap!(ctx::AbstractContext, cursor::CLStructDecl)\n\nSubroutine for handling struct declarations.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.wrap!-Tuple{AbstractContext,CLTypeRef}",
    "page": "API Reference",
    "title": "Clang.wrap!",
    "category": "method",
    "text": "wrap!(ctx::AbstractContext, cursor::CLTypeRef)\n\nFor now, we just skip CXCursor_TypeRef cursors.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.wrap!-Tuple{AbstractContext,CLTypedefDecl}",
    "page": "API Reference",
    "title": "Clang.wrap!",
    "category": "method",
    "text": "wrap!(ctx::AbstractContext, cursor::CLTypedefDecl)\n\nSubroutine for handling typedef declarations.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.wrap!-Tuple{AbstractContext,CLUnionDecl}",
    "page": "API Reference",
    "title": "Clang.wrap!",
    "category": "method",
    "text": "wrap!(ctx::AbstractContext, cursor::CLUnionDecl)\n\nSubroutine for handling union declarations.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.Index",
    "page": "API Reference",
    "title": "Clang.Index",
    "category": "type",
    "text": "Index(exclude_decls_from_PCH, display_diagnostics)\n\nProvide a shared context for creating translation units.\n\nArguments\n\nexclude_decls_from_PCH: whether to allow enumeration of \"local\" declarations.\ndisplay_diagnostics: whether to display diagnostics.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.TokenList",
    "page": "API Reference",
    "title": "Clang.TokenList",
    "category": "type",
    "text": "Tokenizer access\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.TranslationUnit",
    "page": "API Reference",
    "title": "Clang.TranslationUnit",
    "category": "type",
    "text": "TranslationUnit(idx, source, args)\nTranslationUnit(idx, source, args, unsavedFiles, options)\n\nParse the given source file and the translation unit corresponding to that file.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.WrapContext",
    "page": "API Reference",
    "title": "Clang.WrapContext",
    "category": "type",
    "text": "WrapContext\n\nStore shared information about the wrapping session.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.CLANG_JULIA_TYPEMAP",
    "page": "API Reference",
    "title": "Clang.CLANG_JULIA_TYPEMAP",
    "category": "constant",
    "text": "Mapping from libclang types to Julia types\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.RESERVED_ARG_TYPES",
    "page": "API Reference",
    "title": "Clang.RESERVED_ARG_TYPES",
    "category": "constant",
    "text": "Unsupported argument types\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.RESERVED_WORDS",
    "page": "API Reference",
    "title": "Clang.RESERVED_WORDS",
    "category": "constant",
    "text": "Reserved Julia identifiers will be prepended with \"_\"\n\n\n\n\n\n"
},

{
    "location": "api/#Base.isconst-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Base.isconst",
    "category": "method",
    "text": "isconst(t::CXType) -> Bool\nisconst(t::CLType) -> Bool\n\nDetermine whether a CXType has the \"const\" qualifier set, without looking through typedefs that may have added \"const\" at a different level. Wrapper for libclang\'s clang_isConstQualifiedType.\n\n\n\n\n\n"
},

{
    "location": "api/#Base.isvalid-Tuple{Clang.LibClang.CXCursorKind}",
    "page": "API Reference",
    "title": "Base.isvalid",
    "category": "method",
    "text": "isvalid(k::CXcursorKind) -> Bool\nisvalid(c::CLCursor) -> Bool\n\nReturn true if the given cursor kind represents an valid cursor. Wrapper for libclang\'s clang_isInvalid.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.calling_conv-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.calling_conv",
    "category": "method",
    "text": "calling_conv(t::CXType) -> CXCallingConv\ncalling_conv(t::CLFunctionProto) -> CXCallingConv\ncalling_conv(t::CLFunctionNoProto) -> CXCallingConv\n\nReturn the calling convention associated with a function type. Wrapper for libclang\'s clang_getFunctionTypeCallingConv.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.handle_macro_exprn-Tuple{TokenList,Int64}",
    "page": "API Reference",
    "title": "Clang.handle_macro_exprn",
    "category": "method",
    "text": "handle_macro_exprn(tokens::TokenList, pos::Int)\n\nFor handling of #define\'d constants, allows basic expressions but bails out quickly.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isanonymous-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.isanonymous",
    "category": "method",
    "text": "isanonymous(c::CXCursor) -> Bool\nisanonymous(c::CLCursor) -> Bool\n\nReturn true if the given cursor represents an anonymous record declaration(C++). Wrapper for libclang\'s clang_Cursor_isAnonymous.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isvalid-Tuple{Clang.LibClang.CXType}",
    "page": "API Reference",
    "title": "Clang.isvalid",
    "category": "method",
    "text": "isvalid(t::CXType) -> Bool\nisvalid(t::CLType) -> Bool\n\nReturn true if the type is a valid type.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.isvirtual-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.isvirtual",
    "category": "method",
    "text": "isvirtual(c::CXCursor) -> Bool\nisvirtual(c::CLCursor) -> Bool\n\nReturn true if the base class specified by the cursor with kind CXCXXBaseSpecifier is virtual. Wrapper for libclang\'s `clangisVirtualBase`.\n\n\n\n\n\n"
},

{
    "location": "api/#Clang.linkage-Tuple{Clang.LibClang.CXCursor}",
    "page": "API Reference",
    "title": "Clang.linkage",
    "category": "method",
    "text": "linkage(c::CXCursor) -> CXLinkageKind\nlinkage(c::CLCursor) -> CXLinkageKind\n\nReturn the linkage of the entity referred to by a given cursor. Wrapper for libclang\'s clang_getCursorLinkage.\n\n\n\n\n\n"
},

{
    "location": "api/#API-Reference-1",
    "page": "API Reference",
    "title": "API Reference",
    "category": "section",
    "text": "Modules = [Clang]\nOrder   = [:constant, :function, :type]"
},

]}
