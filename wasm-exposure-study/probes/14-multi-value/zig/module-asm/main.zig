// Zig exports a struct return through an out-pointer; module-level assembly writes the two-result function directly.
comptime {
    asm (
        \\.section .text.divmod,"",@
        \\.globl divmod
        \\.export_name divmod, divmod
        \\divmod:
        \\  .functype divmod (i32, i32) -> (i32, i32)
        \\  local.get 0
        \\  local.get 1
        \\  i32.div_u
        \\  local.get 0
        \\  local.get 1
        \\  i32.rem_u
        \\  end_function
    );
}
