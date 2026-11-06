// A global with a constant initialiser: no code runs, the value is placed in the data segment.
nonisolated(unsafe) var g: Int32 = 7

@_expose(wasm, "get")
@_cdecl("get")
func get() -> Int32 { g }
