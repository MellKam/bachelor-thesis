// Usage: node check/rating.mjs
// Renders results/rating/rating.md from results/coding.json, the same hand-authored file the matrix uses (loaded and checked by
// cells.mjs). It counts and compares; it never multiplies, weights or averages. For every cell it asks the same questions: is the
// feature reached, fully, does the compiler check it, and how many obstacles stand in the way (cells.mjs: config or assembly is one,
// every entry of `needs` is one). The report is the tally of those answers per language, per spec version and per feature, and a
// list of which language is ahead of which: A is ahead of B only if A is at least as good on every count and better on one.
// On top of the counts there is one number per language between 0 and 1, from the coefficients in results/rating/weights.json: a cell's
// score is reach x the product of the factors of its obstacles, a language's score the weighted mean over the probed features.
// Absent (confirmed) counts 0 in that mean, like a demonstrated limitation; Absent (not found) is left out of the mean entirely, like
// a pending cell, because "no way was found" is not the same claim as "no way exists" and must not be scored as if it were.
// The coefficients are data, and the report re-ranks the languages with all of them perturbed, so only robust orderings are claimed.
// The same numbers are written to results/rating/rating.json for charts.
import { readFileSync, writeFileSync } from 'node:fs';
import { FEATURES as FEATURE_LIST } from './feature-list.mjs';
import { loadCells, isChecked, obstacles, NEEDS } from './cells.mjs';

const FEATURES = FEATURE_LIST.map((f) => [f.id, f.name]);
const SINCE = Object.fromEntries(FEATURE_LIST.map((f) => [f.id, f.since]));
const VERSIONS = ['1.0', '2.0', '3.0'];
const LANGS = [['rust', 'Rust'], ['zig', 'Zig'], ['c', 'C/C++'], ['moonbit', 'MoonBit'], ['assemblyscript', 'AssemblyScript'], ['tinygo', 'TinyGo'], ['kotlin', 'Kotlin/Wasm']];
// The counts a language is compared on. "none" = reached with no obstacle at all.
const COUNTS = [['reached', 'Reached'], ['full', 'Full'], ['checked', 'Checked'], ['none', 'No obstacle']];

const { cells, problems, warnings, caveats } = loadCells();
if (problems.length) { console.error(problems.join('\n')); process.exit(1); }

const tally = (l, keep = () => true) => {
  const t = { n: 0, reached: 0, full: 0, checked: 0, none: 0, one: 0, more: 0, confirmed: 0, notFound: 0, unprobed: 0 };
  for (const [id] of FEATURES) {
    const c = cells[l][id]; if (c.pending || !keep(id)) continue;
    t.n++;
    if (c.absent) { if (c.modifier === 'confirmed') t.confirmed++; else t.notFound++; if (c.noProbe) t.unprobed++; continue; }
    const r = c.selected.record, o = obstacles(r);
    t.reached++; if (r.support === 'full') t.full++; if (isChecked(r)) t.checked++;
    if (o === 0) t.none++; else if (o === 1) t.one++; else t.more++;
  }
  return t;
};
const T = Object.fromEntries(LANGS.map(([l]) => [l, tally(l)]));
const PROBED = Math.max(...LANGS.map(([l]) => T[l].n));

