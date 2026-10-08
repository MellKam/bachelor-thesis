extern "host" fn log(x: i32) void;

export fn run() void {
    log(42);
}
