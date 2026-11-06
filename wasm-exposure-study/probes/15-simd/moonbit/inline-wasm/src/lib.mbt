extern "wasm" fn simd_add_raw(a : Int, b : Int) -> Int =
  #|(func (param i32 i32) (result i32) local.get 0 i32x4.splat local.get 1 i32x4.splat i32x4.add i32x4.extract_lane 0)

extern "wasm" fn simd_shuffle_raw(a : Int, b : Int) -> Int =
  #|(func (param i32 i32) (result i32) local.get 0 i32x4.splat local.get 1 i32x4.splat i8x16.shuffle 16 17 18 19 4 5 6 7 24 25 26 27 12 13 14 15 i32x4.extract_lane 0)

pub fn simd_add(a : Int, b : Int) -> Int { simd_add_raw(a, b) }
pub fn simd_shuffle(a : Int, b : Int) -> Int { simd_shuffle_raw(a, b) }
