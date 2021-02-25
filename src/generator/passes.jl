"""
    AbstractPass
Supertype for all passes.
"""
abstract type AbstractPass end

const COMPILER_DEFINITIONS_EXTRA = [
    "OBJC_NEW_PROPERTIES",  # https://reviews.llvm.org/D72970
    "_LP64",  # this is a compiler flag and is always defined along with "__LP64__"
]

"""
    CollectTopLevelNode <: AbstractPass
In this pass, all tags and identifiers in all translation units are collected for
CTU analysis.

See also [`collect_top_level_nodes!`](@ref).
"""
mutable struct CollectTopLevelNode <: AbstractPass
    trans_units::Vector{TranslationUnit}
    dependant_headers::Vector{String}
    compiler_defs_extra::Vector{String}
    show_info::Bool
end
CollectTopLevelNode(tus, dhs, info) = CollectTopLevelNode(tus, dhs, COMPILER_DEFINITIONS_EXTRA, info)
CollectTopLevelNode(tus, dhs=String[]; info=false) = CollectTopLevelNode(tus, dhs, info)

function (x::CollectTopLevelNode)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    is_local_only = get(general_options, "is_local_header_only", true)
    skip_defs = get(general_options, "skip_compiler_definition", true)

    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "CollectTopLevelNode_log", x.show_info)

    empty!(dag.nodes)
    for tu in x.trans_units
        tu_cursor = getTranslationUnitCursor(tu)
        header_name = spelling(tu_cursor)
        @info "[CollectTopLevelNode]: processing header: $header_name"
        for cursor in children(tu_cursor)
            file_name = get_filename(cursor)
            if is_local_only && header_name != file_name
                file_name ∉ x.dependant_headers && continue
            end

            str = spelling(cursor)
            if skip_defs && (startswith(str, "__") || (str ∈ x.compiler_defs_extra))
                show_info && @info "[CollectTopLevelNode]: skip $str"
                continue
            end

            collect_top_level_nodes!(dag, cursor)
        end
    end
    return dag
end

"""
    IndexDefinition <: AbstractPass
In this pass, the indices of struct/union/enum tags and those of function/typedef/macro
identifiers are cached in the DAG for future use. Note that, the "Definition" in the type
name means a little bit more.

The `adj` list of each node is also cleared in this pass. Those opaque structs/unions/enums
are marked in this pass.
"""
mutable struct IndexDefinition <: AbstractPass
    show_info::Bool
end
IndexDefinition(; info=false) = IndexDefinition(info)

function (x::IndexDefinition)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "IndexDefinition_log", x.show_info)

    empty!(dag.tags)
    empty!(dag.ids)
    for (i, node) in enumerate(dag.nodes)
        !isempty(node.adj) && empty!(node.adj)

        if is_tag_def(node)
            if haskey(dag.tags, node.id)
                n = dag.nodes[dag.tags[node.id]]
                @assert is_same(n.cursor, node.cursor) "duplicated definitions should be exactly the same!"
                show_info && @info "[IndexDefinition]: found an indexed tag $(node.id) at nodes[$i], skip..."
                ty = dup_type(node.type)
                dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            else
                show_info && @info "[IndexDefinition]: indexing tag $(node.id) at nodes[$i]"
                dag.tags[node.id] = i
            end
        end

        if is_identifier(node)
            if haskey(dag.ids, node.id)
                show_info &&
                    @info "[IndexDefinition]: found duplicated identifier $(node.id) at nodes[$i]"
                ty = dup_type(node.type)
                dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            else
                show_info && @info "[IndexDefinition]: indexing identifier $(node.id) at nodes[$i]"
                dag.ids[node.id] = i
            end
        end
    end

    # also mark opaque tag-types for future use
    for (i, node) in enumerate(dag.nodes)
        is_forward_decl(node) || continue
        if !haskey(dag.tags, node.id)
            ty = opaque_type(node.type)
            dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            dag.tags[node.id] = i
            show_info &&
                @info "[IndexDefinition]: indexing an opaque tag-type $(node.id)"
        end
    end
    return dag
end

"""
    LinkTypedefToAnonymousTagType <: AbstractPass
In this pass, the id info of anonymous tag-type nodes is added to those typedef nodes that
directly/indirectly have a reference to these nodes. The id info is injected in the upstream
passes.
"""
mutable struct LinkTypedefToAnonymousTagType <: AbstractPass
    cache::Dict{Int,Vector{Int}}
    show_info::Bool
end
LinkTypedefToAnonymousTagType(; info=false) = LinkTypedefToAnonymousTagType(Dict(), info)

