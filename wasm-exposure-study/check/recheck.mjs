// Usage: node check/recheck.mjs [lang ...]
// Re-runs the checker on the binaries already built (probes/<NN>-*/<lang>/<variant>/out.wasm), rewrites results/<lang>/<id>.<variant>.json
// and replaces the verdict part of the matching .txt log (the build log above it is kept). Used after the checker itself changed:
// it never rebuilds anything.
import { readdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { checkFile } from './run.mjs';

const args = process.argv.slice(2);
const langs = args.length ? args : readdirSync('results', { withFileTypes: true }).filter((d) => d.isDirectory() && d.name !== 'capstones').map((d) => d.name);
const dirOf = (id) => readdirSync('probes').find((d) => d.startsWith(id + '-'));
let changed = 0, total = 0;
for (const lang of langs) {
  for (const f of readdirSync(`results/${lang}`).filter((n) => n.endsWith('.json')).sort()) {
    const [id, ...rest] = f.slice(0, -5).split('.'); const variant = rest.join('.');
    const old = JSON.parse(readFileSync(`results/${lang}/${f}`, 'utf8'));
    if (old.build === 'failed' || old.hang) continue;   // a build failure or a hang was decided at run time, not by re-reading the module
    const dir = `probes/${dirOf(id)}/${lang}/${variant}`; const wasm = `${dir}/out.wasm`;
    if (!existsSync(wasm)) { console.log(`skip (no binary) ${lang} ${id} ${variant}`); continue; }
    const specFile = `${dir}/spec`; const spec = existsSync(specFile) ? readFileSync(specFile, 'utf8').trim() : id;
    let res; try { res = await checkFile(spec, wasm); } catch (e) { console.log(`checker error ${lang} ${id} ${variant}: ${e.message}`); continue; }
    total++;
    if (!!old.pass !== !!res.pass) { changed++; console.log(`CHANGED ${lang} ${id} ${variant}: ${old.pass ? 'PASS' : 'FAIL'} -> ${res.pass ? 'PASS' : 'FAIL'}`); }
    writeFileSync(`results/${lang}/${f}`, JSON.stringify(res, null, 2) + '\n');
    const txtPath = `results/${lang}/${f.slice(0, -5)}.txt`; const txt = readFileSync(txtPath, 'utf8').split('\n');
    const cut = txt.findIndex((l) => /^(PASS|FAIL) \d\d/.test(l));
    const head = (cut === -1 ? txt : txt.slice(0, cut)).join('\n').replace(/\n+$/, '\n');
    const out = [`${res.pass ? 'PASS' : 'FAIL'} ${spec} ${wasm} (${res.bytes} bytes)`];
    for (const c of res.checks) out.push(`  ${c.ok ? '✓' : c.info ? '·' : '✗'} ${c.name}${c.ok ? '' : c.detail ? '  — ' + c.detail : ''}`);
    writeFileSync(txtPath, head + out.join('\n') + '\n');
  }
}
console.log(`rechecked ${total} binaries, ${changed} verdicts changed`);
