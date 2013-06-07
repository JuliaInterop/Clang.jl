include(joinpath(Pkg.dir(), "Clang", "deps", "ext.jl"))

module Clang
  include("cindex.jl")
  include("wrap_c.jl")
  try
    # Check for global variable USE_CLANG_CPP
    if(Main.USE_CLANG_CPP)
      warn("importing CPP support")
      include("wrap_cpp.jl")
    end
  catch
    # pass
  end
end
