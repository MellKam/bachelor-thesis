const V = @Vector(4, i32);

var A: V = .{ 0, 0, 0, 0 };
var B: V = .{ 0, 0, 0, 0 };
var C: V = .{ 0, 0, 0, 0 };

// The splatted operands go through memory, so LLVM cannot turn extract(add(splat, splat)) back into a scalar add,
// and the result is used twice (stored, and one lane returned), so the lane extraction is not folded into the loads.
fn run(a: i32, b: i32, shuffle: bool) i32 {
    const pa: *volatile V = &A;
    const pb: *volatile V = &B;
    const pc: *volatile V = &C;
    pa.* = @splat(a);
    pb.* = @splat(b);
    const va: V = pa.*;
    const vb: V = pb.*;
    const r: V = if (shuffle) @shuffle(i32, va, vb, [4]i32{ ~@as(i32, 0), 1, ~@as(i32, 2), 3 }) else va + vb;
    pc.* = r;
    return r[0];
}

export fn simd_add(a: i32, b: i32) i32 { return run(a, b, false); }
export fn simd_shuffle(a: i32, b: i32) i32 { return run(a, b, true); }
