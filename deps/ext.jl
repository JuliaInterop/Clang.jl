let 
    function find_library(libname,filename)
        try 
            push!(DL_LOAD_PATH, joinpath(Pkg.dir(), "Clang", "deps", "usr", "lib"))
            dl = dlopen(libname)
        catch
            try 
                dl = dlopen(libname)
                dlclose(dl)
            catch
                error("Failed to find required library "*libname*". Try re-running the package script using Pkg.runbuildscript(\"pkg\")")
            end
        end
    end
    find_library("libwrapclang","libwrapclang")
end
