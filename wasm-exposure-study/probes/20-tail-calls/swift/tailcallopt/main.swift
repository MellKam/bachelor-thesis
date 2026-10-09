// As plain-tail-call, plus LLVM's -tailcallopt (guaranteed tail calls for calling conventions that allow them).
// Swift has no tail-call guarantee. The calls are in tail position and the target has the tail-call feature on.
@inline(never) func ping(_ n: UInt32, _ acc: UInt32) -> UInt32 { n == 0 ? acc : pong(n &- 1, acc &+ 1) }
@inline(never) func pong(_ n: UInt32, _ acc: UInt32) -> UInt32 { n == 0 ? acc : ping(n &- 1, acc &+ 1) }

@_expose(wasm, "count") @_cdecl("count")
func count(_ n: UInt32, _ acc: UInt32) -> UInt32 { ping(n, acc) }
