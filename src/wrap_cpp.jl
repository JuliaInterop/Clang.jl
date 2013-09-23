module wrap_cpp

using Clang.cindex

function base_classes(c)
	search(c, isa(c, cindex.CXXBaseSpecifier))
end

end # module wrap_cpp
