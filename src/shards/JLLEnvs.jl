module JLLEnvs

using Pkg
using Pkg.Artifacts
using Downloads

include("utils.jl")

const JLL_ENV_SHARDS = Dict{String,Any}()

const ARTIFACT_TOML_PATH = Ref{String}()

# The platform used in Artifacts.toml
const BINARY_BUILDER_PLATFORM = Base.BinaryPlatforms.Platform("x86_64", "linux"; libc="musl")

function __init__()
    if haskey(ENV, "JULIA_CLANG_SHARDS_URL") && !isempty(get(ENV, "JULIA_CLANG_SHARDS_URL", ""))
        ARTIFACT_TOML_PATH[] = ENV["JULIA_CLANG_SHARDS_URL"]
    else
        ARTIFACT_TOML_PATH[] = normpath(joinpath(@__DIR__, "..", "..", "Artifacts.toml"))
    end
    merge!(JLL_ENV_SHARDS, Artifacts.load_artifacts_toml(ARTIFACT_TOML_PATH[]))
end

const JLL_ENV_HOST_TRIPLE = "x86_64-linux-musl"
const JLL_ENV_GCC_SHARD_NAME = "GCCBootstrap"
const JLL_ENV_SYSTEM_SHARD_NAME = "PlatformSupport"

const JLL_ENV_GCC_VERSIONS = VersionNumber[
    v"4.8.5",
    v"5.2.0",
    v"6.1.0",
    v"7.1.0",
    v"8.1.0",
    v"9.1.0",
    v"10.2.0",
    v"11.0.0-iains",
]

# External API.
# The triples used for cross-platform configuration
const JLL_ENV_TRIPLES = String[
    "aarch64-apple-darwin20",
    "aarch64-linux-gnu",           # Tier 1
    "aarch64-linux-musl",
    "armv7l-linux-gnueabihf",
    "armv7l-linux-musleabihf",
    "i686-linux-gnu",              # Tier 1
    "i686-linux-musl",
    "i686-w64-mingw32",            # Tier 2
    "powerpc64le-linux-gnu",
    "x86_64-apple-darwin14",       # Tier 1
    "x86_64-linux-gnu",            # Tier 1
    "x86_64-linux-musl",
    "x86_64-unknown-freebsd",      # Tier 1
    "x86_64-w64-mingw32",          # Tier 1
]

const JLL_ENV_CLANG_TARGETS_MAPPING = Dict(
    "aarch64-apple-darwin20"=>"aarch64-apple-darwin20",
    "aarch64-linux-gnu"=>"aarch64-unknown-linux-gnu",
    "aarch64-linux-musl"=>"aarch64-unknown-linux-musl",
    "armv7l-linux-gnueabihf"=>"armv7l-unknown-linux-gnueabihf",
    "armv7l-linux-musleabihf"=>"armv7l-unknown-linux-musleabihf",
    "i686-linux-gnu"=>"i686-unknown-linux-gnu",
    "i686-linux-musl"=>"i686-unknown-linux-musl",
    "i686-w64-mingw32"=>"i686-w64-windows-gnu",
    "powerpc64le-linux-gnu"=>"powerpc64le-unknown-linux-gnu",
    "x86_64-apple-darwin14"=>"x86_64-apple-darwin14",
    "x86_64-linux-gnu"=>"x86_64-unknown-linux-gnu",
    "x86_64-linux-musl"=>"x86_64-unknown-linux-musl",
    "x86_64-unknown-freebsd"=>"x86_64-unknown-freebsd12.2",
    "x86_64-w64-mingw32"=>"x86_64-w64-windows-gnu",
)

triple2target(triple::String) = get(JLL_ENV_CLANG_TARGETS_MAPPING, triple, "unknown")

const JLL_ENV_CLANG_TRIPLE_ABBREVATION_MAPPING = Dict(
    "x86_64-unknown-freebsd"=>"x86_64-unknown-freebsd12.2"
)

# expand freebsd to freebsd12.2
expand_triple(triple::AbstractString) = get(JLL_ENV_CLANG_TRIPLE_ABBREVATION_MAPPING, triple, triple)

# Internal use, triples used in artifacts
const JLL_ENV_ARTIFACT_TRIPLES = expand_triple.(JLL_ENV_TRIPLES)

function get_gcc_shard_key(triple::String, version::VersionNumber=v"4.8.5")
    @assert version ∈ JLL_ENV_GCC_VERSIONS "Wrong JLL gcc version: $version. Please choose a version listed in `JLL_ENV_GCC_VERSIONS`."
    @assert triple ∈ JLL_ENV_ARTIFACT_TRIPLES "Wrong JLL target triple: $triple. Please choose a triple listed in `JLL_ENV_ARTIFACT_TRIPLES`."
    # ignore gcc version for Apple Silicon
    if triple == "aarch64-apple-darwin20"
        return "$JLL_ENV_GCC_SHARD_NAME-aarch64-apple-darwin20.v11.0.0-iains.$JLL_ENV_HOST_TRIPLE.unpacked"
    else
        return "$JLL_ENV_GCC_SHARD_NAME-$triple.v$version.$JLL_ENV_HOST_TRIPLE.unpacked"
    end
end

