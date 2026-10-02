const V = @Vector(4, i32);

export fn popcount(x: u32) u32 {
    return @popCount(x);
}

var out: V = undefined;
var xs: V = undefined;
var ys: V = undefined;

// Without volatile round-trips LLVM folds splat(a) + splat(b) into splat(a + b), as it does for Rust.
export fn simd_add(a: i32, b: i32) i32 {
    const px: *volatile V = &xs;
    const py: *volatile V = &ys;
    px.* = @splat(a);
    py.* = @splat(b);
    const p: *volatile V = &out;
    p.* = px.* + py.*;
    return p.*[0];
}
