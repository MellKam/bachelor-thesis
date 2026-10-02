// Usage: node check/run.mjs <probe-id[:variant]> <module.wasm|module.wat> [--json]
// Runs one probe's acceptance checks against a compiled module and prints the verdict.
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { parseModule } from './wasm.mjs';
import { PROBES } from './probes.mjs';

export const FEATURES = ['--enable-all']; // let the reference WAT use every extension; the *subject* is what is judged

export async function checkFile(spec, file) {
  const [probe, variant] = spec.split(':'); // e.g. "P2:import"
  let bytes;
  if (file.endsWith('.wat')) {
    const out = join(mkdtempSync(join(tmpdir(), 'wx-')), 'm.wasm');
    execFileSync('wat2wasm', [...FEATURES, file, '-o', out]); bytes = readFileSync(out);
  } else bytes = readFileSync(file);
  const tmp = join(mkdtempSync(join(tmpdir(), 'wx-')), 'm.wasm'); writeFileSync(tmp, bytes);
  const fn = PROBES[probe]; if (!fn) throw new Error(`unknown probe ${probe}`);
  let wat;
  try { wat = execFileSync('wasm2wat', [...FEATURES, tmp], { encoding: 'utf8', maxBuffer: 1 << 28, stdio: ['ignore', 'pipe', 'pipe'] }); }
  catch (e) { // the subject produced a module that does not validate: that is a result, not a checker crash
    const why = String(e.stderr || e.message).split('\n').find(Boolean) ?? 'invalid module';
    return { probe: spec, file, pass: false, checks: [{ name: 'module is valid WebAssembly', ok: false, detail: why.replace(/^.*?m\.wasm:/, '') }], unsupported: [] };
  }
  const facts = parseModule(bytes);
  const r = await fn({ facts, wat, bytes, variant });
  return { probe: spec, file, pass: r.pass, checks: r.checks, surface: r.surface, unsupported: facts.unsupported };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const [probe, file, flag] = process.argv.slice(2);
  const res = await checkFile(probe, file);
  if (flag === '--json') console.log(JSON.stringify(res, null, 2));
  else {
    console.log(`${res.pass ? 'PASS' : 'FAIL'} ${probe} ${file}`);
    for (const c of res.checks) console.log(`  ${c.ok ? '✓' : '✗'} ${c.name}${c.ok ? '' : c.detail ? '  — ' + c.detail : ''}`);
    if (res.surface) console.log('  surface:', JSON.stringify(res.surface));
    if (res.unsupported.length) console.log('  decoder warnings:', res.unsupported.join('; '));
  }
  process.exit(res.pass ? 0 : 1);
}
