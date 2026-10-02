// A checker that rejects its own reference modules is broken: run every probes/<id>/reference.wat through it.
import { readdirSync } from 'node:fs';
import { checkFile } from './run.mjs';
let bad = 0;
for (const id of readdirSync('probes').sort()) {
  for (const f of readdirSync(`probes/${id}`).filter((n) => /^reference(\.[a-z]+)?\.wat$/.test(n)).sort()) {
    const variant = f.split('.').length === 3 ? f.split('.')[1] : null;   // reference.import.wat -> "import"
    const spec = variant ? `${id}:${variant}` : id;
    const res = await checkFile(spec, `probes/${id}/${f}`);
    console.log(`${res.pass ? 'PASS' : 'FAIL'} ${spec}`);
    for (const c of res.checks.filter((c) => !c.ok)) console.log(`   ✗ ${c.name} — ${c.detail}`);
    if (!res.pass) bad++;
  }
}
process.exit(bad ? 1 : 0);
