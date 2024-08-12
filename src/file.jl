struct CLFile
    file::CXFile
end

Base.convert(::Type{CLFile}, x::CXFile) = CLFile(x)
Base.cconvert(::Type{CXFile}, x::CLFile) = x
Base.unsafe_convert(::Type{CXFile}, x::CLFile) = x.file

Base.show(io::IO, x::CLFile) = print(io, """CLFile ("$(name(x))")""")


"""
    get_filename(file::CXFile) -> String
Return the complete file and path name of the given `file`.
"""
function get_filename(file::CXFile)
    name(CLFile(file))
end


"""
    name(file::CLFile) -> String
Return the complete file and path name of the given `file`.
"""
function name(file::CLFile)
    file |> clang_getFileName |> _cxstring_to_string
end

"""
    unique_id(file::CLFile) -> CXFileUniqueID
Return the unique id of the given `file`.
"""
function unique_id(file::CLFile)
    id = Ref{CXFileUniqueID}()
    ret = clang_getFileUniqueID(file, id)
    @assert ret==0 "Error getting unique id for $file"
    id[]
end
