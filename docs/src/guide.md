# Usage Guide
Clang is an open-source compiler built on the LLVM framework and targeting C, C++, and Objective-C (LLVM is also the JIT backend for Julia). Due to a highly modular design, Clang has in recent years become the core of a growing number of projects utilizing pieces of the compiler, such as tools for source-to-source translation, static analysis and security evaluation, and editor tools for code completion, formatting, etc.

While LLVM and Clang are written in C++, the Clang project maintains a C-exported interface called "libclang" which provides access to the abstract syntax tree and type representations. Thanks to the ubiquity of support for C calling conventions, a number of languages have utilized libclang as a basis for tooling related to C and C++.

The Clang.jl Julia package wraps libclang, provides a small convenience API for Julia-style programming, and provides a C-to-Julia wrapper generator built on libclang functionality.

## Parsing and Wrapping C with Clang and Julia
In this section, I will introduce Clang.jl and explore both C parsing and C/Julia wrapper generation.
Here is the header file `example.h` used in the following examples:  
```c
// example.h
struct ExStruct {
    int    kind;
    char*  name;
    float* data;
};

void* ExFunction (int kind, char* name, float* data) {
    struct ExStruct st;
    st.kind = kind;
    st.name = name;
    st.data = data;
}
```

### Printing Struct Fields
To motivate the discussion with a succinct example, consider this struct:
```c
struct ExStruct {
    int    kind;
    char*  name;
    float* data;
};
```
Parsing and querying the fields of this struct requires just a few lines of code:
```julia
julia> using Clang
[ Info: Recompiling stale cache file /Users/gnimuc/.julia/compiled/v1.0/Clang/uO7n9.ji for Clang [40e3b903-d033-50b4-a0cc-940c62c95e31]

julia> trans_unit = parse_header("example.h")
TranslationUnit(Ptr{Nothing} @0x00007fa9ac6a9f90, Index(Ptr{Nothing} @0x00007fa9ac6b4080, 0, 1))

julia> root_cursor = getcursor(trans_unit)
CLCursor (Clang.CLTranslationUnit) example.h

julia> struct_cursor = search(root_cursor, "ExStruct")[1]
CLCursor (Clang.CLStructDecl) ExStruct

julia> for c in children(struct_cursor)  # print children
           println("Cursor: ", c, "\n  Kind: ", kind(c), "\n  Name: ", name(c), "\n  Type: ", type(c))
       end
Cursor: CLCursor (Clang.CLFieldDecl) kind
  Kind: CXCursor_FieldDecl(6)
  Name: kind
  Type: CLType (Clang.CLInt)
Cursor: CLCursor (Clang.CLFieldDecl) name
  Kind: CXCursor_FieldDecl(6)
  Name: name
  Type: CLType (Clang.CLPointer)
Cursor: CLCursor (Clang.CLFieldDecl) data
  Kind: CXCursor_FieldDecl(6)
  Name: data
  Type: CLType (Clang.CLPointer)
```

#### AST Representation
Let's examine the example above, starting with the variable `trans_unit`:
```julia
julia> trans_unit
TranslationUnit(Ptr{Nothing} @0x00007fa9ac6a9f90, Index(Ptr{Nothing} @0x00007fa9ac6b4080, 0, 1))
```
A `TranslationUnit` is the entry point to the libclang AST. In the example above, `trans_unit` is a `TranslationUnit` for the parsed file `example.h`. The libclang AST is represented as a directed acyclic graph of cursor nodes carrying three pieces of essential information:

* Kind: purpose of cursor node
* Type: type of the object represented by cursor
* Children: list of child nodes

```julia
julia> root_cursor
CLCursor (Clang.CLTranslationUnit) example.h
```
`root_cursor` is the root cursor node of the `TranslationUnit`.

In Clang.jl the cursor type is encapsulated by a Julia type deriving from the abstract type CLCursor. Under the hood, libclang represents each cursor (CXCursor) kind and type (CXType) as an enum value. These enum values are used to automatically map all CXCursor and CXType objects to Julia types. Thus, it is possible to write multiple-dispatch methods against CLCursor or CLType variables.

```julia
julia> dump(root_cursor)
Clang.CLTranslationUnit
  cursor: Clang.LibClang.CXCursor
    kind: Clang.LibClang.CXCursorKind CXCursor_TranslationUnit(300)
    xdata: Int32 0
    data: Tuple{Ptr{Nothing},Ptr{Nothing},Ptr{Nothing}}
      1: Ptr{Nothing} @0x00007fa9ae362ae8
      2: Ptr{Nothing} @0x0000000000000001
      3: Ptr{Nothing} @0x00007fa9ac6a9f90
```

Under the hood, libclang represents each cursor kind and type as an enum value.
These enums are translated into Julia as a subtype of `Cenum`:
```julia
julia> dump(Clang.LibClang.CXCursorKind)
Clang.LibClang.CXCursorKind <: Clang.LibClang.CEnum.Cenum{UInt32}
```

The example demonstrates two different ways of accessing child nodes of a given cursor. Here,
the children function returns an iterator over the child nodes of the given cursor:

```julia
julia> children(struct_cursor)
3-element Array{CLCursor,1}:
 CLCursor (Clang.CLFieldDecl) kind
 CLCursor (Clang.CLFieldDecl) name
 CLCursor (Clang.CLFieldDecl) data
```
And here, the search function returns a list of child node(s) matching the given name:

```julia
julia> search(root_cursor, "ExStruct")
1-element Array{CLCursor,1}:
 CLCursor (Clang.CLStructDecl) ExStruct
```

#### Type representation
The above example also demonstrates querying of the type associated with a given cursor using
the helper function `type`. In the output:

