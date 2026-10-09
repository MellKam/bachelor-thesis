// The linker (not the program) makes the data segment passive under --shared-memory and copies it from its own initialiser.
@used
nonisolated(unsafe) var DATA: (UInt8, UInt8, UInt8, UInt8) = (0x57, 0x41, 0x53, 0x4d) // "WASM"

@_expose(wasm, "load") @_cdecl("load")
func load(_ dst: UInt32) {
    let src = withUnsafePointer(to: &DATA) { UnsafeRawPointer($0) }
    UnsafeMutableRawPointer(bitPattern: UInt(dst))!.copyMemory(from: src, byteCount: 4)
}

@_expose(wasm, "peek") @_cdecl("peek")
func peek(_ addr: UInt32) -> Int32 { Int32(UnsafePointer<UInt8>(bitPattern: UInt(addr))!.pointee) }
