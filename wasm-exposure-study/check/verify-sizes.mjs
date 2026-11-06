import { readFileSync, existsSync, statSync, mkdtempSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
const size = JSON.parse(readFileSync('results/integration/size.json'));
const cfg = JSON.parse(readFileSync('results/integration.json'));
const rd = (p) => (existsSync(p) ? JSON.parse(readFileSync(p)) : null);
const opt = (f) => { const o = join(mkdtempSync(join(tmpdir(), 'v-')), 'o.wasm'); try { execFileSync(process.env.WASM_OPT, ['-Oz', '--all-features', '--strip-debug', '--strip-producers', f, '-o', o], { stdio: 'ignore' }); return statSync(o).size; } catch { return null; } };
let bad = 0, n = 0;
for (const [l, progs] of Object.entries(size.sizes)) for (const [p, builds] of Object.entries(progs)) {
  const fb = builds.floor; n++;
  const v = p === 'cat' ? cfg[l].I5.cat.floor : null;
  const jf = p === 'cat' ? `results/integration/${l}/I1.${v}.json` : `results/integration/${l}/I5.${p}.floor.json`;
  const j = rd(jf); const file = j?.file?.replace(/\/\/out/, '/out');
  const actual = file && existsSync(file) ? statSync(file).size : null;
  const re = file && existsSync(file) ? opt(file) : null;
  const best = Math.min(fb.raw, fb.opt ?? Infinity);
  const flags = [];
  if (!j) flags.push('no verdict');
  else { if (j.bytes !== fb.raw) flags.push(`verdict bytes ${j.bytes}`); if ((j.optBytes ?? null) !== (fb.opt ?? null)) flags.push(`verdict opt ${j.optBytes}`); if (!j.pass) flags.push('verdict FAIL'); }
  if (actual !== null && actual !== fb.raw) flags.push(`file now ${actual}`);
  if (re !== null && re !== fb.opt) flags.push(`rerun opt ${re}`);
  if (best !== fb.best) flags.push(`best ${fb.best} != ${best}`);
  if (flags.length) bad++;
  console.log(l.padEnd(15), p.padEnd(6), String(fb.raw).padStart(8), String(fb.opt).padStart(8), String(fb.best).padStart(8), flags.join('; ') || 'ok');
}
console.log(`${n} cells, ${bad} with differences`);
