const std = @import("std");
const wasi = std.os.wasi;

pub fn main() void {
    var buf: [4096]u8 = undefined;
    while (true) {
        var iov = [_]wasi.iovec_t{.{ .base = &buf, .len = buf.len }};
        var n: usize = 0;
        if (wasi.fd_read(0, &iov, 1, &n) != .SUCCESS or n == 0) return;
        var out = [_]wasi.ciovec_t{.{ .base = &buf, .len = n }};
        var w: usize = 0;
        if (wasi.fd_write(1, &out, 1, &w) != .SUCCESS) return;
    }
}
