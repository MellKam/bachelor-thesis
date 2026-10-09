/* `life` capstone contract: import host.random() -> i32; export memory, init, step, cells_ptr, width, height. */
#define EXPORT(n) __attribute__((export_name(n)))
#define W 64
#define H 64
#define N (W * H)
__attribute__((import_module("host"), import_name("random"))) extern int host_random(void);

static unsigned char buf[2 * N];
static int cur;

EXPORT("init") void init_grid(void) {
  for (int i = 0; i < N; i++) buf[i] = host_random() & 1;
  cur = 0;
}

EXPORT("step") void step(void) {
  unsigned char *c = buf + cur * N, *nx = buf + (1 - cur) * N;
  for (int y = 0; y < H; y++)
    for (int x = 0; x < W; x++) {
      int n = 0;
      for (int dy = 0; dy < 3; dy++)
        for (int dx = 0; dx < 3; dx++)
          if (!(dy == 1 && dx == 1)) n += c[((y + H - 1 + dy) % H) * W + (x + W - 1 + dx) % W];
      nx[y * W + x] = (n == 3 || (c[y * W + x] && n == 2));
    }
  cur = 1 - cur;
}

EXPORT("cells_ptr") int cells_ptr(void) { return (int)(buf + cur * N); }
EXPORT("width") int width(void) { return W; }
EXPORT("height") int height(void) { return H; }

EXPORT("crash_here") void crash_here(void) { __builtin_trap(); }
