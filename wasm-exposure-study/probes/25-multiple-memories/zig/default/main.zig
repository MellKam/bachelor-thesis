// The builtins take a memory index, so a second memory is nameable in source.
export fn copy_test() i32 {
    return @intCast(@wasmMemorySize(1));
}
