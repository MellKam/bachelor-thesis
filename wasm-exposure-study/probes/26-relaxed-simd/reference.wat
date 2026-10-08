(module
  (func (export "relaxed_madd") (param f32 f32 f32) (result f32)
    (f32x4.extract_lane 0 (f32x4.relaxed_madd (f32x4.splat (local.get 0)) (f32x4.splat (local.get 1)) (f32x4.splat (local.get 2))))))
