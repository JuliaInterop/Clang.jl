mutable struct CLCompilationDatabase
    ptr::CXCompilationDatabase
end

"""
    CLCompileCommand

Represents a command to compile the specific file.
Call [`getDirection`](@ref), [`getArguments`](@ref) and [`getArguments`](@ref) to get its attributes.
"""
mutable struct CLCompileCommand
    # Keep a reference to its root
    root::Any
    ptr::CXCompileCommand
end


mutable struct CLCompileCommands <: AbstractVector{CLCompileCommands}
    ptr::CXCompileCommands
end

"""
    CLCompilationDatabase(path::AbstractString)

Creates a compilation database from the database found in directory `path`.
"""
function CLCompilationDatabase(path::AbstractString)
    error = Ref{CXCompilationDatabase_Error}()
    ptr = clang_CompilationDatabase_fromDirectory(path, error)
    if error[] == CXCompilationDatabase_NoError
        db = CLCompilationDatabase(ptr)
        finalizer(db) do x
            clang_CompilationDatabase_dispose(x.ptr)
        end
    else
        nothing
    end
end

"""
    getCompileCommands(db::CLCompilationDatabase)

Get all compile commands from a compilation database.
"""
function getCompileCommands(db::CLCompilationDatabase)
    ptr = clang_CompilationDatabase_getAllCompileCommands(db.ptr)
    cmds = CLCompileCommands(ptr)
    finalizer(cmds) do x
        clang_CompileCommands_dispose(x.ptr)
    end
    cmds
end

"""
    getCompileCommands(db::CLCompilationDatabase, file::AbstractString)

Get all compile commands for a file given its complete path.
"""
function getCompileCommands(db::CLCompilationDatabase, file::AbstractString)
    ptr = clang_CompilationDatabase_getCompileCommands(db.ptr, file)
    cmds = CLCompileCommands(ptr)
    finalizer(cmds) do x
        clang_CompileCommands_dispose(x.ptr)
    end
    cmds
end


Base.size(cmds::CLCompileCommands) = (clang_CompileCommands_getSize(cmds.ptr),)


function Base.getindex(cmds::CLCompileCommands, i)
    ptr = clang_CompileCommands_getCommand(cmds.ptr, i - 1)
    CLCompileCommand(cmds, ptr)
end


getDirectory(cmd::CLCompileCommand) = _cxstring_to_string(clang_CompileCommand_getDirectory(cmd.ptr))

getFileName(cmd::CLCompileCommand) = _cxstring_to_string(clang_CompileCommand_getFilename(cmd.ptr))

function getArguments(cmd::CLCompileCommand)
    num = clang_CompileCommand_getNumArgs(cmd.ptr)
    args = Vector{String}(undef, num)
    for i in 1:num
        args[i] = _cxstring_to_string(clang_CompileCommand_getArg(cmd.ptr, i - 1))
    end
    args
end

# Mapped source support is dropped by clang
