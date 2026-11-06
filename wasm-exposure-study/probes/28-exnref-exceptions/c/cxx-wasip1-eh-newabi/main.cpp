extern "C" __attribute__((export_name("rethrow_test"))) int rethrow_test(int x) {
    try {
        try { throw x; }
        catch (int) { throw; } // throw the caught exception again
    } catch (int e) { return e; }
    return -1;
}
