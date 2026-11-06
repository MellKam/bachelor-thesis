extern "host" fn random() i32;

const W = 64;
const H = 64;
const N = W * H;

var buf: [2 * N]u8 = undefined;
var cur: usize = 0;

export fn init() void {
    var i: usize = 0;
    while (i < N) : (i += 1) buf[i] = @intCast(random() & 1);
    cur = 0;
}

export fn step() void {
    const offs = [_]usize{ H - 1, 0, 1 };
    const offx = [_]usize{ W - 1, 0, 1 };
    const c = cur * N;
    const nx = (1 - cur) * N;
    var y: usize = 0;
    while (y < H) : (y += 1) {
        var x: usize = 0;
        while (x < W) : (x += 1) {
            var n: u8 = 0;
            for (offs) |dy| {
                for (offx) |dx| {
                    if (dy == 0 and dx == 0) continue;
                    n += buf[c + ((y + dy) % H) * W + (x + dx) % W];
                }
            }
            const alive = buf[c + y * W + x] != 0;
            buf[nx + y * W + x] = if (n == 3 or (alive and n == 2)) 1 else 0;
        }
    }
    cur = 1 - cur;
}

export fn cells_ptr() i32 {
    return @intCast(@intFromPtr(&buf[cur * N]));
}

export fn width() i32 {
    return W;
}

export fn height() i32 {
    return H;
}
