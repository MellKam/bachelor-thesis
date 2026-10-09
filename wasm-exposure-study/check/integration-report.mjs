// Reads results/integration.json (hand coding) and results/integration/<lang>/I<n>.<variant>.json (verdicts) and writes
// results/integration/matrix.md. Checks that every coded variant has a passing verdict (support full) and lists what the verdicts say.
import { readFileSync, existsSync, writeFileSync, readdirSync } from 'node:fs';
import { LANG_KEYS, dirsOf } from './cells.mjs';

const ROUTES = ['builtin', 'official-tool', 'community-tool', 'hand-written'];
const coding = JSON.parse(readFileSync('results/integration.json', 'utf8'));
const verdict = (lang, c, v) => { const p = `results/integration/${lang}/${c}.${v}.json`; return existsSync(p) ? JSON.parse(readFileSync(p, 'utf8')) : null; };
const problems = [];
// MoonBit is one column with two verdict directories; a variant's verdicts live under the backend that built it
const dirOf = (lang, name) => (lang === 'moonbit' ? 'moonbit' : lang);
const CRITS = [['I1', 'WASI (`cat`)', 'i1-wasi'], ['I2', 'Component Model (`words`)', 'i2-component'], ['I3', 'JS host bindings (`words`)', 'i3-js-bindings'], ['I4', 'Debuggability (debug build of `life`)', 'i4-debug']];
const HEAD = { I1: ['WASI', 'Bytes', 'Binary-safe'], I2: ['WASI / kind', 'Bytes', ''], I3: ['Glue (lines)', 'Bytes', ''], I4: ['Debug info', 'Bytes', ''] };
// hand-written glue of the raw route: the code lines of integration/host/words-raw.mjs
const RAW_LINES = readFileSync('integration/host/words-raw.mjs', 'utf8').split('\n').filter((l) => l.trim() && !l.trim().startsWith('//')).length;
const sections = [];
for (const [cid, title, dir] of CRITS) {
const rows = [];
for (const lang of LANG_KEYS) {
  const cell = coding[lang]?.[cid];
  if (!cell) { problems.push(`${lang}: no ${cid} cell`); continue; }
  if (cell.absent) {
    if (!dirsOf(lang).some((d) => existsSync(`integration/${dir}/${d}/ABSENT.md`))) problems.push(`${lang}/${cid}: absent but no ABSENT.md`); rows.push(`| ${lang} | Absent (${cell.absent}) | | | | |`); continue; }
  for (const [name, r] of Object.entries(cell.variants)) {
    if (!ROUTES.includes(r.route)) problems.push(`${lang}/${name}: unknown route ${r.route}`);
    const [vc, vn] = r.verdict ? [r.verdict.split('/')[0], r.verdict.split('/')[1]] : [cid, name];
    const v = verdict(dirOf(lang, name), vc, vn);
    if (!v) { problems.push(`${lang}/${name}: no verdict`); continue; }
    if (r.support === 'full' && !v.pass) problems.push(`${lang}/${name}: coded full but the checker says ${v.build === 'failed' ? 'build failed' : 'fail'}`);
    const bin = v.checks?.find((c) => c.name.startsWith('binary-safe'))?.ok;
    const w = v.wasi ?? {};
    rows.push(`| ${lang} | ${name} | ${r.route}${r.tools ? ` (${r.tools.join(', ')})` : ''}${r.needs ? ` + ${r.needs.join(', ')}` : ''} | ${cid === 'I4' ? ['names', 'dwarf', 'sourceMap'].filter((k) => v.debug?.[k]).join(' + ') || 'none' : cid === 'I3' ? (r.route === 'hand-written' ? `${RAW_LINES} by hand` : `wrapper ${v.adapterLines}`) : `${(w.versions ?? []).join('+')} ${w.kind ?? ''}`} | ${v.bytes} | ${cid === 'I1' ? (bin ? 'yes' : 'no') : ''} |`);
  }
}
sections.push({ cid, title, rows });
}
// ---- I5 size: life and words from their own verdicts, cat from the I1 verdicts named in results/integration.json (I5.cat)
const sizeOf = (v) => (v ? { raw: v.bytes, opt: v.optBytes ?? null, best: Math.min(v.bytes, v.optBytes ?? Infinity) } : null);
const PROGRAMS = ['life', 'words', 'cat'];
const sizes = {}; // sizes[lang][program][route]
for (const lang of LANG_KEYS) {
  sizes[lang] = {};
  for (const prog of PROGRAMS) {
    sizes[lang][prog] = {};
    for (const route of ['floor', 'default']) {
      let v;
      if (prog === 'cat') { const name = coding[lang]?.I5?.cat?.[route]; v = name ? verdict(lang, 'I1', name) : null; }
      else v = verdict(lang, `I5.${prog}`, route) ?? (route === 'default' ? verdict(lang, `I5.${prog}`, 'floor') : null);
      if (v && (v.build === 'failed' || v.pass === false)) { problems.push(`${lang}/I5/${prog}/${route}: the build ${v.build === 'failed' ? 'failed' : 'does not pass the checker'}`); v = null; }
      sizes[lang][prog][route] = sizeOf(v);
    }
  }
}
// score per program and route: 1 - log10(size / smallest among languages) / 3, clamped to [0, 1]; a language's size score is the mean over its builds
const smallest = {};
for (const prog of PROGRAMS) for (const route of ['floor', 'default']) smallest[`${prog}/${route}`] = Math.min(...LANG_KEYS.map((l) => sizes[l][prog][route]?.best ?? Infinity));
const sizeScore = {};
for (const lang of LANG_KEYS) {
  const parts = [];
  for (const prog of PROGRAMS) for (const route of ['floor', 'default']) { const s = sizes[lang][prog][route]; if (s) parts.push(Math.max(0, Math.min(1, 1 - Math.log10(s.best / smallest[`${prog}/${route}`]) / 3))); }
  sizeScore[lang] = parts.length ? +(parts.reduce((a, b) => a + b, 0) / parts.length).toFixed(3) : null;
}
const fmt = (s) => (s ? (s.opt != null && s.opt < s.raw ? `${s.opt} (${s.raw})` : `${s.raw}`) : '-');
const sizeRows = LANG_KEYS.map((l) => `| ${l} | ${PROGRAMS.flatMap((p) => ['floor', 'default'].map((r) => fmt(sizes[l][p][r]))).join(' | ')} | ${sizeScore[l] ?? '-'} |`);
writeFileSync('results/integration/size.json', JSON.stringify({ basis: 'bytes after wasm-opt -Oz when that is smaller, else the raw bytes; score = mean over builds of 1 - log10(size / smallest) / 3, clamped to [0, 1]', sizes, smallest, score: sizeScore }, null, 1));
const sizeSection = ['## I5 Size', '', 'Bytes after `wasm-opt -Oz` where that is smaller (raw bytes in brackets). `floor` = the lowest-level, size-tuned route; `default` = the toolchain\'s default route, where it differs (else the floor is repeated). `cat` comes from the I1 builds named in `results/integration.json`.', '',
  '| Language | life floor | life default | words floor | words default | cat floor | cat default | Size score |', '|---|---|---|---|---|---|---|---|', ...sizeRows, '', 'The score is the mean over the builds of `1 - log10(size / smallest) / 3`, clamped to [0, 1]; 1000x the smallest build of a program is 0.', ''];
