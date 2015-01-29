#
# Example script to wrap PETSc
#

using Clang.cindex
using Clang.wrap_c
using Compat

PETSC_INCLUDE = "/usr/include/petsc"
MPI_INCLUDE = "/usr/include/openmpi"

petsc_header = [joinpath(PETSC_INCLUDE, "petsc.h")]

# Set up include paths
clang_includes = ASCIIString[]
push!(clang_includes, PETSC_INCLUDE)
push!(clang_includes, MPI_INCLUDE)

# Clang arguments
clang_extraargs = ["-v"]
# clang_extraargs = ["-D", "__STDC_LIMIT_MACROS", "-D", "__STDC_CONSTANT_MACROS"]

# Callback to test if a header should actually be wrapped (for exclusion)
function wrap_header(top_hdr::ASCIIString, cursor_header::ASCIIString)
    return startswith(dirname(cursor_header), PETSC_INCLUDE)
end

lib_file(hdr::ASCIIString) = "petsc"
output_file(hdr::ASCIIString) = "PETSc.jl"

function wrap_cursor(name::ASCIIString, cursor)
    exc = false
    exc |= contains(name, "MPI")
    return !exc
end

const wc = wrap_c.init(;
                        headers = petsc_header,
                        output_file = "libPETSc_h.jl",
                        common_file = "libPETSc_common.jl",
                        clang_includes      = clang_includes,
                        clang_args          = clang_extraargs,
                        header_wrapped      = wrap_header,
                        header_library      = lib_file,
                        header_outputfile   = output_file,
                        cursor_wrapped      = wrap_cursor,
                        clang_diagnostics = true)

run(wc)
