pub fn simd_add(a : Int, b : Int) -> Int {
  let r = @v128.i32x4_add(@v128.i32x4_splat(a.reinterpret_as_uint()), @v128.i32x4_splat(b.reinterpret_as_uint()))
  @v128.i32x4_extract_lane(r, 0).reinterpret_as_int()
}

pub fn simd_shuffle(a : Int, b : Int) -> Int {
  let r = @v128.i8x16_shuffle(
    @v128.i32x4_splat(a.reinterpret_as_uint()),
    @v128.i32x4_splat(b.reinterpret_as_uint()),
    16, 17, 18, 19, 4, 5, 6, 7, 24, 25, 26, 27, 12, 13, 14, 15,
  )
  @v128.i32x4_extract_lane(r, 0).reinterpret_as_int()
}
