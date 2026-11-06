const Pair = extern struct { q: u32, r: u32 };

export fn divmod(a: u32, b: u32) Pair {
    return .{ .q = a / b, .r = a % b };
}
