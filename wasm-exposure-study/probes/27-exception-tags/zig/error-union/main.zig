const E = error{Boom};

fn mayFail(x: i32) E!i32 {
    if (x >= 0) return error.Boom;
    return x;
}

export fn roundtrip(x: i32) i32 {
    return mayFail(x) catch x;
}