// ---- the weighted score
const W = JSON.parse(readFileSync('results/rating/weights.json', 'utf8'));
for (const [id] of FEATURES) if (typeof W.features[id] !== 'number') { console.error(`weights.json: no weight for feature ${id}`); process.exit(1); }
const KINDS = ['config', 'opaque', ...Object.keys(NEEDS)];
const listed = W.obstacles.map((o) => o.kind);
for (const k of KINDS) if (listed.filter((x) => x === k).length !== 1) { console.error(`weights.json: obstacle "${k}" must be listed exactly once`); process.exit(1); }
for (const k of listed) if (!KINDS.includes(k)) { console.error(`weights.json: unknown obstacle "${k}"`); process.exit(1); }
W.obstacles.forEach((o, i) => { if (!(o.factor > 0 && o.factor <= 1) || (i && o.factor > W.obstacles[i - 1].factor)) { console.error(`weights.json: the factor of "${o.kind}" must be in (0, 1] and no larger than the one before it (the list runs from least to most damaging)`); process.exit(1); } });
const FACTORS = Object.fromEntries(W.obstacles.map((o) => [o.kind, o.factor]));
const kindsOf = (r) => [...(r.expressed_as === 'config' || r.expressed_as === 'opaque' ? [r.expressed_as] : []), ...(r.needs ?? [])];
// p = { reach: {full, partial}, factors: {kind: f}, weights: {id: w} }
const notFound = (c) => c.absent && c.modifier === 'not found';
const cellScore = (c, p) => (c.absent || c.pending ? 0 : p.reach[c.selected.record.support] * kindsOf(c.selected.record).reduce((a, k) => a * p.factors[k], 1));
const langScore = (l, p) => { let num = 0, den = 0; for (const [id] of FEATURES) { const c = cells[l][id]; if (c.pending || notFound(c)) continue; num += p.weights[id] * cellScore(c, p); den += p.weights[id]; } return num / den; };
const BASE = { reach: W.reach, factors: FACTORS, weights: W.features };
const SCORE = Object.fromEntries(LANGS.map(([l]) => [l, langScore(l, BASE)]));
// Sensitivity: every coefficient moves at random, and the languages are ranked again each time. Seeded, so the file is reproducible.
const DRAWS = 2000;
const rng = ((seed) => () => { seed = (seed + 0x6d2b79f5) | 0; let t = Math.imul(seed ^ (seed >>> 15), 1 | seed); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; })(7);
const clip = (x, lo, hi) => Math.min(hi, Math.max(lo, x));
const wins = Object.fromEntries(LANGS.map(([a]) => [a, Object.fromEntries(LANGS.map(([b]) => [b, 0]))]));
const ranks = Object.fromEntries(LANGS.map(([l]) => [l, []]));
for (let d = 0; d < DRAWS; d++) {
  const p = { reach: { full: 1, partial: clip(W.reach.partial + (rng() - 0.5) * 0.4, 0.2, 0.8) },
    factors: (() => { // the damage of every obstacle scales by one common amount plus a little noise each; the order of the list is kept
      const g = 0.5 + rng(), sev = W.obstacles.map((o) => clip((1 - o.factor) * g * (0.85 + 0.3 * rng()), 0.02, 0.9)).sort((a, b) => a - b);
      return Object.fromEntries(W.obstacles.map((o, i) => [o.kind, 1 - sev[i]])); })(),
    weights: Object.fromEntries(Object.entries(W.features).map(([id, w]) => [id, w * (0.5 + 1.5 * rng())])) };
  const s = Object.fromEntries(LANGS.map(([l]) => [l, langScore(l, p)]));
  for (const [a] of LANGS) { ranks[a].push(1 + LANGS.filter(([b]) => s[b] > s[a] + 1e-12).length); for (const [b] of LANGS) if (s[a] > s[b] + 1e-12) wins[a][b]++; }
}

const out = [];
out.push('# Language rating (generated)', '',
  'Generated by `node check/rating.mjs` from `results/coding.json`. The definitions are in `results/rating/README.md`.',
  (PROBED === FEATURES.length ? `All ${FEATURES.length} features are probed.` : `${PROBED} of ${FEATURES.length} features are probed; the rest are listed as not yet probed and are left out of every count.`)
    + ' Nothing here is a score: each number is a count of cells, and every cell is judged by the same questions.', '',
  '## Summary', '',
  '| Language | Reached | Full | Checked | No obstacle | 1 obstacle | 2+ obstacles | Absent (confirmed) | Absent (not found) | of which never probed |', '|---|---|---|---|---|---|---|---|---|---|');
const order = [...LANGS].sort(([a], [b]) => T[b].reached - T[a].reached || T[b].none - T[a].none || T[b].full - T[a].full);
for (const [l, n] of order) { const t = T[l]; out.push(`| ${n} | ${t.reached}/${t.n} | ${t.full} | ${t.checked} | ${t.none} | ${t.one} | ${t.more} | ${t.confirmed} | ${t.notFound} | ${t.unprobed} |`); }
out.push('', '**Reached**: the language can produce the feature in some way. **Full**: all of it, not part. **Checked**: the compiler type-checks it (native or annotation). **No obstacle / 1 / 2+**: among the reached features, how many obstacles stand between the developer and it. An obstacle is reaching it through a build config or through assembly, or any of:', '',
  ...Object.entries(NEEDS).map(([k, v]) => `- \`${k}\`: ${v}`), '',
  'Sorted by reached, then by no obstacle. The "not found" column is the uncertainty: those cells could still be reached if a way exists. The sort order is only a layout; the comparison is below.', '');

