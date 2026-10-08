const V = @Vector(4, i32);

export fn simd_add(a: i32, b: i32) i32 {
    const v: V = @as(V, @splat(a)) + @as(V, @splat(b));
    return v[0];
}

export fn simd_shuffle(a: i32, b: i32) i32 {
    const v = @shuffle(i32, @as(V, @splat(a)), @as(V, @splat(b)), [4]i32{ ~@as(i32, 0), 1, ~@as(i32, 2), 3 });
    return v[0];
}
