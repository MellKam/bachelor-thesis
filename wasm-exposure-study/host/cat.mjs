// Shared host for the "cat" capstone: runs <module.wasm> under Wasmtime (WASI Preview 1) and checks stdout == stdin.
// Usage: node host/cat.mjs <module.wasm>
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { parseModule } from '../check/wasm.mjs';

const file = process.argv[2];
const facts = parseModule(readFileSync(file));
const report = {
  bytes: readFileSync(file).length,
  imports: facts.imports.map((i) => `${i.module}.${i.name} (${i.kind})`),
  exports: facts.exports.map((e) => `${e.name} (${e.kind})`),
  ok: false, detail: '',
};
const inputs = { text: Buffer.from('hello\nworld\n'), empty: Buffer.alloc(0), large: randomBytes(100_000) };
try {
  for (const [name, input] of Object.entries(inputs)) {
    const r = spawnSync('wasmtime', ['run', file], { input, maxBuffer: 1 << 24, timeout: 20000 });
    if (r.error) throw new Error(`${name}: ${r.error.message}`);
    if (r.status !== 0) throw new Error(`${name}: wasmtime exit ${r.status}: ${String(r.stderr).slice(0, 200).replace(/\s+/g, ' ')}`);
    if (!Buffer.from(r.stdout).equals(input)) throw new Error(`${name}: output differs (${r.stdout.length} bytes out, ${input.length} in)`);
  }
  report.ok = true; report.detail = 'stdout equals stdin for text, empty and 100000 random bytes';
} catch (e) { report.detail = String(e.message ?? e); }
console.log(JSON.stringify(report));
process.exit(report.ok ? 0 : 1);