const byScore = [...LANGS].sort(([a], [b]) => SCORE[b] - SCORE[a]);
out.push('## Score', '', 'One number between 0 and 1 per language, from the coefficients in `results/rating/weights.json` (a draft, set by the author). A cell scores its reach (full 1, partial 0.5) times the factor of each of its obstacles; a language scores the weighted mean of its cells over the features, where each feature has an importance weight. Absent (confirmed) counts 0 in that mean; Absent (not found) is left out of the mean entirely, like a pending cell, since no way was found but none was shown to not exist. The counts above are the evidence; this is their summary.', '',
  `| Language | Score | Rank in ${DRAWS} perturbed runs (best–worst) |`, '|---|---|---|');
for (const [l, n] of byScore) out.push(`| ${n} | ${SCORE[l].toFixed(2)} | ${Math.min(...ranks[l])}–${Math.max(...ranks[l])} |`);
const robust = [];
for (const [a, an] of byScore) for (const [b, bn] of byScore) if (a !== b && SCORE[a] > SCORE[b] && wins[a][b] / DRAWS >= 0.95) robust.push(`${an} above ${bn} (${Math.round(100 * wins[a][b] / DRAWS)}%)`);
const fragile = [];
for (let i = 0; i < byScore.length; i++) for (let j = i + 1; j < byScore.length; j++) { const [a, an] = byScore[i], [b, bn] = byScore[j]; const pa = wins[a][b] / DRAWS; if (pa < 0.95) fragile.push(`${an} / ${bn} (${Math.round(100 * pa)}% / ${Math.round(100 * (1 - pa - (DRAWS - wins[a][b] - wins[b][a]) / DRAWS))}%)`); }
out.push('', `The ranks come from changing every coefficient at random (partial reach ±0.2; the damage of all obstacles together between half and one and a half times, plus ±15% each, in the same order; each feature weight between half and double) ${DRAWS} times. An order is robust only if it held in at least 95% of the runs.`, '',
  `**Robust orderings:** ${robust.length ? robust.join('; ') : 'none'}.`, '', `**Not robust** (the score gap is smaller than the uncertainty of the coefficients): ${fragile.length ? fragile.join('; ') : 'none'}.`, '',
  '**Obstacle factors**, from least to most damaging. A cell is worth its reach times the factor of each obstacle it has.', '', '| Obstacle | Factor | Why it ranks here |', '|---|---|---|', ...W.obstacles.map((o) => `| ${o.kind}${o.kind in NEEDS ? '' : ' (expressed_as)'} | ${o.factor.toFixed(2)} | ${o.why} |`), '',
  `Reach: full ${W.reach.full}, partial ${W.reach.partial}. Feature weights (1–3): ${FEATURES.map(([id]) => `${id}=${W.features[id]}`).join(', ')}.`, '');

const caveatLines = LANGS.filter(([l]) => caveats[l]?.length).flatMap(([l, n]) => caveats[l].map((t) => `- **${n}**: ${t}`));
if (caveatLines.length) out.push('## Language caveats', '', 'True of every probe of the language. They are recorded here and count for nothing, because charging them to each feature would count one obligation thirty times.', '', ...caveatLines, '');

// Pairwise comparison: A is ahead of B if it is at least as good on every count and better on at least one.
const ahead = (a, b) => COUNTS.every(([k]) => T[a][k] >= T[b][k]) && COUNTS.some(([k]) => T[a][k] > T[b][k]);
out.push('## Which language is ahead of which', '', `A language is ahead of another only if it is at least as good on all ${COUNTS.length} counts (${COUNTS.map(([, n]) => n.toLowerCase()).join(', ')}) and better on at least one.`, '');
for (const [a, an] of order) { const behind = LANGS.filter(([b]) => b !== a && ahead(a, b)).map(([, n]) => n); if (behind.length) out.push(`- **${an}** is ahead of ${behind.join(', ')}.`); }
const unordered = [];
for (let i = 0; i < LANGS.length; i++) for (let j = i + 1; j < LANGS.length; j++) { const [a, an] = LANGS[i], [b, bn] = LANGS[j]; if (!ahead(a, b) && !ahead(b, a)) unordered.push(`${an} / ${bn}`); }
out.push('', unordered.length ? `Not ordered, because each leads on something: ${unordered.join('; ')}.` : 'Every pair is ordered.', '');

