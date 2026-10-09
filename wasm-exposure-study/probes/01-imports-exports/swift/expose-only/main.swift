// Same as `default` without @_cdecl / @_extern(c): the functions use Swift's own calling convention, which adds
// two hidden parameters (context, error) to every signature.
@_extern(wasm, module: "host", name: "log")
func hostLog(_ x: Int32)

@_expose(wasm, "run")
func run() { hostLog(42) }
