// Minimal WebAssembly binary decoder: module *structure* only (no instruction decoding).
// Instruction-level questions are answered from `wasm2wat` text in probes.mjs.
const VT = { 0x7f: 'i32', 0x7e: 'i64', 0x7d: 'f32', 0x7c: 'f64', 0x7b: 'v128', 0x70: 'funcref', 0x6f: 'externref', 0x69: 'exnref' };
const KIND = ['func', 'table', 'memory', 'global', 'tag'];

class Reader {
  constructor(b, p = 0) { this.b = b; this.p = p; }
  u8() { return this.b[this.p++]; }
  u32() { let r = 0n, s = 0n, x; do { x = this.b[this.p++]; r |= BigInt(x & 0x7f) << s; s += 7n; } while (x & 0x80); return Number(r); }
  s64() { let r = 0n, s = 0n, x; do { x = this.b[this.p++]; r |= BigInt(x & 0x7f) << s; s += 7n; } while (x & 0x80); if (x & 0x40) r -= 1n << s; return r; }
  name() { const n = this.u32(); const s = new TextDecoder().decode(this.b.subarray(this.p, this.p + n)); this.p += n; return s; }
  bytes(n) { const s = this.b.subarray(this.p, this.p + n); this.p += n; return s; }
  vt() { const c = this.u8(); if (VT[c]) return VT[c]; if (c === 0x63 || c === 0x64) { this.s64(); return 'gc-ref'; } return `0x${c.toString(16)}`; }
  limits() {
    const f = this.u8(); const min = this.u32(); const max = (f & 1) ? this.u32() : null;
    return { min, max, shared: !!(f & 2), memory64: !!(f & 4) };
  }
  constExpr() { // only the forms real compilers emit for offsets / initialisers
    const op = this.u8(); let v = null;
    if (op === 0x41 || op === 0x42) v = this.s64();
    else if (op === 0x23) v = `global.get ${this.u32()}`;
    else if (op === 0x43) this.p += 4; else if (op === 0x44) this.p += 8;
    else if (op === 0xd0) { this.u8(); v = 'ref.null'; }
    while (this.b[this.p] !== 0x0b) this.p++; // tolerate extended-const; skip to end
    this.p++; return v === null ? `op 0x${op.toString(16)}` : (typeof v === 'bigint' ? Number(v) : v);
  }
}

export function parseModule(bytes) {
  const m = { types: [], imports: [], funcTypeIdx: [], tables: [], memories: [], globals: [], exports: [], start: null,
              datas: [], tags: [], customs: [], sections: [], elemCount: 0, unsupported: [] };
  const r = new Reader(bytes, 8);
  while (r.p < bytes.length) {
    const id = r.u8(); const size = r.u32(); const end = r.p + size; m.sections.push(id);
    try {
      if (id === 0) m.customs.push(r.name());
      else if (id === 1) for (let n = r.u32(); n--;) {
        const form = r.u8();
        if (form !== 0x60) { m.unsupported.push(`type form 0x${form.toString(16)}`); break; }
        const params = [], results = [];
        for (let k = r.u32(); k--;) params.push(r.vt()); for (let k = r.u32(); k--;) results.push(r.vt());
        m.types.push({ params, results });
      } else if (id === 2) for (let n = r.u32(); n--;) {
        const module = r.name(), name = r.name(), k = r.u8(); const e = { module, name, kind: KIND[k] };
        if (k === 0) e.type = m.types[r.u32()];
        else if (k === 1) { e.reftype = r.vt(); Object.assign(e, r.limits()); }
        else if (k === 2) Object.assign(e, r.limits());
        else if (k === 3) { e.type = r.vt(); e.mutable = !!r.u8(); }
        else if (k === 4) { r.u8(); e.type = m.types[r.u32()]; }
        m.imports.push(e);
      } else if (id === 3) for (let n = r.u32(); n--;) m.funcTypeIdx.push(r.u32());
      else if (id === 4) for (let n = r.u32(); n--;) { const t = r.vt(); m.tables.push({ reftype: t, ...r.limits() }); }
      else if (id === 5) for (let n = r.u32(); n--;) m.memories.push(r.limits());
      else if (id === 6) for (let n = r.u32(); n--;) { const type = r.vt(); const mutable = !!r.u8(); m.globals.push({ type, mutable, init: r.constExpr() }); }
      else if (id === 7) for (let n = r.u32(); n--;) { const name = r.name(); const k = r.u8(); m.exports.push({ name, kind: KIND[k], index: r.u32() }); }
      else if (id === 8) m.start = r.u32();
      else if (id === 9) m.elemCount = r.u32();
      else if (id === 11) for (let n = r.u32(); n--;) {
        const f = r.u32(); let mode = 'active', mem = 0, offset = null;
        if (f === 1) mode = 'passive'; else { if (f === 2) mem = r.u32(); offset = r.constExpr(); }
        const len = r.u32(); m.datas.push({ mode, memory: mem, offset, bytes: [...r.bytes(len)] });
      } else if (id === 13) for (let n = r.u32(); n--;) { r.u8(); m.tags.push({ type: m.types[r.u32()] }); }
    } catch (e) { m.unsupported.push(`section ${id}: ${e.message}`); }
    r.p = end;
  }
  // derived views over both imported and defined entities
  const imp = (k) => m.imports.filter((i) => i.kind === k);
  m.memoryCount = imp('memory').length + m.memories.length;
  m.allMemories = [...imp('memory'), ...m.memories];
  m.exportedFunc = (name) => { const e = m.exports.find((x) => x.name === name && x.kind === 'func'); if (!e) return null;
    const ni = imp('func').length; return e.index < ni ? imp('func')[e.index].type : m.types[m.funcTypeIdx[e.index - ni]]; };
  return m;
}
export const sig = (t) => t ? `(${t.params.join(', ')}) -> (${t.results.join(', ')})` : null;