function (x::LinkTypedefToAnonymousTagType)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "LinkTypedefToAnonymousTagType_log", x.show_info)

    empty!(x.cache)
    # loop through all the nodes to cache the indices of all the typedefs that refer to
    # an anonymous tag-type
    for i in 1:(length(dag.nodes) - 1)
        cur = dag.nodes[i]
        is_anonymous(cur) || continue
        x.cache[i] = Int[]
        # since an anonymous tag-type may have mutiple typedefs, we need another loop
        for j in (i + 1):length(dag.nodes)
            n = dag.nodes[j]
            is_typedef(n) || break  # keep searching until we hit a non-typedef node
            refback = children(n.cursor)
            if !isempty(refback) && first(refback) == cur.cursor
                push!(x.cache[i], j)
            end
        end
    end
    # loop through all anonymous tag-types and apply node editing
    for (k, v) in x.cache
        isempty(v) && continue  # skip non-typedef anonymous tag-types e.g. enum
        anonymous = dag.nodes[k]
        for i in v
            node = dag.nodes[i]
            ty = TypedefToAnonymous(anonymous.id)
            dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            show_info &&
                @info "[LinkTypedefToAnonymousTagType_log]: store $(anonymous.cursor)'s id to typedef node $(node.id)"
        end
    end
    return dag
end

"""
    ResolveDependency <: AbstractPass
In this pass, the `adj` list of each node in the DAG is populated by its parent definition
nodes. Make sure you run the [`IndexDefinition`](@ref) pass before this pass.

Note that, in the case of circular forward decls, circular dependencies may be introduced
in the DAG, this should be handled in the downstream passes.

See also [`resolve_dependency!`](@ref)
"""
mutable struct ResolveDependency <: AbstractPass
    show_info::Bool
end
ResolveDependency(; info=false) = ResolveDependency(info)

function (x::ResolveDependency)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "ResolveDependency_log", x.show_info)

    for node in dag.nodes
        resolve_dependency!(dag, node)
        unique!(node.adj)  # FIXME: check this
        if show_info
            deps = Dict(n => dag.nodes[n] for n in node.adj)
            @info "[ResolveDependency]: resolved dependency for $(node.cursor)" deps
        end
    end
    return dag
end

@enum DFSMarkStatus begin
    UNMARKED = 0x00
    TEMPORARY = 0x01
    PERMANENT = 0x02
end

"""
    RemoveCircularReference <: AbstractPass
In this pass, circular dependencies that are introduced by mutually referenced structs are
removed, so we can do a topological sort on the DAG.

Make sure you run the [`ResolveDependency`](@ref) pass before this pass.
"""
mutable struct RemoveCircularReference <: AbstractPass
    show_info::Bool
end
RemoveCircularReference(; info=false) = RemoveCircularReference(info)

function detect_cycle!(nodes, marks, cycle, i)
    node = nodes[i]
    mark = marks[i]
    # skip if this node has already been visited
    mark == PERMANENT && return cycle

    # hit a backward edge, record the index
    if mark == TEMPORARY
        push!(cycle, i)
        return cycle
    end

    marks[i] = TEMPORARY
    for n in node.adj
        detect_cycle!(nodes, marks, cycle, n)
        if !isempty(cycle)
            push!(cycle, i)
            return cycle
        end
    end
    marks[i] = PERMANENT
    return cycle
end

function is_non_pointer_ref(child, parent)
    is_non_pointer_dep = false
    for fc in fields(getCursorType(child.cursor))
        fty = getCursorType(fc)
        is_jl_pointer(tojulia(fty)) && continue
        c = getTypeDeclaration(fty)
        if c == parent.cursor
            is_non_pointer_dep = true
        end
    end
    return is_non_pointer_dep
end

function (x::RemoveCircularReference)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "RemoveCircularReference_log", x.show_info)

    marks = fill(UNMARKED, size(dag.nodes))
    while any(x -> x != PERMANENT, marks)
        fill!(marks, UNMARKED)
        for (i, node) in enumerate(dag.nodes)
            marks[i] == UNMARKED || continue
            cycle = Int[]
            detect_cycle!(dag.nodes, marks, cycle, i)
            isempty(cycle) && continue

            # remove cycle reference caused by mutually referenced structs
            is_ptr_ref = false
            origin_idx = first(cycle)
            origin_node = dag.nodes[origin_idx]
            for i in 1:(length(cycle) - 1)
                np, nc = cycle[i], cycle[i + 1]
                parent, child = dag.nodes[np], dag.nodes[nc]
                if child.type isa AbstractStructNodeType
                    # only pointer references can be safely removed
                    is_ptr_ref = !is_non_pointer_ref(child, parent)
                    if is_ptr_ref
                        idx = findfirst(x -> x == np, child.adj)
                        deleteat!(child.adj, idx)
                        id = child.id
                        ty = StructMutualRef()
                        dag.nodes[nc] = ExprNode(id, ty, child.cursor, child.exprs, child.adj)
                        show_info &&
                            @info "[RemoveCircularReference]: removed $(child.id)'s dependency $(parent.id)"
                    end
                end
                # exit earlier
                (i + 1) == first(cycle) && break
            end

            # when never a cycle is found, we reset all of the marks and restart again
            # FIXME: optimize this
            break
        end
    end
    return dag
