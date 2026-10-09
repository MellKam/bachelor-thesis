export class Stats {
  words: u32 = 0;
  bytes: u32 = 0;
  longest: string = "";
}

function isWs(c: i32): bool {
  return c == 32 || c == 9 || c == 10 || c == 13;
}

export function analyse(text: string): Stats {
  const buf = String.UTF8.encode(text);
  const p = changetype<usize>(buf);
  const len = buf.byteLength;
  const r = new Stats();
  r.bytes = len;
  let best = 0, bestAt = 0, i = 0;
  while (i < len) {
    while (i < len && isWs(load<u8>(p + i))) i++;
    const start = i;
    while (i < len && !isWs(load<u8>(p + i))) i++;
    if (i > start) {
      r.words++;
      if (i - start > best) { best = i - start; bestAt = start; }
    }
  }
  r.longest = String.UTF8.decodeUnsafe(p + bestAt, best);
  return r;
}
