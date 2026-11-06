extern "wasm" fn madd_raw(a : Float, b : Float, c : Float) -> Float =
  #|(func (param f32 f32 f32) (result f32) local.get 0 f32x4.splat local.get 1 f32x4.splat local.get 2 f32x4.splat f32x4.relaxed_madd f32x4.extract_lane 0)

pub fn relaxed_madd(a : Float, b : Float, c : Float) -> Float { madd_raw(a, b, c) }
