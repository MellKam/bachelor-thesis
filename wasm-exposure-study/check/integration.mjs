// Usage: node check/integration.mjs <I1|...> <module.wasm> [--json]
// Runs one integration criterion's acceptance checks on a built artifact (see INTEGRATION.md) and prints or emits the verdict.
// Implemented: I1 (WASI), I2 (Component Model), I3 (JS bindings), I5 (size: the programs `life` and `words`, as `I5:life` / `I5:words`).
import { readFileSync } from 'node:fs';
import { execFileSync, spawnSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { mkdtempSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname, resolve } from 'node:path';
import { parseModule } from './wasm.mjs';
import { makeImports } from './features.mjs';
import { rawAnalyse } from '../integration/host/words-raw.mjs';

const wasmTools = (args) => execFileSync('wasm-tools', args, { encoding: 'utf8', maxBuffer: 1 << 26, stdio: ['ignore', 'pipe', 'pipe'] });

// A core module starts 00 61 73 6d 01 00 00 00; a component has version 0x0d and layer 1 (0d 00 01 00).
const isComponent = (b) => b[4] === 0x0d && b[6] === 0x01;

// Which WASI the file speaks, read from the imports. p1 = wasi_snapshot_preview1; p2/p3 = `wasi:<pkg>/<iface>@0.2.x|0.3.x`.
export function wasiFacts(file, bytes) {
  const component = isComponent(bytes);
  const imports = new Set(), exports = new Set();
  if (component) {
    const text = wasmTools(['component', 'wit', file]);
    for (const m of text.matchAll(/\bimport\s+(wasi:[\w-]+\/[\w-]+(?:@[\w.-]+)?)/g)) imports.add(m[1]);
    for (const m of text.matchAll(/\bexport\s+(wasi:[\w-]+\/[\w-]+(?:@[\w.-]+)?)/g)) exports.add(m[1]);
  } else {
    const m = parseModule(bytes); // not `wasm-tools print`: a Foundation build is 60 MB of text
    for (const i of m.imports) imports.add(`${i.module}.${i.name}`);
    for (const e of m.exports) exports.add(e.name);
  }
  const all = [...imports];
  const versions = new Set();
  if (all.some((i) => i.startsWith('wasi_snapshot_preview1.'))) versions.add('p1');
  for (const i of all) { const v = /@(\d+\.\d+)/.exec(i); if (i.startsWith('wasi:') && v) versions.add(`p${v[1] === '0.2' ? 2 : v[1] === '0.3' ? 3 : v[1]}`); }
  const entry = component ? (exports.has('wasi:cli/run@0.2.0') || [...exports].some((e) => e.startsWith('wasi:cli/run')) ? 'command' : 'component') : exports.has('_start') ? 'command' : exports.has('_initialize') ? 'reactor' : 'none';
  const other = all.filter((i) => !i.startsWith('wasi_snapshot_preview1.') && !i.startsWith('wasi:'));
  return { kind: component ? 'component' : 'module', versions: [...versions], entry, imports: all, nonWasiImports: other };
}

// Size after Binaryen's -Oz (INTEGRATION.md I5). Null when wasm-opt cannot read the file (a component, say) or gives up.
export function optimisedSize(file) {
  if (statSync(file).size > 20_000_000) return null; // a 60 MB Foundation build: Binaryen takes minutes and gigabytes
  try {
    const out = join(mkdtempSync(join(tmpdir(), 'wx-opt-')), 'o.wasm');
    execFileSync(process.env.WASM_OPT || 'wasm-opt', ['-Oz', '--all-features', '--strip-debug', '--strip-producers', file, '-o', out], { stdio: 'ignore', timeout: 900000 });
    return statSync(out).size;
  } catch { return null; }
}

// I1: `cat`. stdout must equal stdin for text, empty and 100000 random bytes; exit code 0; run under `wasmtime run`.
export function checkI1(file) {
  const bytes = readFileSync(file);
  const checks = [];
  let facts;
  try { facts = wasiFacts(file, bytes); } catch (e) { return { criterion: 'I1', file, bytes: bytes.length, pass: false, checks: [{ name: 'module can be read', ok: false, detail: String(e.stderr || e.message).split('\n')[0] }] }; }
  const inputs = { text: Buffer.from('hello\nworld\n'), empty: Buffer.alloc(0), large: randomBytes(100_000) };
  for (const [name, input] of Object.entries(inputs)) {
    const r = spawnSync('wasmtime', ['run', file], { input, maxBuffer: 1 << 24, timeout: 20000 });
    let ok = false, detail = '';
    if (r.error) detail = r.error.message;
    else if (r.status !== 0) detail = `exit ${r.status}: ${String(r.stderr).slice(0, 200).replace(/\s+/g, ' ')}`;
    else if (!Buffer.from(r.stdout).equals(input)) detail = `${r.stdout.length} bytes out, ${input.length} in`;
    else ok = true;
    // The random bytes are not valid UTF-8: a text API (Kotlin readln) fails them although WASI works, so that check is informational.
    checks.push({ name: `stdout equals stdin (${name}), exit 0`, ok, detail, ...(name === 'large' && { info: true, name: 'binary-safe: stdout equals stdin (100000 random bytes), exit 0' }) });
  }
  // Informational: what the module is. A module that imports anything outside WASI cannot run under wasmtime alone, which the checks above already show.
  checks.push({ name: `WASI ${facts.versions.join('+') || 'none'}, ${facts.kind}, entry ${facts.entry}`, ok: facts.versions.length > 0, detail: facts.versions.length ? '' : 'no WASI import found', info: true });
  if (facts.nonWasiImports.length) checks.push({ name: 'imports outside WASI', ok: false, detail: facts.nonWasiImports.join(', '), info: true });
  return { criterion: 'I1', file, bytes: bytes.length, optBytes: facts.kind === 'module' ? optimisedSize(file) : null, pass: checks.filter((c) => !c.info || c.name.startsWith('WASI')).every((c) => c.ok), checks, wasi: facts };
}

// I2: the `words` component (integration/wit/words.wit). Pass = it is a valid component, its export is the study:words/words interface
// with exactly the types of the reference WIT, and `wasmtime run --invoke` returns the right record for every input.
const WIT = readFileSync(new URL('../integration/wit/words.wit', import.meta.url), 'utf8');
const norm = (t) => t.replace(/\/\/.*$/gm, '').replace(/\s+/g, ' ').replace(/,\s*}/g, ' }').replace(/\s*([{}:;,()])\s*/g, '$1').trim();
const interfaceBody = (text, name) => { const i = text.search(new RegExp(`interface\\s+${name}\\s*\\{`)); if (i < 0) return null; let d = 0, j = text.indexOf('{', i); const start = j; for (; j < text.length; j++) { if (text[j] === '{') d++; else if (text[j] === '}' && --d === 0) break; } return norm(text.slice(start, j + 1)); };
const analyseRef = (text) => { const w = text.split(/[ \t\n\r]+/).filter(Boolean); const bytes = Buffer.byteLength(text); let longest = ''; for (const x of w) if (Buffer.byteLength(x) > Buffer.byteLength(longest)) longest = x; return { words: w.length, bytes, longest }; };
export const WORDS_INPUTS = [
  'the quick brown fox', '', '  a  bb ccc  ', 'héllo wörld', 'lorem ipsum '.repeat(8333) + 'dolor', // the last is ~100 000 bytes
];
const wave = (t) => `"${t.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\t/g, '\\t').replace(/\r/g, '\\r')}"`;

