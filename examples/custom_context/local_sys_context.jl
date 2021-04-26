function find_std_headers()
    headers = String[]
    @static if Sys.isapple()
        xcode_path = strip(read(`xcode-select --print-path`, String))
        sdk_path = strip(read(`xcrun --show-sdk-path`, String))
        occursin("Xcode", xcode_path) &&
            (xcode_path *= "/Toolchains/XcodeDefault.xctoolchain/")
        didfind = false
        lib = joinpath(xcode_path, "usr", "lib", "c++", "v1")
        inc = joinpath(xcode_path, "usr", "include", "c++", "v1")
        isdir(lib) && (push!(headers, lib); didfind = true)
        isdir(inc) && (push!(headers, inc); didfind = true)
        if isdir("/usr/include")
            push!(headers, "/usr/include")
        else
            isdir(joinpath(sdk_path, "usr", "include"))
            push!(headers, joinpath(sdk_path, "usr", "include"))
        end
        didfind ||
            error("Could not find C++ standard library. Is XCode or CommandLineTools installed?")
    end
    return headers
end

"""
    find_dependent_headers(headers::Vector{T}, args::Vector, general_ops::Dict) where {T<:AbstractString}
Return a vector of headers to which those missing dependent headers are added.
"""
function find_dependent_headers(headers::Vector{T}, args::Vector, general_ops::Dict) where {T<:AbstractString}
    blacklist = get(general_ops, "header_blacklist", [])
    flags = CXTranslationUnit_DetailedPreprocessingRecord
    flags |= CXTranslationUnit_SkipFunctionBodies
    all_headers = copy(headers)
    dependent_headers = T[]
    new_headers = T[]
    blocked_headers = T[]
    idx = Index(false)
    while true
        empty!(new_headers)
        for header in all_headers
            tu = parse_header(idx, header, args, flags)
            GC.@preserve tu begin
                tu_cursor = getTranslationUnitCursor(tu)
                header_name = spelling(tu_cursor)
                header_dir = dirname(header_name)
                for cursor in children(tu_cursor)
                    is_inclusion_directive(cursor) || continue
                    file = getIncludedFile(cursor)
                    file_name = get_filename(file) |> normpath
                    (isempty(file_name) || !isfile(file_name)) && continue

                    dir = dirname(file_name)
                    file_name ∈ all_headers && continue
                    if startswith(header_dir, dir) || startswith(dir, header_dir)
                        isempty(header_dir) && continue
                        file_name ∈ new_headers && continue
                        if any(x->!isempty(x) && endswith(file_name, x), blacklist)
                            file_name ∉ blocked_headers && push!(blocked_headers, file_name)
                            continue
                        end
                        push!(new_headers, file_name)
                    end
                end
            end
        end
        isempty(new_headers) && break
        foreach(new_headers) do h
            @info "found dependent header: $h"
        end
        append!(dependent_headers, new_headers)
        append!(all_headers, new_headers)
    end

    for file in blocked_headers
        @info "skipped a dependent file: $file because it's in the blacklist."
    end

    return normpath.(dependent_headers)
end

"""
    create_context(headers::Vector, args::Vector=String[], options::Dict=Dict())
Create a context from a vector of paths of headers, a vector of compiler flags and
a option dict.
"""
function create_context(headers::Vector, args::Vector=String[], options::Dict=Dict())
    ctx = Context(options)

    general_options = get(options, "general", Dict())
    if get(general_options, "auto_detect_system_headers", true)
        sys_headers = "-I" .* find_std_headers()
        args = vcat(sys_headers, args)
    end

    if get(general_options, "use_clang_headers", true)
        clang_incs = ["-I"*CLANG_INCLUDE]
        args = vcat(clang_incs, args)
    end

    dependent_headers = find_dependent_headers(headers, args, general_options)

    parse_headers!(ctx, headers, args)

    push!(ctx.passes, CollectTopLevelNode(ctx.trans_units, dependent_headers))
    push!(ctx.passes, LinkTypedefToAnonymousTagType())
    push!(ctx.passes, IndexDefinition())
    push!(ctx.passes, CollectNestedRecord())
    push!(ctx.passes, FindOpaques())
    push!(ctx.passes, ResolveDependency())
    push!(ctx.passes, RemoveCircularReference())
    push!(ctx.passes, TopologicalSort())
    push!(ctx.passes, IndexDefinition())
    push!(ctx.passes, ResolveDependency())
    push!(ctx.passes, CatchDuplicatedAnonymousTags())
    push!(ctx.passes, CodegenPreprocessing())
    if get(general_options, "smart_de_anonymize", true)
        push!(ctx.passes, DeAnonymize())
    end
    push!(ctx.passes, Audit())
    push!(ctx.passes, Codegen())
    push!(ctx.passes, CodegenMacro())
    # push!(ctx.passes, CodegenPostprocessing())
    if get(general_options, "auto_mutability", false)
        push!(ctx.passes, TweakMutability())
    end

    # support old behavior
    api_file = get(general_options, "output_api_file_path", "")
    common_file = get(general_options, "output_common_file_path", "")

    output_file_path = get(general_options, "output_file_path", "")
    if isempty(api_file) && isempty(common_file)
        if !isempty(output_file_path)
            push!(ctx.passes, ProloguePrinter(output_file_path))
            push!(ctx.passes, GeneralPrinter(output_file_path))
            push!(ctx.passes, EpiloguePrinter(output_file_path))
        else
            # print to stdout if there is no `output_file_path`
            # this is handy when playing in REPL
            push!(ctx.passes, StdPrinter())
        end
    else
        # TODO: impl
    end

    return ctx
end