```julia
Cursor: CLCursor (Clang.CLFieldDecl) kind
  Kind: CXCursor_FieldDecl(6)
  Name: kind
  Type: CLType (Clang.CLInt)
Cursor: CLCursor (Clang.CLFieldDecl) name
  Kind: CXCursor_FieldDecl(6)
  Name: name
  Type: CLType (Clang.CLPointer)
Cursor: CLCursor (Clang.CLFieldDecl) data
  Kind: CXCursor_FieldDecl(6)
  Name: data
  Type: CLType (Clang.CLPointer)
```

Each `CLFieldDecl` cursor has an associated `CLType` object, with an identity reflecting the field type for the given struct member. It is critical to note the difference between the representation for the *kind* field and the name and data fields. *kind* is represented directly as an `CLInt` object, but name and data are represented as `CLPointer` CLTypes. As explored in the next section, the full type of the `CLPointer` can be queried to retrieve the full `char *` and `float *` types of these members. User-defined types are captured using a similar scheme.


## Function Arguments and Types
To further explore type representations, consider the following function (included in example.h):
```c
void* ExFunction (int kind, char* name, float* data) {
    struct ExStruct st;
    st.kind = kind;
    st.name = name;
    st.data = data;
}
```
To find the cursor for this function declaration, we use function `search` to retrieve nodes of kind  `CXCursor_FunctionDecl` , and select the final one in the list:
```julia
julia> using Clang.LibClang  # CXCursor_FunctionDecl is exposed from LibClang

julia> fdecl = search(root_cursor, CXCursor_FunctionDecl)[end]
CLCursor (Clang.CLFunctionDecl) ExFunction(int, char *, float *)

julia> fdecl_children = [c for c in children(fdecl)]
4-element Array{CLCursor,1}:
 CLCursor (Clang.CLParmDecl) kind
 CLCursor (Clang.CLParmDecl) name
 CLCursor (Clang.CLParmDecl) data
 CLCursor (Clang.CLCompoundStmt)
```
The first three children are `CLParmDecl` cursors with the same name as the arguments in the function signature. Checking the types of the `CLParmDecl` cursors indicates a similarity to the function signature:
```julia
julia> [type(t) for t in fdecl_children[1:3]]
3-element Array{CLType,1}:
 CLType (Clang.CLInt)     
 CLType (Clang.CLPointer)
 CLType (Clang.CLPointer)
```
And, finally, retrieving the target type of each `CLPointer` argument confirms that these cursors represent the function argument type declaration:
```julia
julia> [pointee_type(type(t)) for t in fdecl_children[2:3]]
2-element Array{CLType,1}:
 CLType (Clang.CLChar_S)
 CLType (Clang.CLFloat)
```

## Printing Indented Cursor Hierarchy
As a closing example, here is a simple, indented AST printer using `CLType`- and `CLCursor`-related functions, and utilizing various aspects of Julia's type system.
```julia
printind(ind::Int, st...) = println(join([repeat(" ", 2*ind), st...]))

printobj(cursor::CLCursor) = printobj(0, cursor)
printobj(t::Clang.CLType) = join(typeof(t), " ", spelling(t))
printobj(t::Clang.CLInt) = t
printobj(t::Clang.CLPointer) = pointee_type(t)
printobj(ind::Int, t::CLType) = printind(ind, printobj(t))

function printobj(ind::Int, cursor::Union{Clang.CLFieldDecl, Clang.CLParmDecl})
    printind(ind+1, typeof(cursor), " ", printobj(type(cursor)), " ", name(cursor))
end

function printobj(ind::Int, node::Union{CLCursor,
                                        Clang.CLStructDecl,
                                        Clang.CLCompoundStmt,
                                        Clang.CLFunctionDecl,
                                        Clang.CLBinaryOperator})
    printind(ind, " ", typeof(node), " ", name(node))
    for c in children(node)
        printobj(ind + 1, c)
    end
end
```

```julia
julia> printobj(root_cursor)
 Clang.CLTranslationUnit example.h
   Clang.CLStructDecl ExStruct
      Clang.CLFieldDecl CLType (Clang.CLInt)  kind
      Clang.CLFieldDecl CLType (Clang.CLChar_S)  name
      Clang.CLFieldDecl CLType (Clang.CLFloat)  data
   Clang.CLFunctionDecl ExFunction(int, char *, float *)
      Clang.CLParmDecl CLType (Clang.CLInt)  kind
      Clang.CLParmDecl CLType (Clang.CLChar_S)  name
      Clang.CLParmDecl CLType (Clang.CLFloat)  data
     Clang.CLCompoundStmt
       Clang.CLDeclStmt
         Clang.CLVarDecl st
           Clang.CLTypeRef struct ExStruct
       Clang.CLBinaryOperator
         Clang.CLMemberRefExpr kind
           Clang.CLDeclRefExpr st
         Clang.CLUnexposedExpr kind
           Clang.CLDeclRefExpr kind
       Clang.CLBinaryOperator
         Clang.CLMemberRefExpr name
           Clang.CLDeclRefExpr st
         Clang.CLUnexposedExpr name
           Clang.CLDeclRefExpr name
       Clang.CLBinaryOperator
         Clang.CLMemberRefExpr data
           Clang.CLDeclRefExpr st
         Clang.CLUnexposedExpr data
           Clang.CLDeclRefExpr data
```
Note that a generic `printobj` function has been defined for the abstract `CLType` and `CLCursor` types, and multiple dispatch is used to define the printers for various specific types needing custom behavior. In particular, the following function handles all cursor types for which recursive printing of child nodes is required:
```julia
function printobj(ind::Int, node::Union{CLCursor,
                                        Clang.CLStructDecl,
                                        Clang.CLCompoundStmt,
                                        Clang.CLFunctionDecl})
```
