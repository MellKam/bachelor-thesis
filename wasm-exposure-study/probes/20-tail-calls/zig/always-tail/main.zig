noinline fn a(n: i32, acc: i32) i32 {
    if (n == 0) return acc;
    return @call(.always_tail, b, .{ n - 1, acc + 1 });
}
noinline fn b(n: i32, acc: i32) i32 {
    if (n == 0) return acc;
    return @call(.always_tail, a, .{ n - 1, acc + 1 });
}
export fn count(n: i32, acc: i32) i32 { return a(n, acc); }
