// The Builtin module exposes LLVM's intrinsics by name (llvm.wasm.relaxed.madd.v4f32 -> int_wasm_relaxed_madd_Vec4xFPIEEE32).
import Builtin

@_expose(wasm, "relaxed_madd") @_cdecl("relaxed_madd")
func relaxedMadd(_ a: Float, _ b: Float, _ c: Float) -> Float {
    let va = SIMD4<Float>(repeating: a), vb = SIMD4<Float>(repeating: b), vc = SIMD4<Float>(repeating: c)
    let r = Builtin.int_wasm_relaxed_madd_Vec4xFPIEEE32(
        unsafeBitCast(va, to: Builtin.Vec4xFPIEEE32.self),
        unsafeBitCast(vb, to: Builtin.Vec4xFPIEEE32.self),
        unsafeBitCast(vc, to: Builtin.Vec4xFPIEEE32.self))
    return unsafeBitCast(r, to: SIMD4<Float>.self)[0]
}
