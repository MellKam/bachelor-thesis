// Same workaround as 18: `ref.func` is rejected, so the funcref comes from the implicit table 0 via `table.get`.
comptime {
    asm (
        \\.tabletype __indirect_function_table, funcref
        \\.tabletype t, funcref, 1
        \\t:
        \\.functype slot_of_f () -> (i32)
        \\.section .text.table_ops,"",@
        \\.globl table_ops
        \\.export_name table_ops, table_ops
        \\table_ops:
        \\  .functype table_ops (i32) -> (i32)
        \\  ref.null_func
        \\  local.get 0
        \\  table.grow t
        \\  drop
        \\  i32.const 1
        \\  call slot_of_f
        \\  table.get __indirect_function_table
        \\  table.set t
        \\  table.size t
        \\  i32.const 2
        \\  table.get t
        \\  ref.is_null
        \\  i32.const 100
        \\  i32.mul
        \\  i32.add
        \\  i32.const 1
        \\  table.get t
        \\  ref.is_null
        \\  i32.eqz
        \\  i32.const 1000
        \\  i32.mul
        \\  i32.add
        \\  end_function
    );
}

fn f() callconv(.c) void {}

// the slot of f in the implicit function table; the assembly copies the funcref from there (ref.func is rejected by LLVM 21's assembler)
export fn slot_of_f() usize {
    return @intFromPtr(&f);
}
