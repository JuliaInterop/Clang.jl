.. _doc-wrap_c:

C Wrapper Generator
===================

The Clang.jl wrapper generator is designed to be simple but flexible. The most basic invocation looks like this::

    context = wrap_c.init()
    
    headers = ["all.h", "your.h", "headers.h"]
    wrap_c.wrap_c_headers(context, headers)

However, it is usually necessary to set compiler arguments or customize output. The ``init`` function provides several arguments to configure the compiler, as well as callback functions used to determine various aspects of the output.

.. function:: init(; index, output_file, clang_args, clang_includes, clang_diagnostics, header_wrapped, header_library, header_outputfile)

    ``init``: Create wrapping context. Keyword args are available to specify options, but all options are given sane defaults.

    :param index: Union{}
    :param output_file:
    :type output_file: ASCIIString
    :param common_file: Name of common output file (types, constants, typealiases)
    :type common_file: ASCIIString
    :param clang_args:  
    :type clang_args: Vector{String}
    :param clang_includes: List of include paths for Clang to search.
    :type clang_includes: Vector{String}
    :param clang_diagnostics: Display Clang diagnostics
    :type clang_diagnostics: Bool
    :param header_wrapped: Function called to determine whether a header should be wrapped.
    :type header_wrapped: Function(header_file::ASCIIString, cursor_name::ASCIIString) -> Bool
    :param header_library: Function called to determine the library name for a given header.
    :param header_outputfile: Function called to determine the output filename for a given header.
    :type header_outputfile: Function(header::ASCIIString) -> Bool
    :param rewriter: Function to rewrite generated expressions
    :type rewriter: Function(Expr)


.. function:: wrap_c_headers(wc::WrapContext, headers::Vector{String})

    Generate a wrapping using given WrapContext for a list of headers. All parameters are governed by the WrapContext, see ``wrap_c.init`` for full listing of options.

.. type:: WrapContext
    
    ``WrapContext`` stores all information about the wrapping job.

    :field index: CXIndex to reuse for parsing.
    :field output_file: Name of main output file.
    :field common_file: Name of common output file (constants, types, and aliases)
    :field clang_includes:  Clang include paths
    :field clang_args: additional {"-Arg", "value"} pairs for clang
    :field header_wrapped: called to determine cursor inclusion status
    :field header_library: called to determine shared library for given header
    :field header_outfile: called to determine output file group for given header
    :field common_buf: Array
    :field cache_wrapped: [Internal] Set{ASCIIString}
    :field output_bufs: [Internal] DefaultOrderedDict{ASCIIString, Array{Any}}
    :field options: InternalOptions


