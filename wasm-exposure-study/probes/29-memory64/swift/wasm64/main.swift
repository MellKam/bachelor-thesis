@_expose(wasm, "touch") @_cdecl("touch")
func touch() -> Int32 {
    let p = UnsafeMutablePointer<Int32>(bitPattern: 16)!
    p.pointee = 42
    return p.pointee
}
