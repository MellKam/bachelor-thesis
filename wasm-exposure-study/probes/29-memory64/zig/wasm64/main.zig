export fn touch() i32 {
    const p: *volatile i32 = @ptrFromInt(16);
    p.* = 42;
    return p.*;
}
