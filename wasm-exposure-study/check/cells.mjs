// Loads results/coding.json, the one hand-authored file behind both the matrix and the rating, validates it against the evidence
// (probe directories, ABSENT.md files, the checker's verdicts) and derives from it everything the two reports need.
//
// A cell (results/coding.json[lang][feature]) is one of
//   { variants: { <name>: record }, flags?: [text], note?: text }   a feature the language can produce, by one or more variants
//   { absent: "confirmed" | "not found", rests_on?: [probe], flags?, note? }   it cannot (rests_on: the probes that failed)
//   { pending: true }                                                a feature specified but not probed yet
// A record describes one probe variant with categories only, no numbers:
//   expressed_as  native | annotation | config | inline_asm   how the feature is written (the result vocabulary of the chapter plan);
//                 inline_asm = assembly or Wasm text written by hand (Rust global_asm!, Zig asm, C __asm__, MoonBit extern "wasm")
//   checked       true | false, only for inline_asm: whether the language's own compiler relates the block to the surrounding program
//                 (typed operands, a signature checked against the body). Default: native and annotation are checked, config and
//                 inline_asm are not. It changes the Checked count and the figures, never the score, which already prices in inline_asm.
//   support       full | partial (then `missing` says what is not produced)
//   needs         what else the developer has to accept, from a closed list (NEEDS below); each kind counts once
//   probes        probe directories the record rests on, when it is more than the variant's own name
// An obstacle is `expressed_as` being config or inline_asm (the feature is reached outside the source, or by hand-written assembly,
// whether or not the compiler checks it) plus one for every entry of `needs`. Nothing is multiplied or averaged: the rating counts cells (see rating.mjs).
// `flags` holds only what the categories cannot say (opt-in compiler flags, "implicit table", ...). The cell's result and the
// phrases for `partial` and `needs` are derived, never written twice.
//
// results/coding.json also has a top-level `caveats`: { lang: [text] }, facts about every probe of a language (what the host must do)
// that would be wrong to charge to any single feature. They are printed in both reports and count for nothing.
import { readFileSync, existsSync } from 'node:fs';
import { FEATURES } from './feature-list.mjs';

export const LANG_KEYS = ['rust', 'zig', 'c', 'moonbit', 'assemblyscript', 'tinygo', 'kotlin', 'swift'];
// A language column can have several probe/verdict directories, one per backend that is a different target (MoonBit: `wasm` in
// `moonbit/`, `wasm-gc` in `moonbit-gc/`). A probe is named `<name>` (first directory) or `<directory>/<name>`.
export const LANG_DIRS = { moonbit: ['moonbit', 'moonbit-gc'] };
export const dirsOf = (lang) => LANG_DIRS[lang] ?? [lang];
export const probeRef = (lang, text) => { const i = text.indexOf('/'); return i < 0 ? { dir: dirsOf(lang)[0], name: text } : { dir: text.slice(0, i), name: text.slice(i + 1) }; };
export const probeText = (lang, { dir, name }) => (dir === dirsOf(lang)[0] ? name : `${dir}/${name}`);

// The closed list of things a developer may have to accept besides the way the feature is expressed.
export const NEEDS = {
  'nightly-compiler': 'a nightly, unsupported compiler for the whole project',
  'experimental-api': 'an API, flag or target feature marked experimental or unstable, on a supported compiler',
  'side-effect': 'the mechanism is an implementation detail of another construct: no construct of the language asks for it (a closure call, a class hierarchy, panic unwinding)',
  'extra-runtime': 'a runtime or library shipped in every module',
  'restricted-host': 'a module that only runs on certain hosts (it imports WASI functions or JS glue)',
  'other-backend': 'the other backend of the same language (a module uses one backend)',
};
const ENUMS = { expressed_as: ['native', 'annotation', 'config', 'inline_asm'], support: ['full', 'partial'] };
const RECORD_FIELDS = ['expressed_as', 'support', 'missing', 'needs', 'probes', 'checked'];
const CELL_FIELDS = ['variants', 'absent', 'rests_on', 'pending', 'flags', 'note'];
const MODIFIERS = ['confirmed', 'not found'];

