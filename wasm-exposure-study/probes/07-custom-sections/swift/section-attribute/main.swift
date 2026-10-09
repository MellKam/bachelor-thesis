@used
@section(".custom_section.meta")
let meta: (UInt8, UInt8, UInt8, UInt8, UInt8) = (0x68, 0x65, 0x6c, 0x6c, 0x6f) // "hello"

@_expose(wasm, "nop")
@_cdecl("nop")
func nop() {}
