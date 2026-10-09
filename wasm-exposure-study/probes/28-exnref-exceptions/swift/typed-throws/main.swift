// Re-throwing a caught error is an ordinary `throw` again; nothing becomes try_table / throw_ref.
struct E: Error { var code: Int32 }

@inline(never) func thrower(_ x: Int32) throws(E) { throw E(code: x) }

@inline(never) func middle(_ x: Int32) throws(E) {
    do throws(E) { try thrower(x) } catch { throw error }
}

@_expose(wasm, "rethrow_test") @_cdecl("rethrow_test")
func rethrowTest(_ x: Int32) -> Int32 {
    do throws(E) { try middle(x); return -1 } catch { return error.code }
}
