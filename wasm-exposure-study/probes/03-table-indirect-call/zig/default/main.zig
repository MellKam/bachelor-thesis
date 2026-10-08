fn double(x: i32) i32 {
    return x * 2;
}

fn plus100(x: i32) i32 {
    return x + 100;
}

var slots = [_]*const fn (i32) i32{ &double, &plus100 };

export fn call_slot(slot: i32, x: i32) i32 {
    return slots[@as(usize, @intCast(slot)) & 1](x);
}
