// Usage: node check/run.mjs <feature-id[:variant]> <module.wasm|module.wat> [--json]
// Runs one feature's acceptance checks against a compiled module and prints (or emits as JSON) the verdict.
import { readFileSync, mkdtempSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { parseModule } from './wasm.mjs';
import { analyse, printWat, validate } from './wat.mjs';
import { FEATURES } from './features.mjs';

export async function checkFile(spec, file, extra = {}) {
  const [feature, variant] = spec.split(':'); // e.g. "02:import"
  let path = file;
  if (file.endsWith('.wat')) { path = join(mkdtempSync(join(tmpdir(), 'wx-')), 'm.wasm'); execFileSync('wasm-tools', ['parse', file, '-o', path]); }
  const bytes = readFileSync(path);
  const fn = FEATURES[feature]; if (!fn) throw new Error(`unknown feature ${feature}`);
  const v = validate(path);
  let wat;
  try { wat = printWat(path); }
  catch (e) { return { feature: spec, file, bytes: bytes.length, pass: false, checks: [{ name: 'module can be read', ok: false, detail: String(e.stderr || e.message).split('\n')[0] }], unsupported: [] }; }
  const facts = parseModule(bytes);
  const r = await fn({ facts, wat: analyse(wat), bytes, variant, ...extra });
  const checks = [{ name: 'module validates (all extensions enabled)', ok: v.ok, detail: v.why ?? '', info: true }, ...r.checks];
  return { feature: spec, file, bytes: bytes.length, pass: r.pass, checks, ...(r.members && { members: r.members }), unsupported: facts.unsupported };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const [spec, file, flag] = process.argv.slice(2);
  const res = await checkFile(spec, file);
  if (flag === '--json') console.log(JSON.stringify(res, null, 2));
  else {
    console.log(`${res.pass ? 'PASS' : 'FAIL'} ${spec} ${file} (${res.bytes} bytes)`);
    for (const c of res.checks) console.log(`  ${c.ok ? '✓' : c.info ? '·' : '✗'} ${c.name}${c.ok ? '' : c.detail ? '  — ' + c.detail : ''}`);
    if (res.unsupported.length) console.log('  decoder warnings:', res.unsupported.join('; '));
  }
  process.exit(res.pass ? 0 : 1);
}
