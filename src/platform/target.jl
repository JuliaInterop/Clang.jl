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
    "x86_64-unknown-freebsd13.2"=>"x86_64-unknown-freebsd13.2",
    "x86_64-w64-mingw32"=>"x86_64-w64-windows-gnu",
)

triple2target(triple::String) = get(JLL_ENV_CLANG_TARGETS_MAPPING, triple, "unknown")

function __triplet(p::Platform)
    for k in keys(p.tags)
        if k != "arch" && k != "os" && k != "libc" && k != "call_abi" && k != "os_version"
            delete!(p.tags, k)
        end
    end
    t = triplet(p)
    if os_version(p) === nothing
        if os(p) == "macos" && arch(p) == "x86_64"
            t *= "14"
        elseif os(p) == "macos" && arch(p) == "aarch64"
            t *= "20"
        end
    end
    return t
end

target(triple::String) = get(JLL_ENV_CLANG_TARGETS_MAPPING, triple, "unknown")
target(p::Platform) = target(__triplet(p))