export function checkI2(file) {
  const bytes = readFileSync(file);
  const checks = [];
  const res = (extra = {}) => ({ criterion: 'I2', file, bytes: bytes.length, pass: checks.every((c) => c.ok || c.info), checks, ...extra });
  const isComp = isComponent(bytes);
  checks.push({ name: 'the file is a component, not a core module', ok: isComp, detail: isComp ? '' : 'core module' });
  if (!isComp) return res();
  try { wasmTools(['validate', '--features', 'component-model', file]); checks.push({ name: 'wasm-tools validate (component-model)', ok: true, detail: '' }); }
  catch (e) { checks.push({ name: 'wasm-tools validate (component-model)', ok: false, detail: String(e.stderr || e.message).split('\n')[0] }); return res(); }
  let wit = '';
  try { wit = wasmTools(['component', 'wit', file]); } catch (e) { checks.push({ name: 'component wit can be printed', ok: false, detail: String(e.stderr).split('\n')[0] }); return res(); }
  const exp = /\bexport\s+(study:words\/words(?:@[\w.-]+)?)\s*;/.exec(wit);
  checks.push({ name: 'exports study:words/words', ok: !!exp, detail: exp ? '' : 'no such export in the world' });
  const got = interfaceBody(wit.slice(wit.indexOf('package study:words')), 'words'), want = interfaceBody(WIT, 'words');
  checks.push({ name: 'the interface has the reference types', ok: !!got && got === want, detail: got === want ? '' : `got ${got}` });
  if (!exp) return res({ wasi: wasiFacts(file, bytes) });
  for (const text of WORDS_INPUTS) {
    const r = spawnSync('wasmtime', ['run', '--invoke', `analyse(${wave(text)})`, file], { maxBuffer: 1 << 24, timeout: 30000, encoding: 'utf8' });
    const want = analyseRef(text), label = JSON.stringify(text.length > 24 ? `${text.slice(0, 12)}… (${Buffer.byteLength(text)} bytes)` : text);
    let ok = false, detail = '';
    if (r.error) detail = r.error.message;
    else if (r.status !== 0) detail = `exit ${r.status}: ${String(r.stderr).slice(0, 200).replace(/\s+/g, ' ')}`;
    else {
      const m = /^\{words: (\d+), bytes: (\d+), longest: ("(?:[^"\\]|\\.)*")\}\s*$/.exec(r.stdout);
      if (!m) detail = `unparsed: ${r.stdout.slice(0, 80)}`;
      else { let l; try { l = JSON.parse(m[3]); } catch { l = m[3]; } ok = +m[1] === want.words && +m[2] === want.bytes && l === want.longest; if (!ok) detail = `got ${m[1]}, ${m[2]}, ${l.slice(0, 20)}; want ${want.words}, ${want.bytes}, ${want.longest.slice(0, 20)}`; }
    }
    checks.push({ name: `analyse(${label}) is right`, ok, detail });
  }
  let facts = null;
  try { facts = wasiFacts(file, bytes); checks.push({ name: `imports: ${facts.imports.length ? facts.imports.length + ' WASI interfaces' : 'none'}`, ok: true, detail: '', info: true }); } catch { /* informational only */ }
  return res({ wasi: facts });
}