end

"""
    TopologicalSort <: AbstractPass
Make sure you run the [`RemoveCircularReference`](@ref) pass before this pass.
"""
mutable struct TopologicalSort <: AbstractPass
    show_info::Bool
end
TopologicalSort(; info=false) = TopologicalSort(info)

function dfs_visit!(list, nodes, marks, i)
    node = nodes[i]
    mark = marks[i]
    mark == PERMANENT && return nothing
    @assert mark != TEMPORARY

    marks[i] = TEMPORARY
    for n in node.adj
        dfs_visit!(list, nodes, marks, n)
    end
    marks[i] = PERMANENT
    push!(list, node)
    return nothing
end

function (x::TopologicalSort)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "TopologicalSort_log", x.show_info)

    show_info && @info "[TopologicalSort]: sorting the DAG ..."
    marks = fill(UNMARKED, size(dag.nodes))
    list = []
    for (i, node) in enumerate(dag.nodes)
        marks[i] == UNMARKED || continue
        dfs_visit!(list, dag.nodes, marks, i)
    end
    dag.nodes .= list

    # clean up indices because they are no longer valid
    empty!(dag.tags)
    empty!(dag.ids)

    return dag
end

"""
    DeAnonymize <: AbstractPass
In this pass, naive anonymous tag-types are de-anonymized and the correspoding typedefs
are marked [`Skip`](@ref).

```c
typedef struct {
    int x;
} my_struct;
```

In the C code above, what the C programmer really want to do is to bring the name
"my_struct" from the tag scope into the identifier scope and force users to use `my_struct`
instead of `struct my_struct`. In Julia world, we can just do:

```julia
struct my_struct
    x::Cint
end
```

Make sure you run the [`ResolveDependency`](@ref) pass before this pass.
"""
mutable struct DeAnonymize <: AbstractPass
    show_info::Bool
end
DeAnonymize(; info=false) = DeAnonymize(info)

function (x::DeAnonymize)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "DeAnonymize_log", x.show_info)

    for (i, node) in enumerate(dag.nodes)
        is_typedef_to_anonymous(node) || continue
        # a typedef to anonymous node should have only one dependent node and
        # this node must be an anonymous tag-type node.
        @assert length(node.adj) == 1
        dep_idx = node.adj[1]
        dep_node = dag.nodes[dep_idx]

        # loop through the `adj`-list of all nodes in the DAG to find whether this
        # typedef node is the only node that refers to the anonymous tag-type node.
        apply_edit = true
        for n in dag.nodes
            n == node && continue
            if any(i -> dag.nodes[i] == dep_node, n.adj)
                apply_edit = false
            end
        end

        apply_edit || continue

        # apply node editing
        dn = dep_node
        dag.nodes[dep_idx] = ExprNode(node.id, dn.type, dn.cursor, dn.exprs, dn.adj)
        dag.nodes[i] = ExprNode(node.id, SoftSkip(), node.cursor, node.exprs, node.adj)
        show_info &&
            @info "[DeAnonymize]: adding name $(node.id) to $dep_node"
    end

    return dag
end

"""
    CodegenPreprocessing <: AbstractPass
In this pass, additional info are added into expression nodes for codegen.
"""
mutable struct CodegenPreprocessing <: AbstractPass
    skip_nodes::Vector{Int}
    show_info::Bool
end
CodegenPreprocessing(; info=false) = CodegenPreprocessing(Int[], info)

