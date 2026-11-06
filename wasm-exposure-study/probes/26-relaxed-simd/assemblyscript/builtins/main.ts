export function relaxed_madd(a: f32, b: f32, c: f32): f32 {
  return v128.extract_lane<f32>(v128.relaxed_madd<f32>(v128.splat<f32>(a), v128.splat<f32>(b), v128.splat<f32>(c)), 0);
}
