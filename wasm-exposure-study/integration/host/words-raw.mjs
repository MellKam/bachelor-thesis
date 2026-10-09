// The glue a developer writes by hand when the module speaks the floor ABI (INTEGRATION.md): copy the UTF-8 string into memory the
// module allocated, call it, read the record back. Its non-comment lines are the "hand-written glue" figure of the I3 raw route.
export function rawAnalyse(x, text) {
  const enc = new TextEncoder().encode(text);
  const p = x.alloc(enc.length || 1);
  new Uint8Array(x.memory.buffer).set(enc, p);
  const r = x.analyse(p, enc.length);
  const dv = new DataView(x.memory.buffer);
  const longest = new TextDecoder().decode(new Uint8Array(x.memory.buffer, dv.getUint32(r + 8, true), dv.getUint32(r + 12, true)));
  return { words: dv.getUint32(r, true), bytes: dv.getUint32(r + 4, true), longest };
}
