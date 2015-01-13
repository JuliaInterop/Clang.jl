using Base.Test
using Clang.wrap_c

headername = "cxx/c_struct_typedef.h"
wc = wrap_c.init(;  headers = [headername], header_wrapped=(a,b)->true)
parsed = wrap_c.parse_c_headers(wc)
obuf = wc.output_bufs[headername]
wrap_c.wrap_header(wc, parsed[headername], headername, obuf)
common_buf = wrap_c.dump_to_buf(wc.common_buf)
io = IOBuffer()
wrap_c.print_buffer(io, common_buf)
str = takebuf_string(io)
@test str == "\ntype Str\n    x::Cint\nend\n"
