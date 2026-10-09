// Thin wrapper over the ES module Kotlin/Wasm generates for the wasm-js target; String and the exported class cross without hand-written code.
export const load = async () => {
  const m = await import('./out/app.mjs');
  return (text) => { const r = m.analyse(text); return { words: r.words, bytes: r.bytes, longest: r.longest }; };
};
