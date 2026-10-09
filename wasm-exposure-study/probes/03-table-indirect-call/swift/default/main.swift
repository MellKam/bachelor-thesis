func twice(_ x: Int32) -> Int32 { x &* 2 }
func plus100(_ x: Int32) -> Int32 { x &+ 100 }

typealias Fn = @convention(c) (Int32) -> Int32

// A mutable global so the optimiser cannot see through the selection.
nonisolated(unsafe) var slots: (Fn, Fn) = ({ twice($0) }, { plus100($0) })

@_expose(wasm, "set_slot0")
@_cdecl("set_slot0")
func setSlot0() { slots.0 = { twice($0) } }

@_expose(wasm, "call_slot")
@_cdecl("call_slot")
func callSlot(_ slot: Int32, _ x: Int32) -> Int32 {
    let f = slot & 1 == 0 ? slots.0 : slots.1
    return f(x)
}
