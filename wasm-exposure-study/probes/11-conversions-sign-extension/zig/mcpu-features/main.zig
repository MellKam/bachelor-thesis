export fn sat_trunc(x: f64) i32 { return @intFromFloat(x); }
export fn ext8(x: i32) i32 { return @as(i8, @truncate(x)); }
export fn ext16(x: i32) i32 { return @as(i16, @truncate(x)); }
