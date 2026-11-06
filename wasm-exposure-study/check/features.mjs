// Acceptance checks for every feature in PROBES.md. Each check inspects module *structure* (wasm.mjs), instruction text
// (wat.mjs) and observable behaviour (instantiate + call). Never byte equality, so different compilers can pass.
import { sig } from './wasm.mjs';

class Result {
  constructor() { this.checks = []; this.members = null; }
  add(name, ok, detail = '', info = false) { this.checks.push({ name, ok: !!ok, detail, ...(info && { info: true }) }); return !!ok; }
  get pass() { return this.checks.filter((c) => !c.info).every((c) => c.ok); }
}

// An import object satisfying whatever the module declares, so modules with extra imports can still be exercised.
// Feature-specific values override the defaults.
export function makeImports(facts, overrides = {}) {
  const o = {};
  for (const i of facts.imports) {
    o[i.module] ??= {};
    const given = overrides[i.module]?.[i.name];
    if (given !== undefined) { o[i.module][i.name] = given; continue; }
    if (i.kind === 'func') o[i.module][i.name] = () => (i.type?.results.length ? 0 : undefined);
    else if (i.kind === 'memory') o[i.module][i.name] = new WebAssembly.Memory({ initial: i.min, ...(i.max != null && { maximum: i.max }), shared: i.shared });
    else if (i.kind === 'global') o[i.module][i.name] = ['i32', 'i64', 'f32', 'f64'].includes(i.type) ? new WebAssembly.Global({ value: i.type, mutable: i.mutable }, i.type === 'i64' ? 0n : 0) : 'stub'; // reference-typed immutable global: any JS value
    else if (i.kind === 'tag') o[i.module][i.name] = new WebAssembly.Tag({ parameters: (i.type?.params ?? []).map((p) => (['i32', 'i64', 'f32', 'f64'].includes(p) ? p : 'externref')) });
    else if (i.kind === 'table') o[i.module][i.name] = new WebAssembly.Table({ element: i.reftype === 'externref' ? 'externref' : 'anyfunc', initial: i.min });
  }
  return o;
}

async function instantiate(ctx, r, overrides) {
  try {
    const { instance } = await WebAssembly.instantiate(ctx.bytes, ctx.hostImports ? ctx.hostImports(overrides) : makeImports(ctx.facts, overrides));
    r.add('instantiates', true);
    // WASI "reactor" convention: a runtime that is not started by a start section expects the host to call `_initialize` first
    if (typeof instance.exports._initialize === 'function') {
      try { instance.exports._initialize(); r.add('host called _initialize before any other export (reactor convention)', true, '', true); }
      catch (e) { r.add('_initialize ran', false, String(e.message ?? e)); }
    }
    else if (typeof instance.exports._start === 'function') { // WASI "command": a runtime runs `_start` once, which initialises the program
      try { instance.exports._start(); r.add('host called _start before any other export (WASI command convention)', true, '', true); }
      catch (e) { r.add('_start ran', false, String(e.message ?? e), true); }
    }
    return instance;
  } catch (e) { r.add('instantiates', false, String(e.message ?? e)); return null; }
}
const hasExport = (f, name, kind) => f.exports.some((e) => e.name === name && e.kind === kind);
const eqSig = (t, p, rs) => t && t.params.join() === p.join() && t.results.join() === rs.join();
const same = (a, b) => (typeof a === 'number' && typeof b === 'number' && Number.isNaN(a) && Number.isNaN(b)) || JSON.stringify(a) === JSON.stringify(b);
const tryCall = (r, name, fn, expect) => {
  try { const v = fn(); r.add(name, same(v, expect), `got ${JSON.stringify(v)}, expected ${JSON.stringify(expect)}`); }
  catch (e) { r.add(name, false, String(e.message ?? e)); }
};

