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

function get_system_dirs(triple::String, version::VersionNumber=GCC_MIN_VER, is_cxx=false)
    p = parse(Platform, triple)
    # tweak the default version for aarch64 macos
    v = version == GCC_MIN_VER && os(p) == "macos" && arch(p) == "aarch64" ? v"11.0.0-iains" : version
    env = get_env(p; version=v, is_cxx)
    return get_system_includes(env)
end

get_arch_os_libc(target::AbstractString) = get_arch(target), get_os(target), get_libc(target)

get_arch(target::AbstractString) = first(split(target, '-'))

function get_os(target::AbstractString)
    _, vendor, _ = split(target, '-')
    if vendor == "apple"
        os = "macos"
    elseif vendor == "w64"
        os = "windows"
    elseif vendor == "unknown"
        os = "freebsd"
    elseif vendor == "linux"
        os = "linux"
    else
        error("Unknown OS: $target")
    end
    return os
end

function get_libc(target::AbstractString)
    _, _, env = split(target, '-')
    if startswith(env, "gnu")
        return "glibc"
    elseif startswith(env, "musl")
        return "musl"
    else
        return ""
    end
end

function get_pkg_artifact_dir(pkg::Module, target::String)
    arftspath = Artifacts.find_artifacts_toml(Pkg.pathof(pkg)::String)
    arfts = first(values(Artifacts.load_artifacts_toml(arftspath::String)))
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
    Artifacts.ensure_artifact_installed(name, info, arftspath::String)
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
