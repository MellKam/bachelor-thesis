// A function value is an index into the implicit table and is called with call_indirect; Swift has no typed reference.
typealias Fn = @convention(c) (Int32) -> Int32

nonisolated(unsafe) var f: Fn = { $0 &* 2 }

@_expose(wasm, "set_f") @_cdecl("set_f")
func setF() { f = { $0 &* 2 } }

@_expose(wasm, "apply") @_cdecl("apply")
func apply(_ x: Int32) -> Int32 { f(x) }
