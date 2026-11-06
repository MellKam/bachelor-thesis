export const DATA = [4]u8{ 'W', 'A', 'S', 'M' };

export fn peek(addr: u32) u32 {
    return @as(*const volatile u8, @ptrFromInt(addr)).*;
}
