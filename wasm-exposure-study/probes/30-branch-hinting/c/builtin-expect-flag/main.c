__attribute__((export_name("classify"))) int classify(int x) {
    if (__builtin_expect(x < 0, 0)) return -1; // the rare branch
    return x * 2;
}
