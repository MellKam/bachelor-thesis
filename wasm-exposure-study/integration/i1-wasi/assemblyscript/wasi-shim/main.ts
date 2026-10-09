// The official WASI shim of the AssemblyScript organisation: process.stdin / process.stdout over WASI imports.
const buf = new ArrayBuffer(4096);
while (true) {
  const n = process.stdin.read(buf);
  if (n <= 0) break;
  process.stdout.write(buf.slice(0, n));
}
