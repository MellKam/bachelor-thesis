const std = @import("std");

var buf: [512]u8 = undefined;

export fn bulk_test(n: u32) u32 {
    const p: [*]u8 = &buf;
    @memset(p[0..n], 5);
    std.mem.doNotOptimizeAway(p); // otherwise LLVM turns the copy of freshly memset bytes into a second memset
    @memcpy(p[256..][0..n], p[0..n]);
    var s: u32 = 0;
    for (0..n) |i| s += @as(*const volatile u8, &p[256 + i]).*;
    return s;
}
