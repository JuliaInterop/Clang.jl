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
