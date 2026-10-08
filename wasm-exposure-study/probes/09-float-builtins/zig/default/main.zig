const std = @import("std");

export fn f_sqrt(x: f64) f64 { return @sqrt(x); }
export fn f_min(x: f64, y: f64) f64 { return @min(x, y); }
export fn f_max(x: f64, y: f64) f64 { return @max(x, y); }
export fn f_ceil(x: f64) f64 { return @ceil(x); }
export fn f_floor(x: f64) f64 { return @floor(x); }
export fn f_trunc(x: f64) f64 { return @trunc(x); }
// There is no ties-to-even builtin; @round rounds half away from zero.
export fn f_nearest(x: f64) f64 { return @round(x); }
export fn f_copysign(x: f64, y: f64) f64 { return std.math.copysign(x, y); }
export fn f_abs(x: f64) f64 { return @abs(x); }
