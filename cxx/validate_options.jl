include("/Users/qi/.julia/dev/Clang/.claude/worktrees/generators-clang-cpp-api-02c8e6/cxx/CxxCodegen.jl")
using .CxxCodegen
d = mktempdir()
write(joinpath(d,"h.h"), "struct Keep { int a; };\nstruct Drop { int b; };\nint fn_keep(int x);\nstatic int fn_static(void);\n")
write(joinpath(d,"pro.jl"), "# PROLOGUE MARKER")
write(joinpath(d,"epi.jl"), "# EPILOGUE MARKER")
o = CxxCodegen.Options(library_name="libdemo", module_name="Demo",
        prologue_file_path=joinpath(d,"pro.jl"), epilogue_file_path=joinpath(d,"epi.jl"),
        export_symbol_prefixes=["fn_"], output_ignorelist=["Drop"],
        skip_static_functions=true, use_ccall_macro=true)
buf = IOBuffer(); CxxCodegen.generate([joinpath(d,"h.h")]; io=buf, options=o)
src = String(take!(buf))
println(src)
println("── checks ──")
for (label, ok) in [("module wrapper",  occursin("module Demo", src) && occursin("end # module", src)),
                    ("prologue",        occursin("PROLOGUE MARKER", src)),
                    ("epilogue",        occursin("EPILOGUE MARKER", src)),
                    ("export prefixes", occursin("PREFIXES", src)),
                    ("ignorelist drops Drop", !occursin("struct Drop", src)),
                    ("...but keeps Keep",     occursin("struct Keep", src)),
                    ("library_name used",     occursin("libdemo", src)),
                    ("@ccall form",           occursin("@ccall", src)),
                    ("static skipped",        !occursin("fn_static", src))]
    println(rpad(label, 26), ok ? "OK" : "FAILED")
end
