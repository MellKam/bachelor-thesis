__attribute__((import_module("host"), import_name("log"))) void host_log(int x);

__attribute__((export_name("run"))) void run(void) { host_log(42); }
