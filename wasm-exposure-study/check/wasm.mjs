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
  constExpr() { // parses the whole expression; `lastOps` keeps the opcode names so extended constants (arithmetic) can be told from plain ones
    const ops = []; let first = null;
    for (;;) {
      const op = this.u8(); if (op === 0x0b) break;
      let v = null;
      if (op === 0x41 || op === 0x42) { v = this.s64(); ops.push(op === 0x41 ? 'i32.const' : 'i64.const'); }
      else if (op === 0x23) { v = `global.get ${this.u32()}`; ops.push('global.get'); }
      else if (op === 0x43) { this.p += 4; ops.push('f32.const'); } else if (op === 0x44) { this.p += 8; ops.push('f64.const'); }
      else if (op === 0xd0) { this.s64(); v = 'ref.null'; ops.push('ref.null'); }
      else if (op === 0xd2) { this.u32(); ops.push('ref.func'); }
      else if (op === 0x6a) ops.push('i32.add'); else if (op === 0x6b) ops.push('i32.sub'); else if (op === 0x6c) ops.push('i32.mul');
      else if (op === 0x7c) ops.push('i64.add'); else if (op === 0x7d) ops.push('i64.sub'); else if (op === 0x7e) ops.push('i64.mul');
      else { ops.push(`op 0x${op.toString(16)}`); while (this.b[this.p] !== 0x0b) this.p++; } // unknown (e.g. a GC constructor): skip to the end
      if (first === null) first = v;
    }
    this.lastOps = ops;
    if (ops.length !== 1) return `expr ${ops.join(' ')}`; // anything but a single plain operand is not a number an offset lookup may use
    return first === null ? `op ${ops[0]}` : (typeof first === 'bigint' ? Number(first) : first);
  }
}

export function parseModule(bytes) {
  const m = { types: [], imports: [], funcTypeIdx: [], tables: [], memories: [], globals: [], exports: [], start: null,
              datas: [], tags: [], customs: [], customData: [], hasStruct: false, hasArray: false, hasSubtype: false, hasPackedField: false, hasPackedArray: false, sections: [], elemCount: 0, unsupported: [] };
  const r = new Reader(bytes, 8);
  while (r.p < bytes.length) {
    const id = r.u8(); const size = r.u32(); const end = r.p + size; m.sections.push(id);
    try {
      if (id === 0) { const nm = r.name(); m.customs.push(nm); m.customData.push({ name: nm, at: m.sections.length - 1, bytes: [...r.bytes(end - r.p)] }); }
      else if (id === 1) for (let n = r.u32(); n--;) {
        const readComp = () => { // one composite type; pushes exactly one entry to m.types
          const form = r.u8();
          if (form === 0x60) {
            const params = [], results = [];
            for (let k = r.u32(); k--;) params.push(r.vt()); for (let k = r.u32(); k--;) results.push(r.vt());
            m.types.push({ params, results });
          } else if (form === 0x5f) { // struct: vec of (storagetype, mutability)
            for (let k = r.u32(); k--;) { if (/^0x7[78]$/.test(r.vt())) m.hasPackedField = true; r.u8(); }
            m.types.push({ kind: 'struct', params: [], results: [] }); m.hasStruct = true;
          } else if (form === 0x5e) { // array: storagetype, mutability
            if (/^0x7[78]$/.test(r.vt())) m.hasPackedArray = true; r.u8(); m.types.push({ kind: 'array', params: [], results: [] }); m.hasArray = true;
          } else throw new Error(`type form 0x${form.toString(16)}`);
        };
        const readSub = () => { // optional `sub` / `sub final` wrapper around a composite type
          const b = r.b[r.p];
          if (b === 0x50 || b === 0x4f) { r.u8(); for (let k = r.u32(); k--;) { r.u32(); m.hasSubtype = true; } }
          readComp();
        };
        const b0 = r.b[r.p];
        if (b0 === 0x4e) { r.u8(); for (let k = r.u32(); k--;) readSub(); } // rec group
        else readSub();
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
      else if (id === 6) for (let n = r.u32(); n--;) { const type = r.vt(); const mutable = !!r.u8(); const init = r.constExpr(); m.globals.push({ type, mutable, init, ops: r.lastOps }); }
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
  // byte at `addr` in memory 0 as initialised by active data segments (undefined if no segment covers it)
  m.initialByte = (addr) => { for (const d of m.datas) { if (d.mode === 'active' && d.memory === 0 && typeof d.offset === 'number' && addr >= d.offset && addr < d.offset + d.bytes.length) return d.bytes[addr - d.offset]; } return undefined; };
  m.tableCount = imp('table').length + m.tables.length;
  return m;
}
export const sig = (t) => t ? `(${t.params.join(', ')}) -> (${t.results.join(', ')})` : null;