// Instruction families (08, 09): one entry per member. `ops` must appear in the exported function's text (or in a function it calls).
async function family(ctx, r, members, imports) {
  const inst = await instantiate(ctx, r, imports); r.members = {};
  for (const m of members) {
    const text = ctx.wat.reach(m.name); const f = inst?.exports[m.name];
    const emitted = text !== null && m.ops.some((re) => re.test(text));
    let behaves = false, detail = '';
    if (typeof f === 'function') { try { m.prep?.(inst); const v = f(...m.args); const mem = m.verify ? m.verify(inst) : true; behaves = same(v, m.expect) && mem; detail = `got ${JSON.stringify(v)}, expected ${JSON.stringify(m.expect)}${mem ? '' : '; memory contents differ'}`; } catch (e) { detail = String(e.message ?? e); } }
    else detail = 'export missing';
    r.members[m.label] = { export: typeof f === 'function', emitted, behaves };
    r.add(`${m.label}: export present`, typeof f === 'function' || text !== null, detail);
    r.add(`${m.label}: instruction emitted (${m.ops.map((o) => o.source.replace(/\\b/g, '').replace(/\\\./g, '.')).join(' | ')})`, emitted, text === null ? 'export missing' : '');
    r.add(`${m.label}: behaves`, behaves, detail);
  }
}

