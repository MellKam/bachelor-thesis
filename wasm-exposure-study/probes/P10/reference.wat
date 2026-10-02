(module
  (func (export "popcount") (param i32) (result i32) (i32.popcnt (local.get 0)))
  (func (export "simd_add") (param i32 i32) (result i32)
    (i32x4.extract_lane 0 (i32x4.add (i32x4.splat (local.get 0)) (i32x4.splat (local.get 1))))))
