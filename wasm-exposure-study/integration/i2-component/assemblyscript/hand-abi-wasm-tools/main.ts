// The canonical ABI written by hand (AssemblyScript has no component support): memory, cabi_realloc and the lowered `analyse`.
// AssemblyScript export names are identifiers, so the name the component model needs ("study:words/words@0.1.0#analyse") cannot be
// written in the source; cmd renames the export in the text form of the module.
const HEAP = memory.data(1 << 20);
const RECORD = memory.data(16);
let heapTop: usize = 0;

export function cabi_realloc(oldPtr: usize, oldSize: usize, align: usize, newSize: usize): usize {
  const start = (heapTop + align - 1) & ~(align - 1);
  if (start + newSize > (1 << 20)) return 0;
  heapTop = start + newSize;
  return HEAP + start;
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
  heapTop = 0;
  return RECORD;
}
