// Thin wrapper over the glue wasm-bindgen generated (--target nodejs): nothing is marshalled by hand.
import { createRequire } from 'node:module';

const m = createRequire(import.meta.url)('./pkg/words.js');
export const load = async () => (text) => { const r = m.analyse(text); return { words: r.words, bytes: r.bytes, longest: r.longest }; };
