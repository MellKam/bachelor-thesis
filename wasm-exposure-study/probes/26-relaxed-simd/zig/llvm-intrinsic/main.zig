// Declares LLVM's intrinsic by name. Not a documented Zig API: it is the LLVM name leaking through `extern fn`.
const V = @Vector(4, f32);
extern fn @"llvm.wasm.relaxed.madd.v4f32"(V, V, V) V;

export fn relaxed_madd(a: f32, b: f32, c: f32) f32 {
    const r = @"llvm.wasm.relaxed.madd.v4f32"(@as(V, @splat(a)), @as(V, @splat(b)), @as(V, @splat(c)));
    return r[0];
}
