// The linker decides where this goes; the source has no way to say "address 1024".
export const DATA = [4]u8{ 'W', 'A', 'S', 'M' };

export fn peek(addr: u32) u32 {
    return @as(*const volatile u8, @ptrFromInt(addr)).*;
}
