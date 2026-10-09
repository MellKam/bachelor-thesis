// @_expose(wasm) is accepted on global functions only; a variable cannot be exported by name.
@_expose(wasm, "counter")
nonisolated(unsafe) var counter: Int32 = 0

@_expose(wasm, "bump") @_cdecl("bump")
func bump() -> Int32 { counter &+= 1; return counter }
