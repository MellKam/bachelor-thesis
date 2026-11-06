# 11-conversions-sign-extension — WX: Absent (confirmed)

std has no intrinsic for `i32.trunc_sat_f64_*`, `i32.extend8_s` or `i32.extend16_s`: `i32_trunc_f64` is the trapping conversion and narrow integers are held as i32 with unchecked `transmute`.

**Status:** Not implemented yet; the instructions fit the current intrinsic design and are easy to add. Absent in the current compiler, not ruled out by the language design.
