# TODO: support muti-system mode
load_options(path::AbstractString) = TOML.parse(read(path, String))
