// A tuple is not representable in C, so this uses Swift's own calling convention (no @_cdecl).
@_expose(wasm, "divmod")
func divmod(_ a: Int32, _ b: Int32) -> (Int32, Int32) { (a / b, a % b) }