// Start the way the language's runtime expects (WASI reactor / command convention, as in the feature checker).
async function boot(bytes, overrides = {}) {
  const facts = parseModule(bytes);
  const { instance } = await WebAssembly.instantiate(bytes, makeImports(facts, overrides));
  if (typeof instance.exports._initialize === 'function') instance.exports._initialize();
  else if (typeof instance.exports._start === 'function') { try { instance.exports._start(); } catch { /* a command that exits */ } }
  return { instance, facts };
}

// I5 `life`: the capstone contract (import host.random() -> i32; export memory, init, step, cells_ptr, width, height), 64x64 torus, 100 steps.
export async function checkLife(file) {
  const bytes = readFileSync(file), checks = [];
  const res = (extra = {}) => ({ criterion: 'I5', program: 'life', file, bytes: bytes.length, optBytes: optimisedSize(file), pass: checks.every((c) => c.ok || c.info), checks, ...extra });
  const W = 64, H = 64, N = W * H, STEPS = 100;
  const lcg = () => { let s = 12345; return () => { s = (Math.imul(s, 1103515245) + 12345) & 0x7fffffff; return s >>> 8; }; };
  const rr = lcg();
  let ref = new Uint8Array(N); for (let i = 0; i < N; i++) ref[i] = rr() & 1;
  const refStep = () => { const nx = new Uint8Array(N); for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) { let n = 0; for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) if (dy || dx) n += ref[((y + dy + H) % H) * W + ((x + dx + W) % W)]; nx[y * W + x] = (n === 3 || (ref[y * W + x] && n === 2)) ? 1 : 0; } ref = nx; };
  try {
    const rnd = lcg();
    const { instance } = await boot(bytes, { host: { random: rnd } });
    const x = instance.exports;
    for (const n of ['memory', 'init', 'step', 'cells_ptr', 'width', 'height']) if (!(n in x)) { checks.push({ name: `exports ${n}`, ok: false, detail: 'missing' }); return res(); }
    checks.push({ name: 'width x height is 64 x 64', ok: x.width() === W && x.height() === H, detail: `${x.width()}x${x.height()}` });
    x.init(); for (let i = 0; i < STEPS; i++) { x.step(); refStep(); }
    const got = new Uint8Array(x.memory.buffer, x.cells_ptr(), N);
    let diff = 0; for (let i = 0; i < N; i++) if ((got[i] ? 1 : 0) !== ref[i]) diff++;
    checks.push({ name: `matches the reference after ${STEPS} steps`, ok: diff === 0, detail: `${diff} of ${N} cells differ` });
  } catch (e) { checks.push({ name: 'runs', ok: false, detail: String(e.message ?? e) }); }
  return res();
}