out.push('## By spec version', '', 'The same counts for the features of each spec version (1.0 = module core, 2.0, 3.0 = most recently standardised): reached of the features probed, and how many of the reached ones have no obstacle.', '',
  '| Language | ' + VERSIONS.join(' | ') + ' |', '|---|' + VERSIONS.map(() => '---').join('|') + '|');
for (const [l, n] of LANGS) out.push(`| ${n} | ${VERSIONS.map((v) => { const t = tally(l, (id) => SINCE[id] === v); return t.n ? `${t.reached}/${t.n} reached, ${t.none} with none` : '–'; }).join(' | ')} |`);
out.push('');

out.push('## Per feature', '', 'Each cell: `F` full or `P` partial, `✓` checked or `✗` not checked, then the number of obstacles; `–` Absent.', '',
  '| # | Feature | Spec | ' + LANGS.map(([, n]) => n).join(' | ') + ' |', '|---|---|---|' + LANGS.map(() => '---').join('|') + '|');
const code = (c) => (c.pending ? '?' : c.absent ? '–' : `${c.selected.record.support === 'full' ? 'F' : 'P'}${isChecked(c.selected.record) ? '✓' : '✗'}${obstacles(c.selected.record)}`);
for (const [id, fname] of FEATURES) out.push(`| ${id} | ${fname} | ${SINCE[id]} | ${LANGS.map(([l]) => code(cells[l][id])).join(' | ')} |`);
out.push('');

out.push('## Selected variant per cell', '', 'The variant that stands for the cell: the most complete first, then the one the compiler checks, then the one with the fewest obstacles. Other variants are listed with their obstacle count.', '');
for (const [l, n] of LANGS) {
  out.push(`### ${n}`, '');
  for (const [id, fname] of FEATURES) {
    const c = cells[l][id];
    if (c.pending) { out.push(`- **${id} ${fname}**: not yet probed.`); continue; }
    if (c.absent) { out.push(`- **${id} ${fname}**: Absent (${c.modifier})${c.noProbe ? `, never probed; see ${c.absentFiles.map((f) => `[\`${f}\`](../../${f})`).join(', ')}` : ''}.`); continue; }
    const r = c.selected.record;
    const bits = [r.expressed_as, r.support === 'partial' ? `partial (${r.missing})` : null, ...(r.needs ?? [])].filter(Boolean);
    const others = c.all.filter((v) => v !== c.selected).map((v) => `\`${v.name}\` (${v.record.expressed_as}${v.record.support === 'partial' ? ', partial' : ''}, ${v.obstacles} obstacles)`);
    out.push(`- **${id} ${fname}**: \`${c.selected.name}\`, ${bits.join(', ')}; ${c.selected.obstacles} obstacles.` + (others.length ? ` Also: ${others.join(', ')}.` : '') + (c.note ? ` ${c.note}` : ''));
  }
  out.push('');
}

out.push('## Cross-checks against the verdicts', '');
out.push(...(warnings.length ? warnings.map((w) => `- ${w}`) : ['None.']), '');
writeFileSync('results/rating/rating.md', out.join('\n'));

