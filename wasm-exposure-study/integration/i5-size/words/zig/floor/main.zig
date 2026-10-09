// `words`, floor ABI: export memory, alloc(len) -> ptr, analyse(ptr, len) -> ptr to { words, bytes, longest_ptr, longest_len }.
var heap: [1 << 20]u8 align(8) = undefined;
var top: usize = 0;
var record: [4]u32 = undefined;

export fn alloc(len: usize) [*]u8 {
    const p: [*]u8 = @ptrCast(&heap[top]);
    top += (len + 7) & ~@as(usize, 7);
    return p;
}

fn isWs(c: u8) bool {
    return c == ' ' or c == '\t' or c == '\n' or c == '\r';
}

export fn analyse(ptr: [*]const u8, len: usize) *[4]u32 {
    var words: u32 = 0;
    var best: usize = 0;
    var best_at: usize = 0;
    var i: usize = 0;
    while (i < len) {
        while (i < len and isWs(ptr[i])) i += 1;
        const start = i;
        while (i < len and !isWs(ptr[i])) i += 1;
        if (i > start) {
            words += 1;
            if (i - start > best) {
                best = i - start;
                best_at = start;
            }
        }
    }
    top = 0;
    record = .{ words, @intCast(len), @intCast(@intFromPtr(ptr) + best_at), @intCast(best) };
    return &record;
}
