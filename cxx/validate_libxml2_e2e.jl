include("/Users/qi/.julia/dev/Clang/.claude/worktrees/generators-clang-cpp-api-02c8e6/cxx/CxxCodegen.jl")
using .CxxCodegen
INC="/Users/qi/.julia/artifacts/c99c0e2b61a41b4b2294b30e9f7f26e50c2e38eb/include/libxml2"
hdrs=[joinpath(INC,"libxml",f) for f in readdir(joinpath(INC,"libxml")) if endswith(f,".h")]
out="/tmp/LibXML2.jl"
o = CxxCodegen.Options(library_name="libxml2", module_name="LibXML2")
t0=time(); st = open(out,"w") do io; CxxCodegen.generate(hdrs; args=["-I$INC"], io=io, options=o); end
println("generated in ", round(time()-t0,digits=1), "s  ", st)
println("output: ", filesize(out), " bytes, ", countlines(out), " lines")
m = Module(:XTest); Core.eval(m, :(using CEnum: CEnum, @cenum)); Core.eval(m, :(const libxml2="libxml2"))
try
    Base.include(m, out); println("LOADS: OK")
    n = Base.invokelatest(() -> count(x -> begin v = try getfield(m,x) catch; nothing end
                                           v isa DataType && isconcretetype(v) && isstructtype(v) end,
                                      names(m; all=true)))
    println("concrete struct types defined: ", n)
catch e
    println("LOAD FAILED: ", first(split(sprint(showerror,e),"\n")))
end
