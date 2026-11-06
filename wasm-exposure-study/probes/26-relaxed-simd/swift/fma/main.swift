// addingProduct is Swift's fused multiply-add. It lowers to llvm.fma, which becomes a call to fmaf (not available freestanding),
// never to a relaxed madd.
@_expose(wasm, "relaxed_madd") @_cdecl("relaxed_madd")
func relaxedMadd(_ a: Float, _ b: Float, _ c: Float) -> Float {
    let r = SIMD4<Float>(repeating: c).addingProduct(SIMD4<Float>(repeating: a), SIMD4<Float>(repeating: b))
    return r[0]
}
