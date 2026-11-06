@_extern(wasm, module: "host", name: "base")
@_extern(c)
var base: Int32

nonisolated(unsafe) var counter: Int32 = 0

@_expose(wasm, "bump") @_cdecl("bump")
func bump() -> Int32 { counter = base &+ 1; return counter }