// I5 `words`, core-module form (the floor ABI of INTEGRATION.md): export memory, alloc(len) -> ptr, analyse(ptr, len) -> ptr of
// { words: u32, bytes: u32, longest_ptr: u32, longest_len: u32 }. The host marshals the string by hand (this is the I3 raw route too).
export async function checkWordsCore(file) {
  const bytes = readFileSync(file), checks = [];
  const res = (extra = {}) => ({ criterion: 'I5', program: 'words', file, bytes: bytes.length, optBytes: optimisedSize(file), pass: checks.every((c) => c.ok || c.info), checks, ...extra });
  try {
    const { instance } = await boot(bytes);
    const x = instance.exports;
    for (const n of ['memory', 'alloc', 'analyse']) if (!(n in x)) { checks.push({ name: `exports ${n}`, ok: false, detail: 'missing' }); return res(); }
    for (const text of WORDS_INPUTS) {
      const enc = Buffer.from(text, 'utf8'), want = analyseRef(text);
      const label = JSON.stringify(text.length > 24 ? `${text.slice(0, 12)}… (${enc.length} bytes)` : text);
      let ok = false, detail = '';
      try {
        const got = rawAnalyse(x, text);
        ok = got.words === want.words && got.bytes === want.bytes && got.longest === want.longest;
        if (!ok) detail = `got ${JSON.stringify(got).slice(0, 80)}`;
      } catch (e) { detail = String(e.message ?? e); }
      checks.push({ name: `analyse(${label}) is right`, ok, detail });
    }
  } catch (e) { checks.push({ name: 'runs', ok: false, detail: String(e.message ?? e) }); }
  return res();
}

