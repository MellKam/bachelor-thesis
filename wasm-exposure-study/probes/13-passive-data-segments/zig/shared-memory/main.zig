const data = [4]u8{ 'W', 'A', 'S', 'M' };

export fn load(dst: u32) void {
    const src: *const volatile [4]u8 = &data; // keeps the copy from being folded into immediate stores
    const out: [*]u8 = @ptrFromInt(dst);
    for (0..4) |i| out[i] = src[i];
}

export fn peek(addr: u32) u32 {
    return @as(*const volatile u8, @ptrFromInt(addr)).*;
}
