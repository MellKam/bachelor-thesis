// Acceptance checks for every probe in PROBES.md. Each check inspects module *structure* (wasm.mjs),
// instruction text (wasm2wat) and observable behaviour (instantiate + call). Never byte equality.
import { sig } from './wasm.mjs';

class Result {
  constructor() { this.checks = []; }
  add(name, ok, detail = '') { this.checks.push({ name, ok: !!ok, detail }); return !!ok; }
  get pass() { return this.checks.every((c) => c.ok); }
}

// Build an import object that satisfies whatever the module declares, so a module with extra
// (unrequested) imports can still be exercised; probe-specific values override the defaults.
export function makeImports(facts, overrides = {}) {
  const o = {};
  for (const i of facts.imports) {
    o[i.module] ??= {};
    const given = overrides[i.module]?.[i.name];
    if (given !== undefined) { o[i.module][i.name] = given; continue; }
    if (i.kind === 'func') o[i.module][i.name] = (...a) => (i.type?.results.length ? 0 : undefined);
    else if (i.kind === 'memory') o[i.module][i.name] = new WebAssembly.Memory({ initial: i.min, ...(i.max != null && { maximum: i.max }), shared: i.shared });
    else if (i.kind === 'global') o[i.module][i.name] = new WebAssembly.Global({ value: i.type, mutable: i.mutable }, i.type === 'i64' ? 0n : 0);
    else if (i.kind === 'table') o[i.module][i.name] = new WebAssembly.Table({ element: i.reftype === 'externref' ? 'externref' : 'anyfunc', initial: i.min });
  }
  return o;
}

async function instantiate(ctx, r, overrides) {
  try {
    const { instance } = await WebAssembly.instantiate(ctx.bytes, makeImports(ctx.facts, overrides));
    r.add('instantiates', true); return instance;
  } catch (e) { r.add('instantiates', false, String(e.message ?? e)); return null; }
}
const hasExport = (f, name, kind) => f.exports.some((e) => e.name === name && e.kind === kind);
const eqSig = (t, p, rs) => t && t.params.join() === p.join() && t.results.join() === rs.join();
const tryCall = (r, name, fn, expect) => {
  try { const v = fn(); r.add(name, JSON.stringify(v) === JSON.stringify(expect), `got ${JSON.stringify(v)}, expected ${JSON.stringify(expect)}`); }
  catch (e) { r.add(name, false, String(e.message ?? e)); }
};