// I3: the variant directory has out.wasm and adapter.mjs; adapter.mjs exports `load()` -> Promise<(text) => { words, bytes, longest }>, a thin
// wrapper over whatever the language's tooling generated. Pass = all inputs right, called from Node with no per-language host code.
export async function checkI3(file) {
  const dir = dirname(resolve(file));
  const bytes = readFileSync(file), checks = [];
  const res = (extra = {}) => ({ criterion: 'I3', file, bytes: bytes.length, pass: checks.every((c) => c.ok || c.info), checks, ...extra });
  let analyse, adapterLines = 0;
  try {
    const path = join(dir, 'adapter.mjs');
    adapterLines = readFileSync(path, 'utf8').split('\n').filter((l) => l.trim() && !l.trim().startsWith('//')).length;
    analyse = await (await import(path)).load();
    checks.push({ name: 'adapter loads the generated bindings', ok: true, detail: '' });
  } catch (e) { checks.push({ name: 'adapter loads the generated bindings', ok: false, detail: String(e.stack ?? e).split('\n').slice(0, 3).join(' | ') }); return res(); }
  for (const text of WORDS_INPUTS) {
    const want = analyseRef(text), label = JSON.stringify(text.length > 24 ? `${text.slice(0, 12)}… (${Buffer.byteLength(text)} bytes)` : text);
    let ok = false, detail = '';
    try { const got = await analyse(text); ok = Number(got.words) === want.words && Number(got.bytes) === want.bytes && got.longest === want.longest; if (!ok) detail = `got ${JSON.stringify(got).slice(0, 80)}`; }
    catch (e) { detail = String(e.message ?? e).slice(0, 160); }
    checks.push({ name: `analyse(${label}) is right`, ok, detail });
  }
  checks.push({ name: `adapter: ${adapterLines} lines of code`, ok: true, detail: '', info: true });
  return res({ adapterLines });
}

// I4: a debug build of `life`. Sub-checks (informational each, the cell is coded from them): a `name` section with function names,
// DWARF sections (.debug_*) or a source-map reference, and that the build still runs `life` correctly.
export async function checkI4(file) {
  const bytes = readFileSync(file), facts = parseModule(bytes);
  const names = facts.customs.includes('name');
  const dwarf = facts.customs.some((c) => c.startsWith('.debug_'));
  const sourceMap = facts.customs.includes('sourceMappingURL');
  const run = await checkLife(file);
  // does a trap in the module name the source function? V8 builds the stack from the name section; the function is `crash_here`
  let trap = { exported: false, named: false, stack: '' };
  try {
    const { instance } = await boot(bytes);
    if (typeof instance.exports.crash_here === 'function') {
      trap.exported = true;
      try { instance.exports.crash_here(); } catch (e) { trap.stack = String(e.stack ?? e).split('\n').slice(0, 8).join(' | '); trap.named = /crash_{1,2}here/i.test(trap.stack); }
    }
  } catch (e) { trap.stack = String(e.message ?? e); }
  const checks = [
    { name: 'name section present', ok: names, detail: '', info: true },
    { name: 'DWARF sections present', ok: dwarf, detail: '', info: true },
    { name: 'source-map reference present', ok: sourceMap, detail: '', info: true },
    { name: 'a trap names the source function in the stack', ok: trap.named, detail: trap.exported ? trap.stack.slice(0, 200) : 'crash_here not exported', info: true },
    { name: 'the debug build still runs life correctly', ok: run.pass, detail: run.checks.filter((c) => !c.ok).map((c) => c.detail).join('; ') },
  ];
  return { criterion: 'I4', file, bytes: bytes.length, pass: run.pass, checks, debug: { names, dwarf, sourceMap, trapNamed: trap.named }, customs: facts.customs };
}

const CRITERIA = { I1: checkI1, I2: checkI2, I3: checkI3, I4: checkI4, 'I5:life': checkLife, 'I5:words': checkWordsCore };

if (import.meta.url === `file://${process.argv[1]}`) {
  const [id, file, flag] = process.argv.slice(2);
  if (!CRITERIA[id]) { console.error(`unknown or unimplemented criterion ${id}`); process.exit(2); }
  const res = await CRITERIA[id](file);
  if (flag === '--json') console.log(JSON.stringify(res, null, 2));
  else {
    console.log(`${res.pass ? 'PASS' : 'FAIL'} ${id} ${file} (${res.bytes} bytes)`);
    for (const c of res.checks) console.log(`  ${c.ok ? '✓' : c.info ? '·' : '✗'} ${c.name}${c.ok ? '' : c.detail ? '  — ' + c.detail : ''}`);
  }
  process.exit(res.pass ? 0 : 1);
}
