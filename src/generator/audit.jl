"""
    audit_library_name(dag::ExprDAG, options::Dict)
Check whether the library name is valid.
"""
function audit_library_name(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    if haskey(general_options, "library_name")
        try
            Meta.parse(general_options["library_name"])
        catch err
            general_options["library_name"] = "libxxx"
            @warn "failed to parse the `library_name` as a valid Julia expression, default library name: \":libxxx\" is being used instead."
        end
    else
        general_options["library_name"] = "libxxx"
        @warn "default libname: \":libxxx\" is being used, did you forget to set `library_name` in the toml file? It's safe to ignore this warning if you are using `library_names` as an exhaustive list (if so, set `library_name` to a dummy value to supress it)."
    end
    if haskey(options, "general")
        merge!(options["general"], general_options)
    else
        options["general"] = general_options
    end
    return nothing
end

"""
    sanity_check(dag::ExprDAG, options::Dict)
Check whether the C code uses bad code-styles listed below:
* typedef an identifier that has the same name as a tag-type "A" but the underlying type
is actually something else. For example,
```c
struct foo {
  int x;
};

struct bar {
  int y;
};

typedef struct foo bar;
typedef struct bar foo;
```
* use the same name for structs and functions/function macros. For example,
```c
struct post {
    char m;
};

#define post(x) ((int)(x))
// Or
void post(struct post m);
```
* two identifiers with same name are actually different things.

It is intended to treat these as "bug"s of the upstream C code.
"""
function sanity_check(dag::ExprDAG, options::Dict)
    for (tk, tv) in dag.tags, (idk, idv) in dag.ids
        idk == tk || continue

        tn = dag.nodes[tv]
        idn = dag.nodes[idv]
        @assert !is_tagtype(idn)

        # in case the audit pass is executed after the `Skip` marking
        is_hardskip(idn) && continue

        ifile, iline, icol = get_file_line_column(idn.cursor)
        tfile, tline, tcol = get_file_line_column(tn.cursor)

        if is_typedef(idn)
            ty = getCanonicalType(getTypedefDeclUnderlyingType(idn.cursor))
            if getTypeDeclaration(ty) isa CLNoDeclFound
                ty = getTypedefDeclUnderlyingType(idn.cursor)
            end
            if !is_same(getTypeDeclaration(ty), dag.nodes[tv].cursor)
                error("sanity check failed. [REASON]: typedef an identifier $(idn.cursor) at $ifile:$iline:$icol that has the same name as a tag-type $(tn.cursor) at $tfile:$tline:$tcol. The C code use the same name for different things, which is not a good code-style, please fix it in the upstream.")
            end
        elseif is_function(idn)
            @warn "sanity check failed. [REASON]: the same name $tk is used for struct $(tn.cursor) at $tfile:$tline:$tcol and function $(idn.cursor) at $ifile:$iline:$icol. The C code use the same name for structs and functions, which is not a good code-style, please fix it in the upstream."
        elseif is_macrofunctionlike(idn)
            @warn "sanity check failed. [REASON]: the same name $tk is used for struct $(tn.cursor) at $tfile:$tline:$tcol and function-like macro $(idn.cursor) at $ifile:$iline:$icol. The C code use the same name for structs and functions, which is not a good code-style, please fix it in the upstream."
        else
            error("sanity check failed. please file an issue to Clang.jl.")
        end
    end

    # check whether all duplicated identifiers are actually the same thing (is this even legal in C?)
    for node in dag.nodes
        is_dup_identifier(node) || continue
        for (idk, idv) in dag.ids
            idn = dag.nodes[idv]
            ty1 = getCanonicalType(getTypedefDeclUnderlyingType(node.cursor))
            ty2 = getCanonicalType(getTypedefDeclUnderlyingType(idn.cursor))
            if is_same(getTypeDeclaration(ty1), getTypeDeclaration(ty2))
                file1, line1, col1 = get_file_line_column(node.cursor)
                file2, line2, col2 = get_file_line_column(idn.cursor)
                error("sanity check failed. [REASON]: the identifier $(node.cursor) at $file1:$line1:$col1 and the identifier $(idn.cursor) at $file2:$line2:$col2 have the same name but are actually different things. This is not a good code-style, please fix it in the upstream.")
            end
        end
    end

    return nothing
end


"""
    report_default_tag_types(dag::ExprDAG, options::Dict)
Report those tag-types labeled `StructDefault`/`UnionDefault`/`EnumDefault`.
"""
function report_default_tag_types(dag::ExprDAG, options::Dict)
    default_types = filter(dag.nodes) do node
        node.type isa StructDefault ||
        node.type isa UnionDefault ||
        node.type isa EnumDefault
    end
    if !isempty(default_types) && options["Audit_log"]
        @info "found default tag-types: " default_types
    end
    return nothing
end
