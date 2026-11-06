const BUF = memory.data(512);

export function bulk_test(n: i32): i32 {
  memory.fill(BUF, 5, n);
  memory.copy(BUF + 256, BUF, n);
  let s = 0;
  for (let i = 0; i < n; i++) s += load<u8>(BUF + 256 + i);
  return s;
}