// ---- I6 toolchain cost (reported, not scored): footprint of the official toolchain, cold build of words/floor, extra tools of the best route of I1-I3
const IWJ = JSON.parse(readFileSync('results/rating/integration-weights.json', 'utf8'));
const routeRank = Object.fromEntries(IWJ.routes.map((r) => [r.kind, r.factor]));
const mb = (n) => (n == null ? '-' : n >= 1000 ? `${(n / 1000).toFixed(1)} GB` : `${n} MB`);
const i6Data = {};
const i6Rows = LANG_KEYS.map((l) => {
  const j = existsSync(`results/integration/${l}/I6.json`) ? JSON.parse(readFileSync(`results/integration/${l}/I6.json`, 'utf8')) : null;
  const tools = new Set();
  for (const c of ['I1', 'I2', 'I3']) {
    const cell = coding[l]?.[c];
    if (!cell?.variants) continue;
    const best = Object.values(cell.variants).sort((a, b) => routeRank[b.route] - routeRank[a.route] || (a.tools?.length ?? 0) - (b.tools?.length ?? 0))[0];
    for (const t of best.tools ?? []) tools.add(t);
  }
  i6Data[l] = { footprintMB: j?.footprintMB ?? null, buildSeconds: j?.buildSeconds ?? null, tools: [...tools] };
  return `| ${l} | ${mb(j?.footprintMB)} | ${j ? `${j.buildSeconds} s` : '-'} | ${tools.size ? [...tools].join(', ') : 'none'} |`;
});
writeFileSync('results/integration/i6.json', JSON.stringify({ about: 'Toolchain cost (INTEGRATION.md I6): reported, not scored.', languages: i6Data }, null, 1));
const i6Section = ['## I6 Toolchain cost (reported, not scored)', '', 'Footprint is the size of the official toolchain needed to build to Wasm: compiler, std library or sysroot or SDK, and the runtime the compiler itself needs (Node for AssemblyScript, Go for TinyGo, a JDK for Kotlin). Build time is the cold build of the `words` floor build. Extra tools are the distinct tools of the best route of each of I1-I3 (the compiler and its package manager are not counted).', '',
  '| Language | Toolchain footprint | Cold build, `words` | Extra tools for I1-I3 |', '|---|---|---|---|', ...i6Rows, ''];
const out = ['# Integration results', '', 'Generated by `check/integration-report.mjs` from `results/integration.json` and the verdicts. Do not edit.', '',
  ...sections.flatMap(({ cid, title, rows }) => [`## ${cid} ${title}`, '', `| Language | Variant | Route | ${HEAD[cid][0]} | ${HEAD[cid][1]} | ${HEAD[cid][2]} |`, '|---|---|---|---|---|---|', ...rows, '',
    ...Object.entries(coding).filter(([, c]) => c[cid]?.note).map(([l, c]) => `- **${l}**: ${c[cid].note}`), '']),
  ...sizeSection,
  ...i6Section,
  `Cross-checks against the verdicts: ${problems.length ? '\n' + problems.map((p) => `- ${p}`).join('\n') : 'None.'}`, ''].join('\n');
writeFileSync('results/integration/matrix.md', out);
console.log(out);
