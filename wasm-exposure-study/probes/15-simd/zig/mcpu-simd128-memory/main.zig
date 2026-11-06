const V = @Vector(4, i32);

var A: [4]i32 = .{ 0, 0, 0, 0 };
var B: [4]i32 = .{ 0, 0, 0, 0 };
var C: [4]i32 = .{ 0, 0, 0, 0 };

// Vectors come from and go to memory, so LLVM cannot scalarise the lane operation away.
fn run(a: i32, b: i32, shuffle: bool) i32 {
    for (0..4) |i| {
        @as(*volatile i32, &A[i]).* = a;
        @as(*volatile i32, &B[i]).* = b;
    }
    const va: V = A;
    const vb: V = B;
    const r: V = if (shuffle) @shuffle(i32, va, vb, [4]i32{ ~@as(i32, 0), 1, ~@as(i32, 2), 3 }) else va + vb;
    C = r;
    return @as(*const volatile i32, &C[0]).*;
}

export fn simd_add(a: i32, b: i32) i32 { return run(a, b, false); }
export fn simd_shuffle(a: i32, b: i32) i32 { return run(a, b, true); }
