// llvm.wasm.throw reached through the Builtin module. The compiler crashes (signal 11) while looking the intrinsic up.
import Builtin

@_expose(wasm, "roundtrip") @_cdecl("roundtrip")
func roundtrip(_ x: Int32) -> Int32 {
    Builtin.int_wasm_throw(Int32(0)._value, UnsafeMutableRawPointer(bitPattern: 16)!._rawValue)
    return x
}
