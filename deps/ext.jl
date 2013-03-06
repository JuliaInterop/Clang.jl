let 
    function find_library(libname,filename)
        try 
            dl = dlopen(joinpath(Pkg.dir(),"Clang","deps","usr","lib",filename))
            ccall(:add_library_mapping,Int32,(Ptr{Uint8},Ptr{Uint8}),libname,dl)
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
