// Thin wrapper over the module em++ --bind generated: embind converts the JS string to std::string and the Stats struct to a JS object.
export const load = async () => {
  const Module = (await import('./out.mjs')).default;
  const m = await Module();
  return (text) => m.analyse(text);
};
