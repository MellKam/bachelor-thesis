const std = @import("std");

export fn i_add(a: i32, b: i32) i32 { return a +% b; }
export fn i_sub(a: i32, b: i32) i32 { return a -% b; }
export fn i_mul(a: i32, b: i32) i32 { return a *% b; }
export fn i_div(a: i32, b: i32) i32 { return @divTrunc(a, b); }
export fn i_rem(a: i32, b: i32) i32 { return @rem(a, b); }
export fn i_clz(a: i32) i32 { return @clz(@as(u32, @bitCast(a))); }
export fn i_ctz(a: i32) i32 { return @ctz(@as(u32, @bitCast(a))); }
export fn i_popcnt(a: i32) i32 { return @popCount(@as(u32, @bitCast(a))); }
export fn i_rotl(a: i32, n: i32) i32 { return @bitCast(std.math.rotl(u32, @bitCast(a), @as(u5, @truncate(@as(u32, @bitCast(n)))))); }
export fn i_rotr(a: i32, n: i32) i32 { return @bitCast(std.math.rotr(u32, @bitCast(a), @as(u5, @truncate(@as(u32, @bitCast(n)))))); }
