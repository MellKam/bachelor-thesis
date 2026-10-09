nonisolated(unsafe) var g: Int32 = 0

// an entry in .init_array is what wasm-ld turns into __wasm_call_ctors
@used
@section(".init_array")
let ctor: @convention(c) () -> Void = { g = 7 }

@_expose(wasm, "get")
@_cdecl("get")
func get() -> Int32 { g }