export const PROBES = {
  async P1(ctx) {
    const { facts } = ctx;
    const r = new Result(); const imp = facts.imports.find((i) => i.module === 'host' && i.name === 'log' && i.kind === 'func');
    r.add('import host.log', imp, 'imports: ' + facts.imports.map((i) => `${i.module}.${i.name}`).join(', '));
    r.add('import type (i32) -> ()', eqSig(imp?.type, ['i32'], []), sig(imp?.type));
    r.add('export run () -> ()', eqSig(facts.exportedFunc('run'), [], []), sig(facts.exportedFunc('run')));
    const seen = []; const inst = await instantiate(ctx, r, { host: { log: (x) => seen.push(x) } });
    if (inst) { try { inst.exports.run(); } catch (e) { r.add('run() ok', false, e.message); } r.add('log received 42', seen.join() === '42', `received [${seen}]`); }
    return r;
  },
  async P2(ctx) { // memory configuration; ctx.variant is "export" (define + export as mem) or "import" (import host.mem)
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
  async P3(ctx) {
    const { facts, wat } = ctx; const r = new Result();
    r.add('two or more memories', facts.memoryCount >= 2, `${facts.memoryCount}`);
    const copies = [...wat.matchAll(/memory\.copy\s+(\S+)\s+(\S+)/g)].map((m) => [m[1], m[2]]);
    r.add('memory.copy with differing memory operands', copies.some(([a, b]) => a !== b), 'copies: ' + JSON.stringify(copies));
    const inst = await instantiate(ctx, r);
    if (inst?.exports.copy_test) tryCall(r, 'copy_test() == 10', () => inst.exports.copy_test(), 10); else r.add('export copy_test', false);
    return r;
  },
  async P4(ctx) {
    const { facts } = ctx; const r = new Result();
    const g = facts.exports.find((e) => e.name === 'counter' && e.kind === 'global');
    r.add('exported global "counter"', g); r.add('counter is mutable i32', g && facts.globals[g.index - facts.imports.filter((i) => i.kind === 'global').length]?.mutable && true);
    const b = facts.imports.find((i) => i.module === 'host' && i.name === 'base' && i.kind === 'global');
    r.add('imported global host.base (immutable i32)', b && b.type === 'i32' && !b.mutable, JSON.stringify(b));
    const inst = await instantiate(ctx, r, { host: { base: new WebAssembly.Global({ value: 'i32' }, 41) } });
    if (inst?.exports.bump) { tryCall(r, 'bump() == 42', () => inst.exports.bump(), 42); r.add('counter global == 42', inst.exports.counter?.value === 42, `${inst.exports.counter?.value}`); } else r.add('export bump', false);
    return r;
  },
  async P5(ctx) {
    const { facts, wat } = ctx; const r = new Result();
    r.add('funcref table', facts.tables.some((t) => t.reftype === 'funcref'));
    r.add('element segment', facts.elemCount >= 1);
    r.add('call_indirect present', /call_indirect/.test(wat));
    const inst = await instantiate(ctx, r);
    if (inst?.exports.call_slot) { tryCall(r, 'call_slot(0,5) == 10', () => inst.exports.call_slot(0, 5), 10); tryCall(r, 'call_slot(1,5) == 105', () => inst.exports.call_slot(1, 5), 105); } else r.add('export call_slot', false);
    return r;
  },
  async P6(ctx) {
    const { facts } = ctx; const r = new Result(); const t = facts.exportedFunc('divmod');
    r.add('divmod has two results', t && t.results.length === 2, sig(t)); r.add('divmod (i32, i32) -> (i32, i32)', eqSig(t, ['i32', 'i32'], ['i32', 'i32']), sig(t));
    const inst = await instantiate(ctx, r); if (inst?.exports.divmod) tryCall(r, 'divmod(17,5) == [3,2]', () => inst.exports.divmod(17, 5), [3, 2]); return r;
  },
  async P7(ctx) {
    const { facts } = ctx; const r = new Result();
    r.add('start section references a function', facts.start !== null, 'start = ' + facts.start + ' (if absent, record a documented equivalent as partial)');
    const inst = await instantiate(ctx, r); if (inst?.exports.get) tryCall(r, 'get() == 7 on first call', () => inst.exports.get(), 7); else r.add('export get', false); return r;
  },
  async P8(ctx) {
    const { facts } = ctx; const r = new Result(); const t = facts.exportedFunc('identity');
    r.add('identity (externref) -> (externref)', eqSig(t, ['externref'], ['externref']), sig(t));
    const inst = await instantiate(ctx, r); if (inst?.exports.identity) { const o = { a: 1 }; try { r.add('returns the identical object', inst.exports.identity(o) === o); } catch (e) { r.add('identity call', false, e.message); } } return r;
  },
  async P9(ctx) {
    const { facts, wat } = ctx; const r = new Result();
    r.add('tag section with an i32-payload tag', facts.tags.some((t) => t.type.params.join() === 'i32'), 'tags: ' + JSON.stringify(facts.tags.map((t) => sig(t.type))));
    r.add('exception-handling instructions', /try_table|\btry\b|\bcatch\b|\bthrow\b/.test(wat));
    const inst = await instantiate(ctx, r); if (inst?.exports.roundtrip) tryCall(r, 'roundtrip(5) == 5', () => inst.exports.roundtrip(5), 5); else r.add('export roundtrip', false); return r;
  },
  async P10(ctx) {
    const { wat } = ctx; const r = new Result();
    r.add('i32.popcnt opcode present', /i32\.popcnt/.test(wat)); r.add('i32x4.add opcode present', /i32x4\.add/.test(wat));
    const inst = await instantiate(ctx, r);
    if (inst?.exports.popcount) tryCall(r, 'popcount(255) == 8', () => inst.exports.popcount(255), 8); else r.add('export popcount', false);
    if (inst?.exports.simd_add) tryCall(r, 'simd_add(2,3) == 5', () => inst.exports.simd_add(2, 3), 5); else r.add('export simd_add', false);
    return r;
  },
  async P11(ctx) { // supplementary: custom sections only
    const { facts } = ctx; const r = new Result();
    r.add('custom section "meta"', facts.customs.includes('meta'), 'custom sections: ' + facts.customs.join(', '));
    await instantiate(ctx, r); return r;
  },
  async P12(ctx) { // baseline measurement, not pass/fail on surplus
    const { facts, bytes } = ctx; const r = new Result();
    r.add('exports add (i32, i32) -> (i32)', eqSig(facts.exportedFunc('add'), ['i32', 'i32'], ['i32']), sig(facts.exportedFunc('add')));
    const inst = await instantiate(ctx, r); if (inst?.exports.add) tryCall(r, 'add(2,3) == 5', () => inst.exports.add(2, 3), 5);
    r.surface = {
      bytes: bytes.length,
      imports: facts.imports.map((i) => `${i.module}.${i.name} (${i.kind})`),
      unrequestedExports: facts.exports.filter((e) => e.name !== 'add').map((e) => `${e.name} (${e.kind})`),
      definedFunctions: facts.funcTypeIdx.length, memories: facts.allMemories, definedGlobals: facts.globals.length,
      tables: facts.tables.length, tags: facts.tags.length, start: facts.start, customSections: facts.customs, dataSegments: facts.datas.length,
    };
    return r;
  },
};
