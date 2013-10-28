.. _doc-introduction:

Index API
---------
.. function:: parse_header(header::String; [index, diagnostics, cplusplus, clang_args, clang_includes, clang_flags])

    Main entry-point to Clang.jl. The required ``header`` argument specifies a header to parse. Returns the top CLCursor in the resulting TranslationUnit. Optional (keyword) arguments are as follows:

    :param index:           Pass to re-use a CXIndex over multiple runs.
    :type index: Ptr{CXIndex}
    :param diagnostics:     Print Clang diagnostics to STDERR.
    :type diagnostics: Bool
    :param cplusplus:       Parse as C++ file.
    :type cplusplus: Bool
    :param clang_args:      Vector of arguments (strings) to pass to Clang.
    :type clang_args: Vector{String}
    :param clang_includes:  Vector of include paths for Clang to search (note: path only, "-I" will be prepended automatically)
    :type clang_includes: Vector{String}
    :param clang_flags:     Bitwise OR of TranslationUnit_FLags enum. Not required in typical use; see libclang manual for more information.
    :rtype: TranslationUnit (<: CLCursor)

.. function:: children(c::CLCursor)

    Retrieve child nodes for given CLCursor. Julia's iterator protocol is supported, allowing constructs such as::
    
        for node in children(cursor)
            ...
        end

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

