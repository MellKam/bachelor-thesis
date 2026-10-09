// @_extern(wasm, module:, name:) declares the import; it needs @_extern(c) next to it to get the C calling convention.
@_extern(wasm, module: "host", name: "log")
@_extern(c)
func hostLog(_ x: Int32)

@_expose(wasm, "run")
@_cdecl("run")
func run() { hostLog(42) }
