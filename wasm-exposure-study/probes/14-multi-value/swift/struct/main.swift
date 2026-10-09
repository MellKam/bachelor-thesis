struct Pair { var q: Int32; var r: Int32 }

@_expose(wasm, "divmod")
func divmod(_ a: Int32, _ b: Int32) -> Pair { Pair(q: a / b, r: a % b) }
