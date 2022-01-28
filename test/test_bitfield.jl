using ClangCompiler
using ClangCompiler.LLVM
using Clang.Generators
using Test

# Compile
src = joinpath(@__DIR__, "bitfield", "bitfield.c")
args = get_compiler_args()
jit = LLJIT(; tm = JITTargetMachine())
irgen = IRGenerator(src, args)
cc = CXCompiler(irgen, jit)
link_process_symbols(cc)
compile(cc)

options = Dict("general" => Dict(), "codegen" => Dict())
options["general"]["output_file_path"] = joinpath(@__DIR__, "LibBitField.jl")
options["codegen"]["add_record_constructors"] = true
ctx = create_context(joinpath(@__DIR__, "bitfield", "bitfield.h"), args, options)

build!(ctx, BUILDSTAGE_NO_PRINTING)

function rewrite!(dag::ExprDAG)
    for node in get_nodes(dag)
        node.type isa Generators.AbstractFunctionNodeType || continue
        func_name = string(node.id)
        handle = Symbol(func_name * "_handle")
        for expr in node.exprs
            Meta.isexpr(expr, :function) || continue
            for block_expr in expr.args
                Meta.isexpr(block_expr, :block) || continue
                for ccall_expr in block_expr.args
                    Meta.isexpr(ccall_expr, :call) || continue
                    handle_expr = :(pointer(lookup(jit, $func_name)))
                    ccall_expr.args[2] = handle_expr
                end
            end
        end
    end
end

rewrite!(ctx.dag)
build!(ctx, BUILDSTAGE_PRINTING_ONLY)

include("LibBitField.jl")

@testset "Bitfield" begin
    bf = Ref(BitField(Int8(10), 1.5, Int32(1e6), Int32(-4), Int32(7), UInt32(3)))
    m = Ref(Mirror(10, 1.5, 1e6, -4, 7, 3))
    GC.@preserve cc bf m begin
        pbf = Ptr{BitField}(pointer_from_objref(bf))
        pm = Ptr{Mirror}(pointer_from_objref(m))
        @test toMirror(bf) == m[]
        @test toBitfield(m).a == bf[].a
        @test toBitfield(m).b == bf[].b
        @test toBitfield(m).c == bf[].c
        @test toBitfield(m).d == bf[].d
        @test toBitfield(m).e == bf[].e
        @test toBitfield(m).f == bf[].f
    end
end

dispose(cc)
