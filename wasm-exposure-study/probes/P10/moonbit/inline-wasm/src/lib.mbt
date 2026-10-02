extern "wasm" fn popcnt_raw(x : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.popcnt)

extern "wasm" fn simd_add_raw(a : Int, b : Int) -> Int =
  #|(func (param i32 i32) (result i32) local.get 0 i32x4.splat local.get 1 i32x4.splat i32x4.add i32x4.extract_lane 0)

pub fn popcount(x : Int) -> Int {
  popcnt_raw(x)
}

pub fn simd_add(a : Int, b : Int) -> Int {
  simd_add_raw(a, b)
}
