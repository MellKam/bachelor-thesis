// Shared host for the "life" capstone. Identical for every language: no generated glue, no per-language adaptation.
// Usage: node host/life.mjs <module.wasm>
// Contract: import host.random() -> i32; exports memory, init(), step(), cells_ptr() -> i32, width() -> i32, height() -> i32.
import { readFileSync } from 'node:fs';
import { parseModule } from '../check/wasm.mjs';
import { makeImports } from '../check/probes.mjs';

const bytes = readFileSync(process.argv[2]);
const facts = parseModule(bytes);
const W = 64, H = 64, N = W * H, STEPS = 100;

let s = 12345;
const rnd = () => { s = (Math.imul(s, 1103515245) + 12345) & 0x7fffffff; return s >>> 8; };

// Reference implementation (torus), driven by the same random sequence the module sees.
let ref = new Uint8Array(N); { let r = 12345; const rr = () => { r = (Math.imul(r, 1103515245) + 12345) & 0x7fffffff; return r >>> 8; }; for (let i = 0; i < N; i++) ref[i] = rr() & 1; }
const refStep = () => { const nx = new Uint8Array(N); for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) { let n = 0; for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) if (dy || dx) n += ref[((y + dy + H) % H) * W + ((x + dx + W) % W)]; nx[y * W + x] = (n === 3 || (ref[y * W + x] && n === 2)) ? 1 : 0; } ref = nx; };

const wanted = new Set(['memory', 'init', 'step', 'cells_ptr', 'width', 'height']);
const report = {
  bytes: bytes.length,
  extraImports: facts.imports.filter((i) => !(i.module === 'host' && i.name === 'random')).map((i) => `${i.module}.${i.name} (${i.kind})`),
  extraExports: facts.exports.filter((e) => !wanted.has(e.name)).map((e) => `${e.name} (${e.kind})`),
  calledStart: false, ok: false, detail: '',
};
try {
  const { instance } = await WebAssembly.instantiate(bytes, makeImports(facts, { host: { random: rnd } }));
  const x = instance.exports;
  if (x._start) { x._start(); report.calledStart = true; } // host had to run the language's own entry point first
  if (x.width() !== W || x.height() !== H) throw new Error(`size ${x.width()}x${x.height()}`);
  x.init(); for (let i = 0; i < STEPS; i++) { x.step(); refStep(); }
  const got = new Uint8Array(x.memory.buffer, x.cells_ptr(), N);
  let diff = 0; for (let i = 0; i < N; i++) if ((got[i] ? 1 : 0) !== ref[i]) diff++;
  report.alive = ref.reduce((a, b) => a + b, 0); report.ok = diff === 0; report.detail = diff ? `${diff} of ${N} cells differ after ${STEPS} steps` : `matches reference after ${STEPS} steps`;
} catch (e) { report.detail = String(e.message ?? e); }
console.log(JSON.stringify(report));
process.exit(report.ok ? 0 : 1);
