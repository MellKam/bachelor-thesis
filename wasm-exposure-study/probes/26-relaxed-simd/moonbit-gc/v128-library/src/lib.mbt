pub fn relaxed_madd(a : Float, b : Float, c : Float) -> Float {
  let r = @v128.f32x4_relaxed_madd(@v128.f32x4_splat(a), @v128.f32x4_splat(b), @v128.f32x4_splat(c))
  @v128.f32x4_extract_lane(r, 0)
}