export const verdictOf = (lang, id, probe) => {
  const p = `results/${lang}/${id}.${probe}.json`;
  if (!existsSync(p)) return null;
  const v = JSON.parse(readFileSync(p, 'utf8'));
  return v.build === 'failed' ? 'build failed' : v.hang ? 'hang' : v.pass ? 'pass' : 'fail';
};

// Checked = the language's compiler checks it. Not the same as having no obstacle: a checked inline_asm block is still hand-written assembly.
export const isChecked = (r) => r.checked ?? (r.expressed_as === 'native' || r.expressed_as === 'annotation');
export const obstacles = (r) => (r.expressed_as === 'config' || r.expressed_as === 'inline_asm' ? 1 : 0) + (r.needs?.length ?? 0);
// Which variant stands for a cell: the most complete first, then the one the compiler checks, then the one with the fewest obstacles.
const rank = (r) => [r.support === 'full' ? 1 : 0, isChecked(r) ? 1 : 0, -obstacles(r)];
const better = (a, b) => { const x = rank(a), y = rank(b); for (let i = 0; i < x.length; i++) if (x[i] !== y[i]) return x[i] > y[i]; return false; };

// Phrases that follow from a record's categories, in reading order. `name` is the variant's name (it carries the backend).
const phrases = (name, r) => [
  ...(r.support === 'partial' ? [`partial: ${r.missing}`] : []),
  ...(r.needs ?? []).map((n) => ({
    'nightly-compiler': 'needs a nightly compiler',
    'experimental-api': 'needs an experimental API',
    'extra-runtime': 'ships an extra runtime',
    'restricted-host': 'needs a specific host (WASI or JS)',
    'other-backend': `only on the ${/^(wasm(?:-gc)?):/.exec(name)?.[1] ?? 'other'} backend (a module uses one backend)`,
    'side-effect': 'a side effect, not requested',
  })[n]),
];

export const cap = (s) => s[0].toUpperCase() + s.slice(1);
const EXPRESSION = { native: 'Native', annotation: 'Annotation', config: 'Config', inline_asm: 'Inline asm' };
export const expressionLabel = (r) => EXPRESSION[r.expressed_as] + (r.expressed_as === 'inline_asm' && isChecked(r) ? ', checked' : '');
export const cellFlags = (c) => (c.pending ? [] : [...(c.derived ?? []), ...(c.flags ?? [])]);
export const cellLabel = (c) => {
  if (c.pending) return 'Not yet probed';
  const head = c.absent ? `Absent (${c.modifier})` : expressionLabel(c.selected.record);
  const fl = cellFlags(c);
  return fl.length ? `${head}, ${fl.join(', ')}` : head;
};

