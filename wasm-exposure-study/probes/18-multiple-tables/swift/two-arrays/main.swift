// Two separate arrays of function pointers: Swift (like every LLVM language) has a single implicit table for all of them.
typealias Fn = @convention(c) (Int32) -> Int32

nonisolated(unsafe) var tableA: (Fn, Fn) = ({ $0 &+ 1 }, { $0 &+ 2 })
nonisolated(unsafe) var tableB: (Fn, Fn) = ({ $0 &+ 100 }, { $0 &+ 200 })

@_expose(wasm, "set_a") @_cdecl("set_a")
func setA() { tableA.1 = { $0 &+ 3 } }

@_expose(wasm, "call_a") @_cdecl("call_a")
func callA(_ x: Int32) -> Int32 { tableA.0(x) }

@_expose(wasm, "call_b") @_cdecl("call_b")
func callB(_ x: Int32) -> Int32 { tableB.0(x) }
