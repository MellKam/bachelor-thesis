// Module-level assembly declares the tag (`.tagtype`) and the legacy try/catch (needs +exception_handling).
comptime {
    asm (
        \\.tagtype payload_tag i32
        \\payload_tag:
        \\
        \\.section .text.roundtrip,"",@
        \\.globl roundtrip
        \\.export_name roundtrip, roundtrip
        \\roundtrip:
        \\  .functype roundtrip (i32) -> (i32)
        \\  try i32
        \\    local.get 0
        \\    throw payload_tag
        \\  catch payload_tag
        \\  end_try
        \\  end_function
    );
}