// ---- rating.json: the same numbers as data, for charts. Tidy: one object per language, one per cell, plus the definitions and coefficients.
const r4 = (x) => (x === null || x === undefined ? null : Math.round(x * 10000) / 10000);
const metrics = (c) => {
  if (c.pending) return { status: 'pending', support: null, checked: null, directness: null, score: null, obstacles: [] };
  if (c.absent) return { status: 'absent', absent: c.modifier, neverProbed: c.noProbe, support: 0, checked: null, directness: null, score: 0, obstacles: [] };
  const r = c.selected.record, kinds = kindsOf(r), support = W.reach[r.support], directness = kinds.reduce((a, k) => a * FACTORS[k], 1);
  return { status: 'reached', variant: c.selected.name, expressedAs: r.expressed_as, partial: r.support === 'partial' ? r.missing : null, support, checked: isChecked(r) ? 1 : 0, directness, score: support * directness, obstacles: kinds };
};
const M = Object.fromEntries(LANGS.map(([l]) => [l, Object.fromEntries(FEATURES.map(([id]) => [id, metrics(cells[l][id])]))]));
// The four numbers of a language over a set of features. support and score average over every probed feature where the reach is
// known (Absent confirmed counts 0; Absent not found is excluded, same as pending, since no way was found but none was shown to
// not exist); checked and directness average over the reached features only, so they say how good what the language reaches is.
const aggregate = (l, keep = () => true) => {
  let wAll = 0, wReached = 0, sup = 0, chk = 0, dir = 0, sc = 0, n = 0, reached = 0;
  for (const [id] of FEATURES) { const m = M[l][id]; if (m.status === 'pending' || (m.status === 'absent' && m.absent === 'not found') || !keep(id)) continue; const w = W.features[id]; n++; wAll += w; sup += w * m.support; sc += w * m.score; if (m.status === 'reached') { reached++; wReached += w; chk += w * m.checked; dir += w * m.directness; } }
  return { features: n, reached, support: r4(wAll ? sup / wAll : null), checked: r4(wReached ? chk / wReached : null), directness: r4(wReached ? dir / wReached : null), score: r4(wAll ? sc / wAll : null) };
};
const json = {
  about: 'Generated by check/rating.mjs from results/coding.json and results/rating/weights.json. All numbers are between 0 and 1. Do not edit by hand.',
  criteria: {
    support: { description: 'How much of the feature set the language can produce: reach of a feature is full 1, partial 0.5, Absent (confirmed) 0. Weighted mean over every probed feature except Absent (not found), which is excluded rather than scored, since no way was found but none was shown to not exist.', scope: 'all features except Absent (not found)' },
    checked: { description: 'How much of what the language reaches is type-checked by the compiler (native or annotation = 1, config or assembly = 0). Weighted mean over the reached features.', scope: 'reached features' },
    directness: { description: 'How few obstacles stand between the developer and what the language reaches: the product of the obstacle factors of the cell (1 = none). Weighted mean over the reached features.', scope: 'reached features' },
    score: { description: 'The single summary: per feature, support times directness; weighted mean over every probed feature except Absent (not found), for the same reason as support. Checked is reported next to it, not multiplied in, because config and assembly already lower directness.', scope: 'all features except Absent (not found)' },
  },
  coefficients: { reach: W.reach, obstacles: W.obstacles.map((o) => ({ kind: o.kind, factor: o.factor, why: o.why })), featureWeights: W.features },
  features: FEATURE_LIST.map((f) => ({ id: f.id, name: f.name, since: f.since, weight: W.features[f.id] })),
  languages: LANGS.map(([l, n]) => ({
    id: l, name: n, ...aggregate(l),
    scoreRank: { best: Math.min(...ranks[l]), worst: Math.max(...ranks[l]), mean: r4(ranks[l].reduce((a, b) => a + b, 0) / ranks[l].length) },
    counts: { probed: T[l].n, reached: T[l].reached, full: T[l].full, checked: T[l].checked, noObstacle: T[l].none, oneObstacle: T[l].one, twoOrMoreObstacles: T[l].more, absentConfirmed: T[l].confirmed, absentNotFound: T[l].notFound, neverProbed: T[l].unprobed },
    bySpecVersion: Object.fromEntries(VERSIONS.map((v) => [v, aggregate(l, (id) => SINCE[id] === v)])),
  })),
  cells: LANGS.flatMap(([l, n]) => FEATURES.map(([id, fname]) => { const m = M[l][id]; return { language: l, feature: id, featureName: fname, since: SINCE[id], weight: W.features[id], ...m, support: r4(m.support), checked: r4(m.checked), directness: r4(m.directness), score: r4(m.score) }; })),
  comparison: {
    perturbation: { draws: DRAWS, description: 'Every coefficient is moved at random and the languages are ranked again; share is the fraction of runs in which the first language scored above the second.' },
    pairs: byScore.flatMap(([a], i) => byScore.slice(i + 1).map(([b]) => ({ higher: a, lower: b, share: r4(wins[a][b] / DRAWS), robust: wins[a][b] / DRAWS >= 0.95 }))),
    ahead: LANGS.flatMap(([a]) => LANGS.filter(([b]) => b !== a && ahead(a, b)).map(([b]) => ({ ahead: a, behind: b }))),
  },
};
writeFileSync('results/rating/rating.json', JSON.stringify(json, null, 2) + '\n');
if (warnings.length) console.error(warnings.join('\n'));
console.log('results/rating/rating.md and rating.json written');
