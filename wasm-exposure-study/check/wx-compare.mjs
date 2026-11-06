// Usage: node check/wx-compare.mjs   Prints a size table (raw bytes / bytes after wasm-opt -Oz) of WX against the other languages,
// from the verdicts in results/integration/<lang>/. A language's cat build is the I1 variant named in results/integration.json (I5.cat).
import { readFileSync, existsSync } from 'node:fs';
const read = (p) => (existsSync(p) ? JSON.parse(readFileSync(p, 'utf8')) : null);
const cfg = read('results/integration.json');
const langs = ['rust', 'zig', 'c', 'moonbit', 'assemblyscript', 'tinygo', 'kotlin', 'swift', 'wx'];
const cell = (j) => (j ? `${j.bytes} / ${j.optBytes ?? '-'}` : '-');
console.log('| language | cat floor | cat default | life floor | life default | words floor | words default |');
console.log('|---|---|---|---|---|---|---|');
for (const l of langs) {
  const d = `results/integration/${l}`;
  const cat = cfg[l]?.I5?.cat;
  const row = [
    cat && read(`${d}/I1.${cat.floor}.json`), cat && read(`${d}/I1.${cat.default}.json`),
    read(`${d}/I5.life.floor.json`), read(`${d}/I5.life.default.json`), read(`${d}/I5.words.floor.json`), read(`${d}/I5.words.default.json`),
  ].map(cell);
  console.log(`| ${l} | ${row.join(' | ')} |`);
}