// Returns { cells, problems, warnings, caveats }; cells[lang][id] has `pending`, or `absent`, or `selected` + `all`.
export function loadCells() {
  const coding = JSON.parse(readFileSync('results/coding.json', 'utf8'));
  const problems = [], warnings = [], cells = {};
  const caveats = coding.caveats ?? {};
  for (const [lang, list] of Object.entries(caveats)) {
    if (!LANG_KEYS.includes(lang)) problems.push(`caveats: unknown language "${lang}"`);
    if (!Array.isArray(list) || list.some((t) => typeof t !== 'string')) problems.push(`caveats.${lang}: must be a list of texts`);
  }
  for (const lang of LANG_KEYS) {
    cells[lang] = {};
    for (const { id, slug } of FEATURES) {
      const raw = coding[lang]?.[id], where = `${lang}/${id}`;
      if (!raw) { problems.push(`${where}: no cell in coding.json`); continue; }
      for (const k of Object.keys(raw)) if (!CELL_FIELDS.includes(k)) problems.push(`${where}: unknown field "${k}"`);
      const base = { flags: raw.flags ?? [], note: raw.note };
      if (raw.pending) { cells[lang][id] = { pending: true }; continue; }
      if (raw.absent !== undefined) {
        if (!MODIFIERS.includes(raw.absent)) problems.push(`${where}: absent must be one of ${MODIFIERS.join(' | ')}`);
        if (raw.variants) problems.push(`${where}: an absent cell has no variants (list the failed probes under rests_on)`);
        const restsOn = (raw.rests_on ?? []).map((t) => probeRef(lang, t));
        for (const r of restsOn) if (!dirsOf(lang).includes(r.dir) || !existsSync(`probes/${id}-${slug}/${r.dir}/${r.name}`)) problems.push(`${where}: probe "${probeText(lang, r)}" has no directory`);
        const absentFiles = dirsOf(lang).map((d) => `probes/${id}-${slug}/${d}/ABSENT.md`).filter((f) => existsSync(f));
        if (!restsOn.length && !absentFiles.length) problems.push(`${where}: no probe and no ABSENT.md`);
        cells[lang][id] = { absent: true, modifier: raw.absent, restsOn, absentFiles, noProbe: !restsOn.length, derived: [], ...base };
        continue;
      }
      if (!raw.variants || !Object.keys(raw.variants).length) { problems.push(`${where}: a cell needs "variants", "absent" or "pending"`); continue; }
      if (raw.rests_on) problems.push(`${where}: rests_on only goes with an absent cell`);
      const all = [];
      for (const [name, r] of Object.entries(raw.variants)) {
        for (const k of Object.keys(r)) if (!RECORD_FIELDS.includes(k)) problems.push(`${where}/${name}: unknown field "${k}"`);
        for (const [k, allowed] of Object.entries(ENUMS)) if (!allowed.includes(r[k])) problems.push(`${where}/${name}: ${k} must be one of ${allowed.join(' | ')}`);
        for (const n of r.needs ?? []) if (!(n in NEEDS)) problems.push(`${where}/${name}: needs "${n}" is not one of ${Object.keys(NEEDS).join(' | ')}`);
        if (new Set(r.needs ?? []).size !== (r.needs ?? []).length) problems.push(`${where}/${name}: needs lists a kind twice`);
        if (r.needs?.includes('other-backend') && !/^wasm(-gc)?:/.test(name)) problems.push(`${where}/${name}: other-backend is for variants named after their backend (wasm:… or wasm-gc:…)`);
        if (r.checked !== undefined && (typeof r.checked !== 'boolean' || r.expressed_as !== 'inline_asm')) problems.push(`${where}/${name}: checked is true or false and only goes with inline_asm (native and annotation are always checked, config never)`);
        if (r.support === 'partial' && !r.missing) problems.push(`${where}/${name}: partial support needs a "missing" text`);
        if (r.support === 'full' && r.missing) problems.push(`${where}/${name}: "missing" only goes with partial support`);
        const probes = (r.probes ?? [name]).map((t) => probeRef(lang, t));
        const verdicts = probes.map((p) => verdictOf(p.dir, id, p.name));
        probes.forEach((p, i) => {
          if (!dirsOf(lang).includes(p.dir) || !existsSync(`probes/${id}-${slug}/${p.dir}/${p.name}`)) problems.push(`${where}/${name}: probe "${probeText(lang, p)}" has no directory`);
          else if (verdicts[i] === null) problems.push(`${where}/${name}: probe "${probeText(lang, p)}" has no verdict`);
        });
        if (r.support === 'full' && !r.needs?.includes('side-effect') && verdicts.some((v) => v && v !== 'pass'))
          warnings.push(`${where}/${name}: support is full but the checker says ${verdicts.join(', ')}`);
        if (r.support === 'partial' && verdicts.every((v) => v === 'pass'))
          warnings.push(`${where}/${name}: support is partial but every probe passes the checker`);
        all.push({ name, record: r, probes, verdicts, obstacles: obstacles(r) });
      }
      let selected = all[0];
      for (const v of all.slice(1)) if (better(v.record, selected.record)) selected = v;
      cells[lang][id] = { absent: false, selected, all, derived: phrases(selected.name, selected.record), ...base };
    }
  }
  for (const lang of Object.keys(coding)) if (lang !== 'caveats' && !LANG_KEYS.includes(lang)) problems.push(`coding.json: unknown language "${lang}"`);
  return { cells, problems, warnings, caveats };
}
