// Module-level assembly writes f32x4.relaxed_madd.
comptime {
    asm (
        \\.section .text.relaxed_madd,"",@
        \\.globl relaxed_madd
        \\.export_name relaxed_madd, relaxed_madd
        \\relaxed_madd:
        \\  .functype relaxed_madd (f32, f32, f32) -> (f32)
        \\  local.get 0
        \\  f32x4.splat
        \\  local.get 1
        \\  f32x4.splat
        \\  local.get 2
        \\  f32x4.splat
        \\  f32x4.relaxed_madd
        \\  f32x4.extract_lane 0
        \\  end_function
    );
}
