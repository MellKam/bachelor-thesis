@external("host", "random")
declare function random(): i32;

const W: i32 = 64;
const H: i32 = 64;
const N: i32 = W * H;

const BUF = memory.data(2 * N);
let cur: i32 = 0;

export function init(): void {
  for (let i = 0; i < N; i++) store<u8>(BUF + i, <u8>(random() & 1));
  cur = 0;
}

export function step(): void {
  const c = BUF + cur * N;
  const nx = BUF + (1 - cur) * N;
  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      let n: i32 = 0;
      for (let dy = 0; dy < 3; dy++) {
        for (let dx = 0; dx < 3; dx++) {
          if (dy == 1 && dx == 1) continue;
          n += load<u8>(c + ((y + H - 1 + dy) % H) * W + (x + W - 1 + dx) % W);
        }
      }
      const alive = load<u8>(c + y * W + x) != 0;
      store<u8>(nx + y * W + x, <u8>(n == 3 || (alive && n == 2) ? 1 : 0));
    }
  }
  cur = 1 - cur;
}

export function cells_ptr(): i32 {
  return <i32>(BUF + cur * N);
}

export function width(): i32 {
  return W;
}

export function height(): i32 {
  return H;
}

export function crash_here(): void {
  unreachable();
}
