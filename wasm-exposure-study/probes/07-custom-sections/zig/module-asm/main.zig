// Module-level assembly writes the custom section: the `.custom_section.` prefix is honoured by the assembler and wasm-ld, unlike `linksection`.
comptime {
    asm (
        \\.section .custom_section.meta,"",@
        \\.ascii "hello"
    );
}

export fn nop() void {}
