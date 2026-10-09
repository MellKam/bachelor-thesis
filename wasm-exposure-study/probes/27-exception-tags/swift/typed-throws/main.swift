// Swift errors are ordinary return values (the error register), not Wasm exceptions: the behaviour is right, no tag exists.
struct E: Error { var code: Int32 }

@inline(never) func thrower(_ x: Int32) throws(E) { throw E(code: x) }

@_expose(wasm, "roundtrip") @_cdecl("roundtrip")
func roundtrip(_ x: Int32) -> Int32 {
    do throws(E) { try thrower(x); return -1 } catch { return error.code }
}
