export function popcount(x: u32): u32 {
  return popcnt<u32>(x);
}

export function simd_add(a: i32, b: i32): i32 {
  const v = i32x4.add(i32x4.splat(a), i32x4.splat(b));
  return i32x4.extract_lane(v, 0);
}
