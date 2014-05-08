using Clang.cindex
using Base.Test

top = cindex.parse_header("cxx/enums.hh"; cplusplus = true)

class = cindex.search(top, "A") |> first
enum = cindex.search(class, "MyEnum") |> first

Clang.wt.wrap(STDOUT, enum)
buf = IOBuffer()
Clang.wt.wrapjl(buf, :testlib, enum)
s = takebuf_string(buf)

for l in split(strip(s), "\n")
    l = strip(l)
    if !beginswith(l, "#")
        println(l)
        eval(parse(l))
    end
end

@test A_MyEnum <: Uint32
@test x == uint32(0)
@test y == uint32(1)
@test z == uint32(2)
