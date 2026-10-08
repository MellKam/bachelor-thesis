typedef int (*__funcref fn_t)(int);
static int twice(int x) { return x * 2; }

__attribute__((export_name("apply"))) int apply(int x) {
    fn_t f = (fn_t)twice;
    return f(x);
}
