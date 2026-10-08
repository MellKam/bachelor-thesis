const V16 = @Vector(16, u8);
const V16s = @Vector(16, i16);
const V8s = @Vector(8, i16);

fn ld(p: u32, off: u32) V16 {
    const q: *align(1) const V16 = @ptrFromInt(p + off);
    return q.*;
}
fn st(p: u32, off: u32, v: V16) void {
    const q: *align(1) V16 = @ptrFromInt(p + off);
    q.* = v;
}

// Vectors come from and go to linear memory, so LLVM cannot scalarise them.
export fn v_copy(p: u32) u32 {
    st(p, 16, ld(p, 0));
    return @as(*const volatile u8, @ptrFromInt(p + 16)).*;
}

export fn v_select(p: u32) u32 {
    const a = ld(p, 0);
    const b = ld(p, 16);
    const m = ld(p, 32);
    const r = (a & m) | (b & ~m);
    st(p, 48, r);
    const w: @Vector(4, u32) = @bitCast(r);
    return w[0];
}

export fn v_narrow(p: u32) u32 {
    const a: V8s = @bitCast(ld(p, 0));
    const b: V8s = @bitCast(ld(p, 16));
    const ab = @shuffle(i16, a, b, [16]i32{ 0, 1, 2, 3, 4, 5, 6, 7, ~@as(i32, 0), ~@as(i32, 1), ~@as(i32, 2), ~@as(i32, 3), ~@as(i32, 4), ~@as(i32, 5), ~@as(i32, 6), ~@as(i32, 7) });
    const lo: V16s = @splat(-128);
    const hi: V16s = @splat(127);
    const c = @min(@max(ab, lo), hi); // saturate to the i8 range
    const r: @Vector(16, i8) = @intCast(c);
    st(p, 32, @bitCast(r));
    return @as(*const volatile u8, @ptrFromInt(p + 39)).*;
}
