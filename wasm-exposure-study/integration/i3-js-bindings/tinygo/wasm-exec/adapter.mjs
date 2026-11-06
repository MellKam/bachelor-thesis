// TinyGo's own wasm_exec.js starts the Go program, which registers `analyse` on globalThis; strings and the result object are converted by syscall/js.
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

export const load = async () => {
  await import('./wasm_exec.js');
  const go = new globalThis.Go();
  const { instance } = await WebAssembly.instantiate(readFileSync(join(dirname(fileURLToPath(import.meta.url)), 'out.wasm')), go.importObject);
  go.run(instance);
  return (text) => globalThis.analyse(text);
};
