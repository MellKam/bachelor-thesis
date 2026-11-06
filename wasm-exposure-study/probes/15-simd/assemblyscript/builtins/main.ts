export function simd_add(a: i32, b: i32): i32 {
  return v128.extract_lane<i32>(v128.add<i32>(v128.splat<i32>(a), v128.splat<i32>(b)), 0);
}

export function simd_shuffle(a: i32, b: i32): i32 {
  return v128.extract_lane<i32>(v128.shuffle<i32>(v128.splat<i32>(a), v128.splat<i32>(b), 4, 1, 6, 3), 0);
}
