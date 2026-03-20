"""
Test to understand how libclang reports bitfield offsets and support for larger bitfields.
This test file is for analysis purposes and demonstrates the current limitations
and what would be needed to support larger bitfields (up to 52 bits).
"""

import Clang

# Test basic bitfield offset reporting
@testset "Bitfield offset analysis" begin
    # Create test code with various bitfield sizes
    code = """
    struct BasicBitfield {
        unsigned int a : 8;
        unsigned int b : 16;
        unsigned int c : 8;
    };
    
    struct LargeBitfield {
        unsigned int a : 5;
        unsigned int b : 50;
        unsigned int c : 3;
    };
    
    struct ZeroWidthBitfield {
        unsigned int a : 3;
        unsigned int : 0;
        unsigned int b : 5;
    };
    
    struct AlignmentBitfield {
        unsigned char a : 4;
        unsigned short b : 12;
        unsigned int c : 20;
    };
    """
    
    idx = Clang.Index_create(false, false)
    unsaved = Clang.CXUnsavedFile(
        Cstring(pointer("test.h")), 
        Cstring(pointer(code)), 
        length(code)
    )
    tu = Clang.parse_translation_unit(
        idx, "test.h", String[],
        Cstring[pointer(unsaved)], 1, UInt32(0)
    )
    
    root = Clang.getTranslationUnitCursor(tu)
    
    structs_data = Dict()
    
    function visit_cursor(cursor, parent)
        kind = Clang.getcursorkind(cursor)
        if kind == Clang.CXCursor_StructDecl
            struct_name = Clang.spelling(cursor)
            ty = Clang.getCursorType(cursor)
            fields = Clang.fields(ty)
            
            struct_info = []
            for field in fields
                fname = Clang.spelling(field)
                is_bf = Clang.isBitField(field) != 0
                
                if is_bf
                    width = Clang.getFieldDeclBitWidth(field)
                    offset = Clang.getOffsetOfField(field)
                    push!(struct_info, (fname, "bitfield", width, offset))
                else
                    if !isempty(fname)  # Only track named fields
                        offset = Clang.getOffsetOfField(field)
                        push!(struct_info, (fname, "regular", nothing, offset))
                    end
                end
            end
            structs_data[struct_name] = struct_info
        end
        return Clang.CXChildVisit_Continue
    end
    
    Clang.visit(root, visit_cursor, nothing)
    Clang.Index_dispose(idx)
    
    # Print collected data for analysis
    println("\n=== Bitfield offset analysis ===")
    for (struct_name, fields) in structs_data
        println("\nStruct: $struct_name")
        for (fname, field_type, width, offset) in fields
            if field_type == "bitfield"
                println("  '$fname': bitfield width=$width bits, offset=$offset bits")
            else
                println("  '$fname': regular field, offset=$offset bits")
            end
        end
    end
    
    # Validate basic assumptions
    basic = get(structs_data, "BasicBitfield", [])
    if !isempty(basic)
        # a: 8 bits at offset 0
        # b: 16 bits at offset 8
        # c: 8 bits at offset 24
        @test length(basic) == 3
    end
end
