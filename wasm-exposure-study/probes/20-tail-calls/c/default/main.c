__attribute__((noinline)) static int a(int n, int acc);
__attribute__((noinline)) static int b(int n, int acc) { if (n == 0) return acc;  return a(n - 1, acc + 1); }
__attribute__((noinline)) static int a(int n, int acc) { if (n == 0) return acc;  return b(n - 1, acc + 1); }
__attribute__((export_name("count"))) int count(int n, int acc) { return a(n, acc); }
