// Thin wrapper over the module `jco transpile` generated from the component; the string and record cross the boundary without hand-written code.
export const load = async () => {
  const { words } = await import('./pkg/words.js');
  return (text) => words.analyse(text);
};
