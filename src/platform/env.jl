const JLL_ENV_TRIPLES = String[
    "aarch64-apple-darwin20",
    "aarch64-linux-gnu",
    "aarch64-linux-musl",
    "armv7l-linux-gnueabihf",
    "armv7l-linux-musleabihf",
    "i686-linux-gnu",
    "i686-linux-musl",
    "i686-w64-mingw32",
    "powerpc64le-linux-gnu",
    "x86_64-apple-darwin14",
    "x86_64-linux-gnu",
    "x86_64-linux-musl",
    "x86_64-unknown-freebsd",
    "x86_64-w64-mingw32",
]

const HOST_TRIPLE = "x86_64-linux-musl"
const GCC_SHARD_NAME = "GCCBootstrap"

const JLL_ENV_PLATFORMS = [
    Platform("aarch64", "macos"),
    Platform("aarch64", "linux"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("armv7l", "linux"),
    Platform("armv7l", "linux"; libc="musl"),
    Platform("i686", "linux"),
    Platform("i686", "linux"; libc="musl"),
    Platform("i686", "windows"),
    Platform("powerpc64le", "linux"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "linux"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "freebsd"),
    Platform("x86_64", "windows"),
]

get_gcc_shard_key(p::Platform, version::VersionNumber=GCC_MIN_VER) = "$GCC_SHARD_NAME-$(__triplet(p)).v$version.$HOST_TRIPLE.unpacked"
get_gcc_shard_key(triple::String, version::VersionNumber=GCC_MIN_VER) = get_gcc_shard_key(parse(Platform, triple), version)

function get_environment_info(p::Platform, version::VersionNumber=GCC_MIN_VER)
    gcc = JLL_ENV_SHARDS[get_gcc_shard_key(p, version)][]
    gcc_download = gcc["download"][]
    return (id=gcc["git-tree-sha1"], url=gcc_download["url"], chk=gcc_download["sha256"])
end
get_environment_info(triple::String, version::VersionNumber=GCC_MIN_VER) = get_environment_info(parse(Platform, triple), version)
