@used
let DATA: (UInt8, UInt8, UInt8, UInt8) = (0x57, 0x41, 0x53, 0x4d) // "WASM"

@_expose(wasm, "peek")
@_cdecl("peek")
func peek(_ addr: UInt32) -> Int32 {
    Int32(UnsafePointer<UInt8>(bitPattern: UInt(addr))!.pointee)
}