function get_system_shard_key(triple::String)
    @assert triple ∈ JLL_ENV_ARTIFACT_TRIPLES "Wrong JLL target triple: $triple. Please choose a triple listed in `JLL_ENV_ARTIFACT_TRIPLES`."
    platform_keys = filter(collect(keys(JLL_ENV_SHARDS))) do key
        startswith(key, "$JLL_ENV_SYSTEM_SHARD_NAME-$triple.") &&
        endswith(key, "$JLL_ENV_HOST_TRIPLE.unpacked")
    end
    return platform_keys[]
end

function get_environment_info(triple::String, version::VersionNumber=v"4.8.5")
    @assert triple ∈ JLL_ENV_ARTIFACT_TRIPLES "Wrong JLL target triple: $triple. Please choose a triple listed in `JLL_ENV_ARTIFACT_TRIPLES`."
    gcc = JLL_ENV_SHARDS[get_gcc_shard_key(triple, version)][]
    sys = JLL_ENV_SHARDS[get_system_shard_key(triple)][]
    gcc_download = gcc["download"][]
    sys_download = sys["download"][]
    info = [
        (id=gcc["git-tree-sha1"], url=gcc_download["url"], chk=gcc_download["sha256"]),
        (id=sys["git-tree-sha1"], url=sys_download["url"], chk=sys_download["sha256"]),
    ]
    return info
end

function get_system_dirs(triple::String, version::VersionNumber=v"4.8.5")
    triple = expand_triple(triple)
    info = get_environment_info(triple, version)
    gcc_info = info[1]
    sys_info = info[2]

    # download shards
    if haskey(ENV, "JULIA_CLANG_SHARDS_URL") && !isempty(get(ENV, "JULIA_CLANG_SHARDS_URL", ""))
        @info "Downloading artifact($(gcc_info.id))"
    end
    Artifacts.ensure_artifact_installed(get_gcc_shard_key(triple, version), ARTIFACT_TOML_PATH[]; platform=BINARY_BUILDER_PLATFORM)
    # Artifacts.download_artifact(Base.SHA1(sys_info.id), sys_info.url, sys_info.chk)

    # -isystem paths
    gcc_triple_path = Artifacts.artifact_path(Base.SHA1(gcc_info.id))
    # sys_triple_path = Artifacts.artifact_path(Base.SHA1(sys_info.id))
    isys = String[]
    if triple == "x86_64-apple-darwin14"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include"))
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include-fixed"))
        push!(isys, joinpath(gcc_triple_path, triple, "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "usr", "include"))
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "System", "Library", "Frameworks"))
    elseif triple == "aarch64-apple-darwin20"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, "11.0.0", "include"))
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, "11.0.0", "include-fixed"))
        push!(isys, joinpath(gcc_triple_path, triple, "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "usr", "include"))
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "System", "Library", "Frameworks"))
    elseif triple == "x86_64-w64-mingw32" || triple == "i686-w64-mingw32"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include"))
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include-fixed"))
        push!(isys, joinpath(gcc_triple_path, triple, "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "include"))
    elseif triple == "i686-linux-gnu" || triple == "x86_64-linux-gnu" ||
            triple == "aarch64-linux-gnu" || triple == "powerpc64le-linux-gnu" ||
            triple == "x86_64-unknown-freebsd12.2"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include"))
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include-fixed"))
        push!(isys, joinpath(gcc_triple_path, triple, "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "usr", "include"))
    elseif triple == "i686-linux-musl" || triple == "x86_64-linux-musl" ||
            triple == "aarch64-linux-musl"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include"))
        push!(isys, joinpath(gcc_triple_path, triple, "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "usr", "include"))
    elseif triple == "armv7l-linux-gnueabihf"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", "arm-linux-gnueabihf", string(version), "include"))
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", "arm-linux-gnueabihf", string(version), "include-fixed"))
        push!(isys, joinpath(gcc_triple_path, "arm-linux-gnueabihf", "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, "arm-linux-gnueabihf", "sys-root", "usr", "include"))
    elseif triple == "armv7l-linux-musleabihf"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", "arm-linux-musleabihf", string(version), "include"))
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", "arm-linux-musleabihf", string(version), "include-fixed"))
        push!(isys, joinpath(gcc_triple_path, "arm-linux-musleabihf", "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, "arm-linux-musleabihf", "sys-root", "usr", "include"))
    else
        error("Platform $triple is not supported.")
    end

    @assert all(isdir, isys) "failed to setup environment due to missing dirs, please file an issue at https://github.com/JuliaInterop/Clang.jl/issues."

    return normpath.(isys)
end

function get_pkg_artifact_dir(pkg::Module, target::String)
    afts = first(values(Artifacts.load_artifacts_toml(Artifacts.find_artifacts_toml(Pkg.pathof(pkg)))))
    target_arch, target_os, target_libc = get_arch_os_libc(target)
    candidates = Dict[]
    for info in afts
        if info isa Dict
            arch = get(info, "arch", "")
            os = get(info, "os", "")
            libc = get(info, "libc", "")
            if arch == target_arch && os == target_os && libc == target_libc
                push!(candidates, info)
            end
        else
            # this could be an "Any"-platform JLL package
            push!(candidates, afts)
            break
        end
    end
    isempty(candidates) && return ""
    length(candidates) > 1 && @warn "found more than one candidate artifacts, only use the first one: $(first(candidates))"
    info = first(candidates)
    download_info = info["download"][]
    id, url, chk = info["git-tree-sha1"], download_info["url"], download_info["sha256"]
    Artifacts.download_artifact(Base.SHA1(id), url, chk)
    return normpath(Artifacts.artifact_path(Base.SHA1(id)))
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
