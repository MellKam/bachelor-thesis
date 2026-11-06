// `ref.func` is rejected by the LLVM 21 assembler Zig 0.16 bundles (see module-asm), so the funcrefs are copied out of the implicit table 0 with `table.get`.
comptime {
    asm (
        \\.tabletype __indirect_function_table, funcref
        \\.tabletype table_a, funcref, 1
        \\table_a:
        \\.tabletype table_b, funcref, 1
        \\table_b:
        \\.functype slot_of_add1 () -> (i32)
        \\.functype slot_of_add100 () -> (i32)
        \\.section .text.call_a,"",@
        \\.globl call_a
        \\.export_name call_a, call_a
        \\call_a:
        \\  .functype call_a (i32) -> (i32)
        \\  i32.const 0
        \\  call slot_of_add1
        \\  table.get __indirect_function_table
        \\  table.set table_a
        \\  local.get 0
        \\  i32.const 0
        \\  call_indirect table_a, (i32) -> (i32)
        \\  end_function
        \\.section .text.call_b,"",@
        \\.globl call_b
        \\.export_name call_b, call_b
        \\call_b:
        \\  .functype call_b (i32) -> (i32)
        \\  i32.const 0
        \\  call slot_of_add100
        \\  table.get __indirect_function_table
        \\  table.set table_b
        \\  local.get 0
        \\  i32.const 0
        \\  call_indirect table_b, (i32) -> (i32)
        \\  end_function
    );
}

fn add1(x: i32) callconv(.c) i32 { return x + 1; }
fn add100(x: i32) callconv(.c) i32 { return x + 100; }

// Slots in the implicit function table; the assembly copies the funcrefs from there into its own tables
// (ref.func is rejected by the LLVM 21 assembler that Zig 0.16 bundles).
export fn slot_of_add1() usize { return @intFromPtr(&add1); }
export fn slot_of_add100() usize { return @intFromPtr(&add100); }
