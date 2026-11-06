// Usage: node check/summarise.mjs [lang ...] [--json]
// Condenses results/<lang>/<id>.<variant>.json (the checker's verdicts) into one line per variant:
// the verdict, the module size, and the names of the checks that failed. Informational checks are never listed as failures.
import { readdirSync, readFileSync, existsSync } from 'node:fs';

const args = process.argv.slice(2);
const asJson = args.includes('--json');
const langs = args.filter((a) => !a.startsWith('--'));
const all = readdirSync('results', { withFileTypes: true }).filter((d) => d.isDirectory() && !['capstones'].includes(d.name)).map((d) => d.name).sort();
const rows = [];
for (const lang of langs.length ? langs : all) {
  if (!existsSync(`results/${lang}`)) continue;
  for (const f of readdirSync(`results/${lang}`).filter((n) => n.endsWith('.json')).sort()) {
    const [id, ...rest] = f.slice(0, -5).split('.'); const variant = rest.join('.');
    let v; try { v = JSON.parse(readFileSync(`results/${lang}/${f}`, 'utf8')); } catch { v = { build: 'unreadable' }; }
    const failed = (v.checks ?? []).filter((c) => !c.ok && !c.info).map((c) => c.name + (c.detail ? ` [${String(c.detail).slice(0, 70)}]` : ''));
    rows.push({ lang, id, variant, build: v.build ?? 'ok', pass: !!v.pass, hang: !!v.hang, bytes: v.bytes ?? null, failed, members: v.members });
  }
}
if (asJson) console.log(JSON.stringify(rows, null, 1));
else for (const r of rows) {
  const verdict = r.build === 'failed' ? 'BUILD-FAILED' : r.hang ? 'HANG' : r.pass ? 'PASS' : 'FAIL';
  console.log(`${r.lang.padEnd(15)} ${r.id} ${r.variant.padEnd(26)} ${verdict.padEnd(12)} ${r.bytes ?? ''}${r.failed.length ? '\n    ✗ ' + r.failed.join('\n    ✗ ') : ''}`);
}