function (x::CodegenPreprocessing)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "CodegenPreprocessing_log", x.show_info)

    empty!(x.skip_nodes)
    for (i, node) in enumerate(dag.nodes)
        if skip_check(dag, node)
            push!(x.skip_nodes, i)
            dag.nodes[i] = ExprNode(node.id, Skip(), node.cursor, node.exprs, node.adj)
            show_info &&
                @info "[CodegenPreprocessing]: skip a $(node.type) node named $(node.id)"
        end
        if attribute_check(dag, node)
            ty = attribute_type(node.type)
            dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            show_info &&
                @info "[CodegenPreprocessing]: mark an attribute $(node.type) node named $(node.id)"
        end
        if nested_anonymous_check(dag, node)
            ty = nested_anonymous_type(node.type)
            dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            show_info &&
                @info "[CodegenPreprocessing]: mark a nested anonymous $(node.type) node named $(node.id)"
        end
        if bitfield_check(dag, node)
            ty = bitfield_type(node.type)
            dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            show_info &&
                @info "[CodegenPreprocessing]: mark a bitfield $(node.type) node named $(node.id)"
        end
    end

    has_new_skip_node = true
    while has_new_skip_node
        has_new_skip_node = false
        for (i, n) in enumerate(dag.nodes)
            is_hardskip(n) && continue
            # if any dependent node is a `Skip` node, mark this node as `Skip`
            for j in n.adj
                dn = dag.nodes[j]
                is_hardskip(dn) || continue
                push!(x.skip_nodes, i)
                dag.nodes[i] = ExprNode(n.id, Skip(), n.cursor, n.exprs, n.adj)
                show_info &&
                    @info "[CodegenPreprocessing]: skip a $(n.type) node named $(n.id)"
                has_new_skip_node = true
            end
        end
    end

    return dag
end

"""
    Codegen <: AbstractPass
In this pass, Julia expressions are emitted to `node.exprs`.
"""
mutable struct Codegen <: AbstractPass
    show_info::Bool
end
Codegen(; info=false) = Codegen(info)

function (x::Codegen)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "Codegen_log", x.show_info)
    codegen_options = get(options, "codegen", Dict())
    # forward general options
    if haskey(general_options, "library_name")
        codegen_options["library_name"] = general_options["library_name"]
    end

    # store definitions which would be used during codegen
    codegen_options["DAG_tags"] = dag.tags
    codegen_options["DAG_ids"] = dag.ids
    codegen_options["DAG_ids_extra"] = dag.ids_extra

    for (i, node) in enumerate(dag.nodes)
        !isempty(node.exprs) && empty!(node.exprs)
        emit!(dag, node, codegen_options, idx=i)
        show_info && @info "[Codegen]: emit Julia expression for $(node.id)"
    end

    # clean up
    delete!(codegen_options, "DAG_tags")
    delete!(codegen_options, "DAG_ids")
    delete!(codegen_options, "DAG_ids_extra")

    return dag
end

"""
    CodegenPostprocessing <: AbstractPass
"""
mutable struct CodegenPostprocessing <: AbstractPass
    show_info::Bool
end
CodegenPostprocessing(; info=false) = CodegenPostprocessing(info)

function (x::CodegenPostprocessing)(dag::ExprDAG, options::Dict)
    # TODO: add impl
end

const DEFAULT_AUDIT_FUNCTIONS = [
    audit_library_name,
    sanity_check,
    report_default_tag_types,
]

mutable struct Audit <: AbstractPass
    funcs::Vector{Function}
    show_info::Bool
end
Audit(; show_info=true) = Audit(DEFAULT_AUDIT_FUNCTIONS, show_info)

function (x::Audit)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    if !haskey(log_options, "Audit_log")
        log_options["Audit_log"] = x.show_info
    end

    for f in x.funcs
        f(dag, options)
    end

    return dag
end

"""
    AbstractPrinter <: AbstractPass
Supertype for printers.
"""
abstract type AbstractPrinter <: AbstractPass end

"""
    FunctionPrinter <: AbstractPrinter
In this pass, only those functions are dumped to file.
"""
mutable struct FunctionPrinter <: AbstractPrinter
    file::AbstractString
    show_info::Bool
end
FunctionPrinter(file::AbstractString; info=true) = FunctionPrinter(file, info)

function (x::FunctionPrinter)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "FunctionPrinter_log", x.show_info)

    show_info && @info "[FunctionPrinter]: print to $(x.file)"
    open(x.file, "w") do io
        for node in dag.nodes
            node.type isa AbstractFunctionNodeType || continue
            pretty_print(io, node, general_options)
        end
    end
    return dag
end

"""
    CommonPrinter <: AbstractPrinter
In this pass, only those non-functions are dumped to file.
"""
mutable struct CommonPrinter <: AbstractPrinter
    file::AbstractString
    show_info::Bool
end
CommonPrinter(file::AbstractString; info=true) = CommonPrinter(file, info)

