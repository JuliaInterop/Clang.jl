module wrap_cpp

using Clang.cindex

export @vcall, @scall, @mcall

immutable CPPFunc
    fname::String
    args::Vector{CXCursor}
    rettype::CXCursor
end

function method_vt_index(cursor::cindex.CXCursor)
    if (cindex.CXXMethod_isVirtual(cursor) != 1)
        return -1
    end
    ccall( ("wci_getCXXMethodVTableIndex", :libwrapclang), Int32, (Ptr{Uint8},), cursor.data)
end

function method_mangled_name(cursor::cindex.CXCursor)
    bufr = zeros(Uint8, 1024)
    ccall( ("wci_getCXXMethodMangledName", :libwrapclang), Int32, (Ptr{Uint8},Ptr{Uint8}), cursor.data, bufr)
    bytestring(convert(Ptr{Uint8},bufr))
end


function cxxclass_cb(cursor::Ptr{Uint8}, data::Ptr{Void})
    cu = CXCursor()
    ccall(:memcpy, Void, (Ptr{Void},Ptr{Void}, Uint), cu.data, cursor, cindex.CXCursor_size)    
    holder = unsafe_pointer_to_objref(data)
    push!(holder, cu)
    return int(0)
end

function base_class(cursor::cindex.CXCursor)
    cb = cfunction(cxxclass_cb, Int, (Ptr{Uint8},Ptr{Void}))
    temp = CXCursor[]
    ccall( ("wci_getCXXClassParents", :libwrapclang), Int32, (Ptr{Uint8}, Ptr{Void}, Ptr{Void}), cursor.data, cb, pointer_from_objref(temp))
    if (length(temp) < 1) return None end
    return temp[1] # TODO: don't assume single inheritance...
end

function find_sym(name,liblist)
    libs = {dlopen(l)=>l for l in liblist}
    found = false
    dl = C_NULL
    for dl in keys(libs)
        try
            dlsym_e(dl, name)
        catch
            continue
        end
        found = true
    end
    if found
        println("symbol $name found in ", libs[dl])
        return splitdir(libs[dl])[end]
    else
        return None
        println("NOT FOUND")
    end
end

#function fixup_fname(wc::WrapContext, name::ASCIIString)
#end

function emit_cwrapper(func::CPPFunc, out::IOStream)
    ret_str = cindex.ctype_to_julia(func.rettype)
    print("$ret_str $func.fname(")
end

function get_function(cursor::CXCursor)
    fname  = spelling(cursor)
    args = wrap_c.function_args(cu)
    rettype = cindex.return_type(cu, false)

    CPPFunc(fname, ret_type, args)
end

#function wrap_header(header::String,
#                     wc::WrapContext,
#                     output::Wrappable)
#
## args: clsname, hmap, liblist
##  class_strm = open("vtk_classes.txt", "a")
##  hfile = clsname*".h"
##  hbase = hmap[hfile]
##  hpath = joinpath(hmap[hfile],hfile)
##  println(hpath)
##  
##  ### Instantiate parser
##
##  tu = cindex.tu_parse(idx, hpath,
##    ["-x", "c++",
##     map(x->"-I"*x, vtksubdirs)...,
##     extra_inc_paths...,
##     "-I$VTK_BUILD_PATH/includes",
##     "-I$JULIA_ROOT/deps/llvm-3.2/build/Release/lib/clang/3.2/include",
##     "-c"],
##    cindex.TranslationUnit_Flags.None)
##
##
##  ### Get translation unit
##
##  topcu = cindex.getTranslationUnitCursor(tu)
##  topcl = children(topcu)
##  println("  children: ", topcl.size)
#
## get add original to header list
## get a function
## get function arg types and names
## 
#
#    
#
#  ### Find requested class declaration
#
#  clscu = cindex.CXCursor()
#  found = false
#  for i=1:topcl.size
#    clscu = topcl[i]
#    if(cu_kind(clscu) == cindex.CurKind.CLASSDECL && name(clscu) == clsname)
#      found = true
#      break
#    end
#  end
#
#  if(!found)
#    warn("Unable to find class declaration for $clsname in header $hpath")
#    return
#  end
#
#  ### Get the base class name
#
#  basecu = wrap_cpp.base_class(clscu)
#  basename = ""
#  if (basecu == None)
#    println("No base for class: $clsname")
#  else
#    basename = name(basecu)
#  end
#
#  println("Wrapping: ", name(clscu), " base: ", basename)
#
#  ostrm = open(clsname*".jl", "w")
#
#  ### Class hierarchy membership
#  # add to global classmap
#  if (basename != "")
#    if (!has(classmap, basename))
#      classmap[basename] = ASCIIString[]
#    end
#    push!(ref(classmap, basename), clsname)
#  end
#  # print to wrapper
#  println(class_strm, "$clsname $basename")
##  println(ostrm, "abstract $clsname <: $basename")
#  println(ostrm, "cur_class = $clsname")
#
#  cl = children(clscu)
#
#  if (cl.size == 0)
#    # the first cursor may not be the real declaration if there 
#    #   is an export declaration in the way. Try to resolve underlying cursor.
#    clscu = cindex.getTypeDeclaration(cindex.resolve_type(cu_type(clscu)))
#    cl = children(clscu)
#    if (cl.size == 0)
#      warn("  No class members found for $clsname")
#      return
#    end
#  end
#
#
#  ### Global variables for run
#  first_stat = true
#  shlib = ""
#  
#  for i=1:cl.size
#    cu = cl[i]
#    debug && println(name(cu))
#    if (ty_kind(cu_type(cu)) != cindex.TypKind.FUNCTIONPROTO)
#      continue
#    end
#
#    fname  = spelling(cu)
#    mname = wrap_cpp.method_mangled_name(cu)
#    is_virt = bool(cindex.CXXMethod_isVirtual(cu))
#    is_stat = bool(cindex.CXXMethod_isStatic(cu))
#
#    if(fname == "New")
#      fname = clsname*"New"
#    elseif(fname == "operator=")
#      fname = clsname*"_eq"
#    end
#
#    if(first_stat && is_stat)
#      #shlib = wrap_cpp.find_sym(mname, liblist)
#      shlib = "libvtk"*match(r"(/cmn/git/VTK/)(.*)/", hpath).captures[2]
#      if shlib == None
#        continue
#      end
#      first_stat = false
#    end
#
#    vtidx = -1
#    if (!is_stat)
#      vtidx = wrap_cpp.method_vt_index(cu)
#    end
#    
#    # Skip any virtual functions with bad vt index. Should only be ctor/dtor
#    if (!is_stat && vtidx < 0)
#      warn("  bad vt index, skipping $fname")
#      continue
#    end
#
#    args = wrap_c.rep_args([wrap_c.rep_type(wrap_c.ctype_to_julia(x)) for x in wrap_c.function_args(cu)])
#    ret_type = wrap_c.rep_type(wrap_c.ctype_to_julia(cindex.return_type(cu, false)))
#
#
#    if (is_virt)
#      println(ostrm, "@vcall $vtidx $ret_type $fname $args")
#    elseif (is_stat)
#      println(ostrm, "@scall $ret_type $fname $args $mname \"$shlib\"")
#    else
#      println(ostrm, "@mcall $ret_type $fname $args $mname \"$shlib\"")
#    end
#  end # big for loop
# 
#  cindex.cl_dispose(cl)
#  close(ostrm)
#  close(class_strm)
#  cindex.tu_dispose(tu)
#end


end # module wrap_cpp
