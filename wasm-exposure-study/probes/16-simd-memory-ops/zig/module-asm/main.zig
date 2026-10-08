// @Vector gets load, store and bitwise select but not the saturating narrow; module-level assembly writes all three exports.
comptime {
    asm (
        \\.globl v_copy
        \\.export_name v_copy, v_copy
        \\v_copy:
        \\  .functype v_copy (i32) -> (i32)
        \\  local.get 0
        \\  local.get 0
        \\  v128.load 0
        \\  v128.store 16
        \\  local.get 0
        \\  i32.load8_u 16
        \\  end_function
        \\.globl v_select
        \\.export_name v_select, v_select
        \\v_select:
        \\  .functype v_select (i32) -> (i32)
        \\  local.get 0
        \\  local.get 0
        \\  v128.load 0
        \\  local.get 0
        \\  v128.load 16
        \\  local.get 0
        \\  v128.load 32
        \\  v128.bitselect
        \\  v128.store 48
        \\  local.get 0
        \\  i32.load 48
        \\  end_function
        \\.globl v_narrow
        \\.export_name v_narrow, v_narrow
        \\v_narrow:
        \\  .functype v_narrow (i32) -> (i32)
        \\  local.get 0
        \\  local.get 0
        \\  v128.load 0
        \\  local.get 0
        \\  v128.load 16
        \\  i8x16.narrow_i16x8_s
        \\  v128.store 32
        \\  local.get 0
        \\  i32.load8_u 39
        \\  end_function
    );
}
