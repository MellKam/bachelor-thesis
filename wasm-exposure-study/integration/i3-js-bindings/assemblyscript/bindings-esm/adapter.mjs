// Thin wrapper over the ESM bindings `asc --bindings esm` wrote; the record comes back as a lifted object.
export const load = async () => {
  const m = await import('./out.js');
  return (text) => { const r = m.analyse(text); return { words: r.words, bytes: r.bytes, longest: r.longest }; };
};