export const FEATURES = {
  async '01'(ctx) { // imports and exports
    const { facts } = ctx; const r = new Result(); const imp = facts.imports.find((i) => i.module === 'host' && i.name === 'log' && i.kind === 'func');
    r.add('import host.log', imp, 'imports: ' + facts.imports.map((i) => `${i.module}.${i.name}`).join(', '));
    r.add('import type (i32) -> ()', eqSig(imp?.type, ['i32'], []), sig(imp?.type));
    r.add('export run () -> ()', eqSig(facts.exportedFunc('run'), [], []), sig(facts.exportedFunc('run')));
    const seen = []; const inst = await instantiate(ctx, r, { host: { log: (x) => seen.push(x) } });
    if (inst) { try { inst.exports.run(); } catch (e) { r.add('run() ok', false, e.message); } r.add('log received 42', seen.join() === '42', `received [${seen}]`); }
    return r;
  },
  async '02'(ctx) { // memory configuration; variant "export" (define + export as mem) or "import" (import host.mem)
    const { facts } = ctx; const r = new Result(); const m = facts.allMemories;
    r.add('exactly one memory', m.length === 1, `${m.length} memories`);
    r.add('limits min 1 max 4', m[0]?.min === 1 && m[0]?.max === 4, JSON.stringify(m[0]));
    if (ctx.variant === 'import') {
      const i = facts.imports.find((x) => x.module === 'host' && x.name === 'mem' && x.kind === 'memory');
      r.add('imported as host.mem', i, 'memory imports: ' + facts.imports.filter((x) => x.kind === 'memory').map((x) => `${x.module}.${x.name}`));
      await instantiate(ctx, r, { host: { mem: new WebAssembly.Memory({ initial: 1, maximum: 4 }) } });
    } else {
      r.add('defined in module (not imported)', facts.memories.length === 1);
      r.add('exported as "mem"', hasExport(facts, 'mem', 'memory'), 'memory exports: ' + facts.exports.filter((e) => e.kind === 'memory').map((e) => e.name));
      await instantiate(ctx, r);
    }
    return r;
  },
  async '10'(ctx) { // globals
    const { facts } = ctx; const r = new Result();
    const g = facts.exports.find((e) => e.name === 'counter' && e.kind === 'global');
    r.add('exported global "counter"', g); r.add('counter is mutable i32', g && facts.globals[g.index - facts.imports.filter((i) => i.kind === 'global').length]?.mutable && true);
    const b = facts.imports.find((i) => i.module === 'host' && i.name === 'base' && i.kind === 'global');
    r.add('imported global host.base (immutable i32)', b && b.type === 'i32' && !b.mutable, JSON.stringify(b));
    const inst = await instantiate(ctx, r, { host: { base: new WebAssembly.Global({ value: 'i32' }, 41) } });
    if (inst?.exports.bump) { tryCall(r, 'bump() == 42', () => inst.exports.bump(), 42); r.add('counter global == 42', inst.exports.counter?.value === 42, `${inst.exports.counter?.value}`); } else r.add('export bump', false);
    return r;
  },
  async '03'(ctx) { // table + indirect call
    const { facts, wat } = ctx; const r = new Result();
    r.add('funcref table', facts.tables.some((t) => t.reftype === 'funcref'));
    r.add('element segment', facts.elemCount >= 1);
    r.add('call_indirect present', /call_indirect/.test(wat.whole));
    const inst = await instantiate(ctx, r);
    if (inst?.exports.call_slot) { tryCall(r, 'call_slot(0,5) == 10', () => inst.exports.call_slot(0, 5), 10); tryCall(r, 'call_slot(1,5) == 105', () => inst.exports.call_slot(1, 5), 105); } else r.add('export call_slot', false);
    return r;
  },
  async '05'(ctx) { // start function
    const { facts } = ctx; const r = new Result();
    r.add('start section references a function', facts.start !== null, 'start = ' + facts.start + ' (if absent, record a documented equivalent as partial)');
    const inst = await instantiate(ctx, r); if (inst?.exports.get) tryCall(r, 'get() == 7 on first call', () => inst.exports.get(), 7); else r.add('export get', false); return r;
  },
  async '06'(ctx) { // data segments: bytes "WASM" at a chosen address (1024)
    const { facts } = ctx; const r = new Result(); const want = [0x57, 0x41, 0x53, 0x4d];
    const img = want.map((_, i) => facts.initialByte(1024 + i));
    r.add('active data segment puts "WASM" at address 1024', img.every((b, i) => b === want[i]), `bytes at 1024..1027 = ${JSON.stringify(img)}; segments: ${JSON.stringify(facts.datas.map((d) => [d.mode, d.offset, d.bytes.length]))}`);
    const inst = await instantiate(ctx, r);
    if (inst?.exports.peek) { tryCall(r, 'peek(1024) == 0x57', () => inst.exports.peek(1024), 0x57); tryCall(r, 'peek(1027) == 0x4d', () => inst.exports.peek(1027), 0x4d); } else r.add('export peek', false);
    return r;
  },
  async '07'(ctx) { // custom sections: "meta" carrying the bytes "hello"
    const { facts } = ctx; const r = new Result(); const c = facts.customData.find((x) => x.name === 'meta');
    r.add('custom section "meta"', c, 'custom sections: ' + facts.customs.join(', '));
    r.add('payload is "hello"', c && Buffer.from(c.bytes).toString() === 'hello', c ? JSON.stringify(Buffer.from(c.bytes).toString()) : '');
    await instantiate(ctx, r); return r;
  },
  async '08'(ctx) { // integer operations (family)
    const r = new Result(); const op = (n) => new RegExp(`\\bi32\\.${n}\\b`);
    await family(ctx, r, [
      { label: 'add', name: 'i_add', args: [2, 3], expect: 5, ops: [op('add')] }, { label: 'sub', name: 'i_sub', args: [10, 3], expect: 7, ops: [op('sub')] },
      { label: 'mul', name: 'i_mul', args: [6, 7], expect: 42, ops: [op('mul')] }, { label: 'div', name: 'i_div', args: [17, 5], expect: 3, ops: [/\bi32\.div_[su]\b/] },
      { label: 'rem', name: 'i_rem', args: [17, 5], expect: 2, ops: [/\bi32\.rem_[su]\b/] }, { label: 'clz', name: 'i_clz', args: [1], expect: 31, ops: [op('clz')] },
      { label: 'ctz', name: 'i_ctz', args: [8], expect: 3, ops: [op('ctz')] }, { label: 'popcnt', name: 'i_popcnt', args: [255], expect: 8, ops: [op('popcnt')] },
      { label: 'rotl', name: 'i_rotl', args: [0x80000001 | 0, 1], expect: 3, ops: [op('rotl')] }, { label: 'rotr', name: 'i_rotr', args: [1, 1], expect: -2147483648, ops: [op('rotr')] },
    ]);
    return r;
  },
  async '09'(ctx) { // float builtins (family), f64
    const r = new Result(); const op = (n) => new RegExp(`\\bf64\\.${n}\\b`);
    await family(ctx, r, [
      { label: 'sqrt', name: 'f_sqrt', args: [16], expect: 4, ops: [op('sqrt')] }, { label: 'min', name: 'f_min', args: [1, 2], expect: 1, ops: [op('min')] },
      { label: 'max', name: 'f_max', args: [1, 2], expect: 2, ops: [op('max')] }, { label: 'ceil', name: 'f_ceil', args: [1.2], expect: 2, ops: [op('ceil')] },
      { label: 'floor', name: 'f_floor', args: [1.8], expect: 1, ops: [op('floor')] }, { label: 'trunc', name: 'f_trunc', args: [-1.8], expect: -1, ops: [op('trunc')] },
      { label: 'nearest', name: 'f_nearest', args: [2.5], expect: 2, ops: [op('nearest')] }, { label: 'copysign', name: 'f_copysign', args: [3, -1], expect: -3, ops: [op('copysign')] },
      { label: 'abs', name: 'f_abs', args: [-2], expect: 2, ops: [op('abs')] },
    ]);
    return r;
  },
  async '14'(ctx) { // multi-value
    const { facts } = ctx; const r = new Result(); const t = facts.exportedFunc('divmod');
    r.add('divmod has two results', t && t.results.length === 2, sig(t)); r.add('divmod (i32, i32) -> (i32, i32)', eqSig(t, ['i32', 'i32'], ['i32', 'i32']), sig(t));
    const inst = await instantiate(ctx, r); if (inst?.exports.divmod) tryCall(r, 'divmod(17,5) == [3,2]', () => inst.exports.divmod(17, 5), [3, 2]); return r;
  },
  async '17'(ctx) { // externref
    const { facts } = ctx; const r = new Result(); const t = facts.exportedFunc('identity');
    r.add('identity (externref) -> (externref)', eqSig(t, ['externref'], ['externref']), sig(t));
    const inst = await instantiate(ctx, r); if (inst?.exports.identity) { const o = { a: 1 }; try { r.add('returns the identical object', inst.exports.identity(o) === o); } catch (e) { r.add('identity call', false, e.message); } } return r;
  },
  async '18'(ctx) { // multiple tables
    const { facts, wat } = ctx; const r = new Result();
    r.add('two or more tables', facts.tableCount >= 2, `${facts.tableCount}`);
    r.add('element segments initialise the tables (informational: a table may also be filled by table.set at run time)', facts.elemCount >= 2, `${facts.elemCount}`, true);
    const ops = new Set([...wat.whole.matchAll(/call_indirect\s*((?:\$\S+|\d+)\s+)?\(type/g)].map((m) => (m[1] ?? '0').trim()));
    r.add('call_indirect uses two different tables', ops.size >= 2, `table operands: ${JSON.stringify([...ops])}`);
    const inst = await instantiate(ctx, r);
    if (inst?.exports.call_a && inst?.exports.call_b) { tryCall(r, 'call_a(5) == 6', () => inst.exports.call_a(5), 6); tryCall(r, 'call_b(5) == 105', () => inst.exports.call_b(5), 105); } else r.add('exports call_a, call_b', false);
    return r;
  },
  async '12'(ctx) { // bulk memory (family)
    const r = new Result(); const text = ctx.wat.reach('bulk_test');
    r.add('export bulk_test', text !== null);
    r.add('memory.fill emitted', text !== null && /\bmemory\.fill\b/.test(text)); r.add('memory.copy emitted', text !== null && /\bmemory\.copy\b/.test(text));
    r.add('array.fill / array.copy used instead (the GC-array equivalents; informational)', /\barray\.(fill|copy)\b/.test(ctx.wat.whole), '', true);
    const inst = await instantiate(ctx, r); if (inst?.exports.bulk_test) { tryCall(r, 'bulk_test(8) == 40', () => inst.exports.bulk_test(8), 40); tryCall(r, 'bulk_test(40) == 200', () => inst.exports.bulk_test(40), 200); } return r;
  },
  async '11'(ctx) { // non-trapping conversions and sign extension (family)
    const r = new Result(); const inst = await instantiate(ctx, r); const T = (n) => ctx.wat.reach(n);
    r.add('i32.trunc_sat_f64 emitted', /\bi32\.trunc_sat_f64_[su]\b/.test(T('sat_trunc') ?? '')); r.add('i32.extend8_s emitted', /\bi32\.extend8_s\b/.test(T('ext8') ?? '')); r.add('i32.extend16_s emitted', /\bi32\.extend16_s\b/.test(T('ext16') ?? ''));
    if (inst?.exports.sat_trunc) { tryCall(r, 'sat_trunc(1e20) == i32 max', () => inst.exports.sat_trunc(1e20), 2147483647); tryCall(r, 'sat_trunc(-1e20) == i32 min', () => inst.exports.sat_trunc(-1e20), -2147483648); tryCall(r, 'sat_trunc(NaN) == 0', () => inst.exports.sat_trunc(NaN), 0); } else r.add('export sat_trunc', false);
    if (inst?.exports.ext8) tryCall(r, 'ext8(0x80) == -128', () => inst.exports.ext8(0x80), -128); else r.add('export ext8', false);
    if (inst?.exports.ext16) tryCall(r, 'ext16(0x8000) == -32768', () => inst.exports.ext16(0x8000), -32768); else r.add('export ext16', false);
    return r;
  },
  async '15'(ctx) { // SIMD (family)
    const r = new Result(); const inst = await instantiate(ctx, r); const T = (n) => ctx.wat.reach(n) ?? '';
    r.add('simd_add: i32x4.splat emitted', /\bi32x4\.splat\b/.test(T('simd_add'))); r.add('simd_add: i32x4.add emitted', /\bi32x4\.add\b/.test(T('simd_add'))); r.add('simd_add: i32x4.extract_lane emitted', /\bi32x4\.extract_lane\b/.test(T('simd_add')));
    r.add('simd_shuffle: i8x16.shuffle emitted', /\bi8x16\.shuffle\b/.test(T('simd_shuffle')));
    if (inst?.exports.simd_add) tryCall(r, 'simd_add(2,3) == 5', () => inst.exports.simd_add(2, 3), 5); else r.add('export simd_add', false);
    if (inst?.exports.simd_shuffle) tryCall(r, 'simd_shuffle(1,2) == 2', () => inst.exports.simd_shuffle(1, 2), 2); else r.add('export simd_shuffle', false);
    return r;
  },
  async '25'(ctx) { // multiple memories
    const { facts, wat } = ctx; const r = new Result();
    r.add('two or more memories', facts.memoryCount >= 2, `${facts.memoryCount}`);
    const copies = [...wat.whole.matchAll(/memory\.copy\s+(\S+)\s+(\S+)/g)].map((m) => [m[1], m[2]]);
    r.add('memory.copy with differing memory operands', copies.some(([a, b]) => a !== b), 'copies: ' + JSON.stringify(copies));
    const inst = await instantiate(ctx, r);
    if (inst?.exports.copy_test) tryCall(r, 'copy_test() == 10', () => inst.exports.copy_test(), 10); else r.add('export copy_test', false);
    return r;
  },
  async '27'(ctx) { // exception tags
    const { facts, wat } = ctx; const r = new Result();
    r.add('tag section with at least one tag', facts.tags.length >= 1, 'tags: ' + JSON.stringify(facts.tags.map((t) => sig(t.type))));
    r.add('tag payload types (informational; the reference uses i32)', true, JSON.stringify(facts.tags.map((t) => t.type.params)), true);
    r.add('exception-handling instructions', /try_table|\btry\b|\bcatch\b|\bthrow\b/.test(wat.whole));
    const inst = await instantiate(ctx, r); if (inst?.exports.roundtrip) tryCall(r, 'roundtrip(5) == 5', () => inst.exports.roundtrip(5), 5); else r.add('export roundtrip', false); return r;
  },
  async '29'(ctx) { // 64-bit memory
    const { facts } = ctx; const r = new Result();
    r.add('a memory with a 64-bit index type', facts.allMemories.some((m) => m.memory64), JSON.stringify(facts.allMemories));
    const inst = await instantiate(ctx, r); if (inst?.exports.touch) tryCall(r, 'touch() == 42', () => inst.exports.touch(), 42); else r.add('export touch', false); return r;
  },
  async '20'(ctx) { // tail calls: 1,000,000 deep self-recursion
    const r = new Result(); const text = ctx.wat.reach('count');
    r.add('return_call emitted', text !== null && /\breturn_call(_indirect|_ref)?\b/.test(text), text === null ? 'export count missing' : '');
    const inst = await instantiate(ctx, r); if (inst?.exports.count) tryCall(r, 'count(1000000, 0) == 1000000 without overflowing the stack', () => inst.exports.count(1000000, 0), 1000000); else r.add('export count', false); return r;
  },
  async '23'(ctx) { // GC: struct + array
    const { facts } = ctx; const r = new Result(); const text = ctx.wat.whole; // anywhere in the module: allocations may happen in a global initialiser
    r.add('module defines a struct type', facts.hasStruct); r.add('module defines an array type', facts.hasArray);
    r.add('struct.new + struct.get present in the module', /\bstruct\.new/.test(text) && /\bstruct\.get/.test(text)); r.add('array.new* + array.get present in the module', /\barray\.new/.test(text) && /\barray\.get/.test(text));
    r.add('typed function references (call_ref / ref.func) used', /\bcall_ref\b|\bref\.func\b/.test(ctx.wat.whole), 'informational', true);
    const inst = await instantiate(ctx, r); if (inst?.exports.gc_test) tryCall(r, 'gc_test() == 15', () => inst.exports.gc_test(), 15); else r.add('export gc_test', false); return r;
  },
  async '26'(ctx) { // relaxed SIMD
    const r = new Result(); const text = ctx.wat.reach('relaxed_madd') ?? '';
    r.add('f32x4.relaxed_madd (or nmadd) emitted', /\bf32x4\.relaxed_n?madd\b/.test(text));
    const inst = await instantiate(ctx, r); if (inst?.exports.relaxed_madd) tryCall(r, 'relaxed_madd(2,3,4) == 10', () => inst.exports.relaxed_madd(2, 3, 4), 10); else r.add('export relaxed_madd', false); return r;
  },

  // ---- features added after the first 21 were probed (specified in PROBES.md) ----
  async '04'(ctx) { // table import and export; variant "export" (defined + exported as tbl) or "import" (imported as host.tbl)
    const { facts, wat } = ctx; const r = new Result(); const all = [...facts.imports.filter((i) => i.kind === 'table'), ...facts.tables];
    r.add('exactly one table', all.length === 1, `${all.length} tables`);
    r.add('funcref table with limits min 2 max 8', all[0]?.reftype === 'funcref' && all[0]?.min === 2 && all[0]?.max === 8, JSON.stringify(all[0]));
    r.add('call_indirect present', /call_indirect/.test(wat.whole), 'informational', true);
    if (ctx.variant === 'import') {
      const i = facts.imports.find((x) => x.module === 'host' && x.name === 'tbl' && x.kind === 'table');
      r.add('imported as host.tbl', i, 'table imports: ' + facts.imports.filter((x) => x.kind === 'table').map((x) => `${x.module}.${x.name}`));
      const tbl = new WebAssembly.Table({ element: 'anyfunc', initial: 2, maximum: 8 });
      const inst = await instantiate(ctx, r, { host: { tbl } });
      r.add('slot 0 of the host table is filled by the module', tbl.get(0) !== null, 'the module must place a function into the imported table');
      if (inst?.exports.call_slot) tryCall(r, 'call_slot(0,5) == 10', () => inst.exports.call_slot(0, 5), 10); else r.add('export call_slot', false);
    } else {
      r.add('defined in module (not imported)', facts.tables.length === 1);
      r.add('exported as "tbl"', hasExport(facts, 'tbl', 'table'), 'table exports: ' + facts.exports.filter((e) => e.kind === 'table').map((e) => e.name));
      const inst = await instantiate(ctx, r); const t = inst?.exports.tbl;
      if (t instanceof WebAssembly.Table) tryCall(r, 'tbl.get(0)(5) == 10', () => t.get(0)(5), 10); else r.add('exported table is reachable from the host', false);
    }
    return r;
  },
  async '13'(ctx) { // passive data segments: "WASM" copied on demand with memory.init
    const { facts } = ctx; const r = new Result(); const text = ctx.wat.reach('load') ?? '';
    const seg = facts.datas.find((d) => d.mode === 'passive' && Buffer.from(d.bytes).includes('WASM'));
    r.add('a passive data segment holding "WASM"', seg, `segments: ${JSON.stringify(facts.datas.map((d) => [d.mode, d.offset, d.bytes.length]))}`);
    r.add('memory.init emitted in load', /\bmemory\.init\b/.test(text), ctx.wat.reach('load') === null ? 'export load missing' : '');
    r.add('data.drop emitted', /\bdata\.drop\b/.test(text), 'informational', true);
    const inst = await instantiate(ctx, r);
    if (inst?.exports.load && inst?.exports.peek) {
      tryCall(r, 'peek(2048) == 0 before load', () => inst.exports.peek(2048), 0);
      try { inst.exports.load(2048); } catch (e) { r.add('load(2048) ok', false, String(e.message ?? e)); }
      tryCall(r, 'peek(2048) == 0x57 after load', () => inst.exports.peek(2048), 0x57); tryCall(r, 'peek(2051) == 0x4d after load', () => inst.exports.peek(2051), 0x4d);
    } else r.add('exports load and peek', false);
    return r;
  },
  async '16'(ctx) { // SIMD memory and bitwise operations (family): vectors come from linear memory so they cannot be folded to scalars
    const P = 256; const r = new Result();
    const mem = (inst) => Object.values(inst.exports).find((x) => x instanceof WebAssembly.Memory);
    const put = (inst, at, bytes) => { const m = mem(inst); if (!m) throw new Error('no exported memory for the host to write test data into'); new Uint8Array(m.buffer).set(bytes, at); };
    const get = (inst, at, n) => [...new Uint8Array(mem(inst).buffer, at, n)];
    const fill = (n, v) => Array(n).fill(v);
    const i16 = (xs) => [...new Uint8Array(new Int16Array(xs).buffer)];
    await family(ctx, r, [
      { label: 'v_copy', name: 'v_copy', ops: [/^(?=[\s\S]*\bv128\.load\b)[\s\S]*\bv128\.store\b/], args: [P], expect: 1,
        prep: (i) => put(i, P, Array.from({ length: 16 }, (_, k) => k + 1)), verify: (i) => get(i, P + 16, 16).join() === Array.from({ length: 16 }, (_, k) => k + 1).join() },
      { label: 'v_select', name: 'v_select', ops: [/\bv128\.bitselect\b/], args: [P], expect: 0x12121212,
        prep: (i) => put(i, P, [...fill(16, 0x11), ...fill(16, 0x22), ...fill(16, 0xf0)]), verify: (i) => get(i, P + 48, 16).every((b) => b === 0x12) },
      { label: 'v_narrow', name: 'v_narrow', ops: [/\bi8x16\.narrow_i16x8_s\b/], args: [P], expect: 127,
        prep: (i) => put(i, P, [...i16([1, 2, 3, 4, 5, 6, 7, 300]), ...i16([-1, -2, -3, -4, -5, -6, -7, -300])]),
        verify: (i) => get(i, P + 32, 16).join() === [1, 2, 3, 4, 5, 6, 7, 127, 255, 254, 253, 252, 251, 250, 249, 128].join() },
    ]);
    return r;
  },
  async '19'(ctx) { // operations on reference tables
    const r = new Result(); const text = ctx.wat.reach('table_ops') ?? '';
    for (const op of ['table.grow', 'table.set', 'table.get', 'table.size', 'ref.is_null']) r.add(`${op} emitted`, new RegExp(`\\b${op.replace('.', '\\.')}\\b`).test(text), ctx.wat.reach('table_ops') === null ? 'export table_ops missing' : '');
    const inst = await instantiate(ctx, r); if (inst?.exports.table_ops) tryCall(r, 'table_ops(3) == 1104', () => inst.exports.table_ops(3), 1104); else r.add('export table_ops', false); return r;
  },
  async '21'(ctx) { // extended constant expressions: a global initialiser that does arithmetic on an imported global
    const { facts } = ctx; const r = new Result();
    const b = facts.imports.find((i) => i.module === 'host' && i.name === 'base' && i.kind === 'global');
    r.add('imported global host.base (immutable i32)', b && b.type === 'i32' && !b.mutable, JSON.stringify(b));
    const g = facts.globals.find((x) => x.ops?.includes('global.get') && x.ops.some((o) => /^i32\.(add|sub|mul)$/.test(o)));
    r.add('a global initialiser combines global.get with integer arithmetic', g, 'initialisers: ' + JSON.stringify(facts.globals.map((x) => x.ops)));
    r.add('start function used instead (informational)', facts.start !== null, `start = ${facts.start}`, true);
    const inst = await instantiate(ctx, r, { host: { base: new WebAssembly.Global({ value: 'i32' }, 100) } });
    if (inst?.exports.get_g) tryCall(r, 'get_g() == 112', () => inst.exports.get_g(), 112); else r.add('export get_g', false); return r;
  },
  async '22'(ctx) { // typed function references: ref.func + call_ref, no table
    const r = new Result(); const text = ctx.wat.reach('apply') ?? ''; const miss = ctx.wat.reach('apply') === null ? 'export apply missing' : '';
    r.add('ref.func emitted (anywhere in the module: the reference may be built in an initialiser)', /\bref\.func\b/.test(ctx.wat.whole), miss); r.add('call_ref emitted in apply', /\bcall_ref\b/.test(text), miss);
    r.add('reference type is non-nullable (informational)', /\(ref \$|\(ref \d/.test(ctx.wat.whole), '', true);
    r.add('call_indirect or a table also present (informational)', /\bcall_indirect\b/.test(ctx.wat.whole) || ctx.facts.tableCount > 0, '', true);
    const inst = await instantiate(ctx, r); if (inst?.exports.apply) tryCall(r, 'apply(5) == 10', () => inst.exports.apply(5), 10); else r.add('export apply', false); return r;
  },
  async '24'(ctx) { // GC casts, subtyping, i31, packed fields (family)
    const { facts } = ctx; const r = new Result(); const text = ctx.wat.reach('gc_extra') ?? '';
    const members = {
      subtype: facts.hasSubtype,
      cast: /\bref\.(test|cast)\b/.test(text),
      i31: /\bref\.i31\b/.test(text) && /\bi31\.get_[su]\b/.test(text),
      packed: (facts.hasPackedArray || facts.hasPackedField) && /\b(array|struct)\.get_[su]\b/.test(text),
    };
    const inst = await instantiate(ctx, r); let ok = false;
    if (inst?.exports.gc_extra) { try { const v = inst.exports.gc_extra(); ok = v === 210; r.add('gc_extra() == 210', ok, `got ${JSON.stringify(v)}, expected 210`); } catch (e) { r.add('gc_extra() == 210', false, String(e.message ?? e)); } }
    else r.add('export gc_extra', false);
    r.members = {};
    const label = { subtype: 'declared subtype (sub)', cast: 'ref.test / ref.cast', i31: 'ref.i31 + i31.get', packed: 'packed i8/i16 element with get_s|u' };
    for (const [k, emitted] of Object.entries(members)) { r.members[k] = { export: !!inst?.exports.gc_extra, emitted, behaves: ok }; r.add(`${label[k]} present`, emitted, text === '' ? 'export gc_extra missing' : ''); }
    return r;
  },
  async '28'(ctx) { // exception handling with exnref: catch_ref + throw_ref inside try_table
    const { facts } = ctx; const r = new Result(); const text = ctx.wat.reach('rethrow_test') ?? ''; const miss = ctx.wat.reach('rethrow_test') === null ? 'export rethrow_test missing' : '';
    r.add('tag section with at least one tag', facts.tags.length >= 1);
    r.add('try_table emitted', /\btry_table\b/.test(text), miss); r.add('throw_ref emitted', /\bthrow_ref\b/.test(text), miss);
    r.add('catch_ref / catch_all_ref used (informational)', /\bcatch_(all_)?ref\b/.test(text), '', true);
    r.add('legacy try/catch/rethrow also used (informational)', /\b(try|rethrow|delegate)\b(?!_)/.test(text), '', true);
    const inst = await instantiate(ctx, r); if (inst?.exports.rethrow_test) tryCall(r, 'rethrow_test(5) == 5', () => inst.exports.rethrow_test(5), 5); else r.add('export rethrow_test', false); return r;
  },
  async '30'(ctx) { // branch hinting: custom section metadata.code.branch_hint with a hint on classify
    const { facts } = ctx; const r = new Result(); const c = facts.customData.find((x) => x.name === 'metadata.code.branch_hint');
    r.add('custom section "metadata.code.branch_hint"', c, 'custom sections: ' + facts.customs.join(', '));
    const codeAt = facts.sections.indexOf(10); // the proposal: the hint section appears only before the code section, so an engine reading in order never sees one placed after it
    if (c) r.add('hint section precedes the code section', codeAt < 0 || c.at < codeAt, `section order: ${facts.sections.join(',')}`);
    const hints = []; // vec(func: u32, vec(offset: u32, size: u32 = 1, value: u8))
    if (c) { const b = c.bytes; let p = 0; const u32 = () => { let v = 0, s = 0, x; do { x = b[p++]; v |= (x & 0x7f) << s; s += 7; } while (x & 0x80); return v >>> 0; };
      try { for (let n = u32(); n--;) { const fn = u32(); for (let k = u32(); k--;) { const off = u32(); u32(); hints.push({ fn, off, value: b[p++] }); } } } catch (e) { r.add('hint section decodes', false, e.message); } }
    const e = facts.exports.find((x) => x.name === 'classify' && x.kind === 'func');
    const mine = e ? hints.filter((h) => h.fn === e.index) : [];
    r.add('at least one hint targets classify', mine.length > 0, `hints: ${JSON.stringify(hints)}; classify = function ${e?.index}`);
    r.add('hint values (0 unlikely, 1 likely)', true, JSON.stringify(mine.map((h) => h.value)), true);
    const inst = await instantiate(ctx, r);
    if (inst?.exports.classify) { tryCall(r, 'classify(5) == 10', () => inst.exports.classify(5), 10); tryCall(r, 'classify(-1) == -1', () => inst.exports.classify(-1), -1); } else r.add('export classify', false);
    return r;
  },
};
