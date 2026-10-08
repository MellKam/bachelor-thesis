export function roundtrip(x: i32): i32 {
  try {
    if (x >= 0) throw new Error("boom");
    return x;
  } catch (e) {
    return x;
  }
}
