using Clang.wrap_c
using Test

@testset "c struct" begin
    headername = joinpath(@__DIR__, "cxx", "c_struct_typedef.h")
    wrap_header(top_hdr, cursor_header) = startswith(basename(cursor_header), "c_struct_typedef.h")
    wc = wrap_c.init(;  headers=[headername], header_wrapped=wrap_header)
    parsed = wrap_c.parse_c_headers(wc)
    obuf = wc.output_bufs[headername]
    wrap_c.wrap_header(wc, parsed[headername], headername, obuf)
    common_buf = wrap_c.dump_to_buf(wc.common_buf)
    io = IOBuffer()
    wrap_c.print_buffer(io, common_buf)
    str = String(take!(io))
    @test str == "\nstruct Str\n    x::Cint\nend\n"
end
