(module
  (func (export "simd_add") (param i32 i32) (result i32)
    (i32x4.extract_lane 0 (i32x4.add (i32x4.splat (local.get 0)) (i32x4.splat (local.get 1)))))
  (func (export "simd_shuffle") (param i32 i32) (result i32)
    (i32x4.extract_lane 0 (i8x16.shuffle 16 17 18 19 4 5 6 7 24 25 26 27 12 13 14 15
      (i32x4.splat (local.get 0)) (i32x4.splat (local.get 1))))))