function (x::CommonPrinter)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "CommonPrinter_log", x.show_info)

    show_info && @info "[CommonPrinter]: print to $(x.file)"
    open(x.file, "w") do io
        for node in dag.nodes
            node.type isa AbstractMacroNodeType && continue
            pretty_print(io, node, general_options)
        end
        # print macros in the bottom of the file
        for node in dag.nodes
            node.type isa AbstractMacroNodeType || continue
            pretty_print(io, node, options)
        end
    end
    return dag
end

"""
    GeneralPrinter <: AbstractPrinter
In this pass, structs/unions/enums are dumped to file.
"""
mutable struct GeneralPrinter <: AbstractPrinter
    file::AbstractString
    show_info::Bool
end
GeneralPrinter(file::AbstractString; info=true) = GeneralPrinter(file, info)

function (x::GeneralPrinter)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "GeneralPrinter_log", x.show_info)

    show_info && @info "[GeneralPrinter]: print to $(x.file)"
    open(x.file, "a") do io
        for node in dag.nodes
            node.type isa AbstractMacroNodeType && continue
            pretty_print(io, node, general_options)
        end
        # print macros in the bottom of the file
        for node in dag.nodes
            node.type isa AbstractMacroNodeType || continue
            pretty_print(io, node, options)
        end
    end
    return dag
end

"""
    ProloguePrinter <: AbstractPrinter
In this pass, prologues are dumped to file.
"""
mutable struct ProloguePrinter <: AbstractPrinter
    file::AbstractString
    show_info::Bool
end
ProloguePrinter(file::AbstractString; info=true) = ProloguePrinter(file, info)

function (x::ProloguePrinter)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "ProloguePrinter_log", x.show_info)
    module_name = get(general_options, "module_name", "")
    jll_pkg_name = get(general_options, "jll_pkg_name", "")
    prologue_file_path = get(general_options, "prologue_file_path", "")
    use_native_enum = get(general_options, "use_julia_native_enum_type", false)

    show_info && @info "[ProloguePrinter]: print to $(x.file)"
    open(x.file, "w") do io
        # print "module name"
        if !isempty(module_name)
            println(io, "module $module_name")
            println(io)
        end
        # print _jll pkgs
        if !isempty(jll_pkg_name)
            println(io, "using $jll_pkg_name")
            println(io, "export $jll_pkg_name")
            println(io)
        end
        # print "using CEnum"
        if !use_native_enum
            println(io, "using CEnum")
            println(io)
        end
        # print prelogue patches
        if !isempty(prologue_file_path)
            println(io, read(prologue_file_path, String))
            println(io)
        end
    end
    return dag
end

"""
    EpiloguePrinter <: AbstractPrinter
In this pass, epilogues are dumped to file.
"""
mutable struct EpiloguePrinter <: AbstractPrinter
    file::AbstractString
    show_info::Bool
end
EpiloguePrinter(file::AbstractString; info=true) = EpiloguePrinter(file, info)

function (x::EpiloguePrinter)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "EpiloguePrinter_log", x.show_info)
    module_name = get(general_options, "module_name", "")
    epilogue_file_path = get(general_options, "epilogue_file_path", "")
    export_prefixes = get(general_options, "export_symbol_prefixes", "")

    show_info && @info "[EpiloguePrinter]: print to $(x.file)"
    open(x.file, "a") do io
        # print epilogue patches
        if !isempty(epilogue_file_path)
            println(io, read(epilogue_file_path, String))
            println(io)
        end
        # print exports
        if !isempty(export_prefixes)
            str = """# exports
const PREFIXES = $export_prefixes
foreach(names(@__MODULE__; all=true)) do s
    for prefix in PREFIXES
        if startswith(string(s), prefix)
            @eval export \$s
        end
    end
end"""
            println(io, str)
            println(io)
        end
        # print "end # module"
        if !isempty(module_name)
            println(io, "end # module")
        end
    end
    return dag
end

## EXPERIMENTAL
"""
    CodegenMacro <: AbstractPass
[`Codegen`](@ref) pass for macros.
"""
mutable struct CodegenMacro <: AbstractPass
    show_info::Bool
end
CodegenMacro(; info=false) = CodegenMacro(info)

function (x::CodegenMacro)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "CodegenMacro_log", x.show_info)
    codegen_options = get(options, "codegen", Dict())
    macro_options = get(codegen_options, "macro", Dict())
    macro_mode = get(macro_options, "macro_mode", "basic")

    macro_mode == "none" && return dag

    for node in dag.nodes
        node.type isa AbstractMacroNodeType || continue
        !isempty(node.exprs) && empty!(node.exprs)
        macro_emit!(dag, node, macro_options)
        show_info && @info "[CodegenMacro]: emit Julia expression for $(node.id)"
    end

    return dag
end
