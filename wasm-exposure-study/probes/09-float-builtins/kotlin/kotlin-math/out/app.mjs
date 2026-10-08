
import { WASI } from 'wasi';
import { argv, env } from 'node:process';

const wasi = new WASI({ version: 'preview1', args: argv, env, });

const fs = await import('node:fs');
const url = await import('node:url');
const wasmBuffer = fs.readFileSync(url.fileURLToPath(import.meta.resolve('./app.wasm')));
const wasmModule = new WebAssembly.Module(wasmBuffer);
const wasmInstance = new WebAssembly.Instance(wasmModule, wasi.getImportObject());

wasi.start(wasmInstance);

const exports = wasmInstance.exports

export {
    exports as __ALL_EXPORTS,

}

const wasmMemory = exports.memory;
export { wasmMemory as memory }

export const {
    f_sqrt,
    f_min,
    f_max,
    f_ceil,
    f_floor,
    f_trunc,
    f_nearest,
    f_copysign,
    f_abs,
    _start
} = exports

