// The canonical ABI written by hand: Zig has no component support. The core module exports `memory`, `cabi_realloc` and the lowered
// form of `analyse` under the name the component model expects; `wasm-tools component embed` + `component new` wrap it.
var heap: [1 << 20]u8 align(8) = undefined; // a bump allocator is enough: the host calls cabi_realloc once per call
var heap_top: usize = 0;
var record: [4]u32 = undefined; // stats: words, bytes, longest.ptr, longest.len

fn cabiRealloc(old_ptr: ?[*]u8, old_size: usize, alignment: usize, new_size: usize) callconv(.c) ?[*]u8 {
    _ = old_ptr;
    _ = old_size;
    const start = (heap_top + alignment - 1) & ~(alignment - 1);
    if (start + new_size > heap.len) return null;
    heap_top = start + new_size;
    return @ptrCast(&heap[start]);
}

fn isWs(c: u8) bool {
    return c == ' ' or c == '\t' or c == '\n' or c == '\r';
}

fn analyse(ptr: [*]const u8, len: usize) callconv(.c) *[4]u32 {
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
    record = .{ words, @intCast(len), @intCast(@intFromPtr(ptr) + best_at), @intCast(best) };
    heap_top = 0;
    return &record;
}

comptime {
    @export(&cabiRealloc, .{ .name = "cabi_realloc" });
    @export(&analyse, .{ .name = "study:words/words@0.1.0#analyse" });
}
