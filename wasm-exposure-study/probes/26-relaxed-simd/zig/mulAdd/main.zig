const V = @Vector(4, f32);

export fn relaxed_madd(a: f32, b: f32, c: f32) f32 {
    const r = @mulAdd(V, @as(V, @splat(a)), @as(V, @splat(b)), @as(V, @splat(c)));
    return r[0];
}
