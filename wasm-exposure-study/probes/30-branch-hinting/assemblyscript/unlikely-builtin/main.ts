export function classify(x: i32): i32 {
  if (unlikely(x < 0)) return -1; // the rare branch
  return x * 2;
}
