// A checker that rejects its own reference modules is broken: run every probes/<id>/reference*.wat through it.
import { readdirSync } from 'node:fs';
import { checkFile } from './run.mjs';
let bad = 0;
for (const dir of readdirSync('probes').sort()) {
  if (!/^\d\d-/.test(dir)) continue;
  const id = dir.slice(0, 2);
  for (const f of readdirSync(`probes/${dir}`).filter((n) => /^reference(\.[a-z]+)?\.wat$/.test(n)).sort()) {
    const variant = f.split('.').length === 3 ? f.split('.')[1] : null;   // reference.import.wat -> "import"
    const spec = variant ? `${id}:${variant}` : id;
    const res = await checkFile(spec, `probes/${dir}/${f}`);
    console.log(`${res.pass ? 'PASS' : 'FAIL'} ${spec} ${dir}`);
    for (const c of res.checks.filter((c) => !c.ok && !c.info)) console.log(`   ✗ ${c.name} — ${c.detail}`);
    if (!res.pass) bad++;
  }
}
process.exit(bad ? 1 : 0);
