// `words`, floor ABI: export memory, alloc(len) -> ptr, analyse(ptr, len) -> ptr to { words, bytes, longest_ptr, longest_len }.
const HEAP = memory.data(1 << 20);
const RECORD = memory.data(16);
let top: usize = 0;

export function alloc(len: i32): usize {
  const p = HEAP + top;
  top += (<usize>len + 7) & ~7;
  return p;
}

function isWs(c: u8): bool {
  return c == 32 || c == 9 || c == 10 || c == 13;
}

export function analyse(ptr: usize, len: i32): usize {
  let words: u32 = 0;
  let best: i32 = 0;
  let bestAt: i32 = 0;
  let i: i32 = 0;
  while (i < len) {
    while (i < len && isWs(load<u8>(ptr + i))) i++;
    const start = i;
    while (i < len && !isWs(load<u8>(ptr + i))) i++;
    if (i > start) {
      words++;
      if (i - start > best) { best = i - start; bestAt = start; }
    }
  }
  store<u32>(RECORD, words);
  store<u32>(RECORD, <u32>len, 4);
  store<u32>(RECORD, <u32>(ptr + bestAt), 8);
  store<u32>(RECORD, <u32>best, 12);
  top = 0;
  return RECORD;
}
