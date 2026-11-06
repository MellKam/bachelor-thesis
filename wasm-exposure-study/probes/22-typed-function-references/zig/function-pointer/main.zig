fn double(x: i32) i32 {
    return x * 2;
}

var f: *const fn (i32) i32 = &double;

export fn apply(x: i32) i32 {
    const g: *const volatile *const fn (i32) i32 = &f;
    return g.*(x);
}
