#define E(n) __attribute__((export_name(n)))
E("i_add") int i_add(int a, int b) { return (int)((unsigned)a + (unsigned)b); }
E("i_sub") int i_sub(int a, int b) { return (int)((unsigned)a - (unsigned)b); }
E("i_mul") int i_mul(int a, int b) { return (int)((unsigned)a * (unsigned)b); }
E("i_div") int i_div(int a, int b) { return a / b; }
E("i_rem") int i_rem(int a, int b) { return a % b; }
E("i_clz") int i_clz(int a) { return __builtin_clz((unsigned)a); }
E("i_ctz") int i_ctz(int a) { return __builtin_ctz((unsigned)a); }
E("i_popcnt") int i_popcnt(int a) { return __builtin_popcount((unsigned)a); }
E("i_rotl") int i_rotl(int a, int n) { return (int)__builtin_rotateleft32((unsigned)a, (unsigned)n); }
E("i_rotr") int i_rotr(int a, int n) { return (int)__builtin_rotateright32((unsigned)a, (unsigned)n); }
