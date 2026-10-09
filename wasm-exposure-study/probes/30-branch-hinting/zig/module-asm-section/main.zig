// Hand-encoded metadata.code.branch_hint (function 0, offset 8 = the br_if, size 1, value 1). wasm-ld puts custom sections after the code section,
// but the proposal allows the hint section only before it.
// Hand-encoded metadata.code.branch_hint: 1 function (index 0), 1 hint at body offset 8 (the br_if), size 1, value 1 (likely taken).
comptime {
    asm (
        \\.section .custom_section.metadata.code.branch_hint,"",@
        \\.byte 1, 0, 1, 8, 1, 1
    );
}

var sink: i32 = 0;

export fn classify(x: i32) i32 {
    if (x < 0) {
        @as(*volatile i32, &sink).* = 1; // keeps the branch from being turned into a select
        return -1;
    }
    return x * 2;
}
