// Thin wrapper over the bundle the PackageToJS plugin generated (Node platform); the Swift side registers `analyse` on globalThis.
import { instantiate } from './Bundle/instantiate.js';
import { defaultNodeSetup } from './Bundle/platforms/node.js';

export const load = async () => {
  await instantiate(await defaultNodeSetup({}));
  return (text) => { const r = globalThis.analyse(text); return { words: r.words, bytes: r.bytes, longest: r.longest }; };
};
