extern "C" __attribute__((export_name("roundtrip"))) int roundtrip(int x) {
    try { throw x; } catch (int e) { return e; }
    return -1;
}
