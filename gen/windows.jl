using Pkg.Artifacts

# "GCCBootstrap-x86_64-w64-mingw32.v10.2.0.x86_64-linux-musl.unpacked"
sha = Base.SHA1("03a2b8e14e4abea9e138424dbbb3d968756d36de")
url = "https://github.com/JuliaPackaging/Yggdrasil/releases/download/GCCBootstrap-v10.2.0/GCCBootstrap-x86_64-w64-mingw32.v10.2.0.x86_64-linux-musl.unpacked.tar.gz"
chk = "2c85bc7434a77f7f1b43c79cc3a0ed869cd0b312bb685ec55d03a5b88d39d57a"

mingw_dir = joinpath(homedir(), ".julia", "artifacts", string(sha))
if !isdir(mingw_dir)
    Artifacts.download_artifact(sha, url, chk)
    @assert isdir(mingw_dir) "failed to download the artifact!"
end

mingw_inc = joinpath(mingw_dir, "x86_64-w64-mingw32", "include")
mingw_sys = joinpath(mingw_dir, "x86_64-w64-mingw32", "sys-root")
@assert isdir(mingw_inc)
@assert isdir(mingw_sys)
