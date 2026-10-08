function a(n: i32, acc: i32): i32 {
  if (n == 0) return acc;
  return b(n - 1, acc + 1);
}
function b(n: i32, acc: i32): i32 {
  if (n == 0) return acc;
  return a(n - 1, acc + 1);
}
export function count(n: i32, acc: i32): i32 { return a(n, acc); }
