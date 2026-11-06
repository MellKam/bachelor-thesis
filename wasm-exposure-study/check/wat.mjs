// Reads a module's instructions as text via `wasm-tools print` (WABT cannot read Wasm GC) and answers one question:
// "is this instruction emitted by (or reachable from) this exported function?". Instruction questions are never answered
// from source code, only from the compiled module.
import { execFileSync } from 'node:child_process';

export function printWat(file) {
  return execFileSync('wasm-tools', ['print', file], { encoding: 'utf8', maxBuffer: 1 << 28, stdio: ['ignore', 'pipe', 'pipe'] });
}

export function validate(file) { // `--features all` so a module is never rejected for using a recent extension
  try { execFileSync('wasm-tools', ['validate', '--features', 'all', file], { stdio: ['ignore', 'pipe', 'pipe'] }); return { ok: true }; }
  catch (e) { return { ok: false, why: String(e.stderr || e.message).trim().split('\n')[0] }; }
}

export function analyse(wat) {
  // function bodies: "(func $name (;N;) (type ..) ..." up to the next top-level item
  const funcs = new Map(), byName = new Map(), lines = wat.split('\n'); let cur = null;
  for (const line of lines) {
    const h = /^  \(func (?:(\$(?:"[^"]*"|[^\s)]+)) )?(?:\(@name "[^"]*"\) )?\(;(\d+);\)/.exec(line);
    if (h) { cur = { index: Number(h[2]), name: h[1] ?? null, body: [] }; funcs.set(cur.index, cur); if (cur.name) byName.set(cur.name, cur.index); }
    else if (/^  \(/.test(line) || /^\)/.test(line)) cur = null;
    if (cur) cur.body.push(line);
  }
  const exportsF = new Map();
  for (const m of wat.matchAll(/\(export "([^"]*)" \(func (\$(?:"[^"]*"|[^\s)]+)|\d+)\)\)/g)) exportsF.set(m[1], m[2].startsWith('$') ? byName.get(m[2]) : Number(m[2]));
  const textOf = (f) => f.body.join('\n');
  const callsOf = (f) => [...textOf(f).matchAll(/\b(?:return_)?call (\$(?:"[^"]*"|[^\s)]+)|\d+)/g)].map((c) => (c[1].startsWith('$') ? byName.get(c[1]) : Number(c[1])));
  // text of an exported function plus every function it calls directly or transitively
  const reach = (exportName) => {
    const start = exportsF.get(exportName); if (start === undefined || !funcs.has(start)) return null;
    const seen = new Set(), stack = [start], out = [];
    while (stack.length) { const i = stack.pop(); if (seen.has(i) || !funcs.has(i)) continue; seen.add(i); const f = funcs.get(i); out.push(textOf(f)); stack.push(...callsOf(f)); }
    return out.join('\n');
  };
  return { funcs, exportsF, reach, whole: wat };
}
