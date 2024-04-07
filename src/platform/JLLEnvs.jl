module JLLEnvs

using Pkg
using Pkg.Artifacts
using Pkg.Artifacts: load_artifacts_toml, artifact_path
using Base.BinaryPlatforms

const JLL_ENV_SHARDS = Dict{String,Any}()

const ARTIFACT_TOML_PATH = Ref{String}()

function __init__()
    if haskey(ENV, "JULIA_CLANG_SHARDS_URL") && !isempty(get(ENV, "JULIA_CLANG_SHARDS_URL", ""))
        ARTIFACT_TOML_PATH[] = ENV["JULIA_CLANG_SHARDS_URL"]
    else
        ARTIFACT_TOML_PATH[] = normpath(joinpath(@__DIR__, "..", "..", "Artifacts.toml"))
    end
    merge!(JLL_ENV_SHARDS, Artifacts.load_artifacts_toml(ARTIFACT_TOML_PATH[]))
end

include("env.jl")
include("version.jl")
include("target.jl")
include("types.jl")
include("system.jl")

function get_system_dirs(triple::String, version::VersionNumber=v"4.8.5", is_cxx=false)
    env = get_env(parse(Platform, triple); version, is_cxx)
    return get_system_includes(env)
end

function get_default_args(is_cxx=false, version=GCC_MIN_VER)
    env = get_default_env(; is_cxx, version)
    args = ["-isystem" * dir for dir in get_system_includes(env)]
    push!(args, "--target=$(target(env.platform))")
    return args
end

function get_pkg_artifact_dir(pkg::Module, target::String)
    arftspath = Artifacts.find_artifacts_toml(Pkg.pathof(pkg))
    arfts = first(values(Artifacts.load_artifacts_toml(arftspath)))
    target_arch, target_os, target_libc = get_arch_os_libc(target)
    candidates = Dict[]
    for info in arfts
        if info isa Dict
            arch = get(info, "arch", "")
            os = get(info, "os", "")
            libc = get(info, "libc", "")
            if arch == target_arch && os == target_os && libc == target_libc
                push!(candidates, info)
            end
        else
            # this could be an "Any"-platform JLL package
            push!(candidates, arfts)
            break
        end
    end
    isempty(candidates) && return ""
    length(candidates) > 1 && @warn "found more than one candidate artifacts, only use the first one: $(first(candidates))"
    info = first(candidates)
    name = info["git-tree-sha1"]  # this is not a real name but a hash
    Artifacts.ensure_artifact_installed(name, info, arftspath)
    return normpath(Artifacts.artifact_path(Base.SHA1(name)))
end

function get_pkg_include_dir(pkg::Module, target::String)
    artifact_dir = get_pkg_artifact_dir(pkg, target)
    if isempty(artifact_dir)
        return ""
    else
        joinpath(artifact_dir, "include")
    end
end

end # module
