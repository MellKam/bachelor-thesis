// Zig has no builtin for f64.min/f64.max (@min/@max have different NaN rules), ties-to-even rounding or copysign as an instruction;
// module-level assembly writes them.
comptime {
    asm (
        \\.globl f_min
        \\.export_name f_min, f_min
        \\f_min:
        \\  .functype f_min (f64, f64) -> (f64)
        \\  local.get 0
        \\  local.get 1
        \\  f64.min
        \\  end_function
        \\.globl f_max
        \\.export_name f_max, f_max
        \\f_max:
        \\  .functype f_max (f64, f64) -> (f64)
        \\  local.get 0
        \\  local.get 1
        \\  f64.max
        \\  end_function
        \\.globl f_nearest
        \\.export_name f_nearest, f_nearest
        \\f_nearest:
        \\  .functype f_nearest (f64) -> (f64)
        \\  local.get 0
        \\  f64.nearest
        \\  end_function
        \\.globl f_copysign
        \\.export_name f_copysign, f_copysign
        \\f_copysign:
        \\  .functype f_copysign (f64, f64) -> (f64)
        \\  local.get 0
        \\  local.get 1
        \\  f64.copysign
        \\  end_function
    );
}

export fn f_sqrt(x: f64) f64 { return @sqrt(x); }
export fn f_ceil(x: f64) f64 { return @ceil(x); }
export fn f_floor(x: f64) f64 { return @floor(x); }
export fn f_trunc(x: f64) f64 { return @trunc(x); }
export fn f_abs(x: f64) f64 { return @abs(x); }
