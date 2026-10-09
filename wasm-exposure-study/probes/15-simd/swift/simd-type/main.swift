// The splatted operands go through memory so the optimiser cannot turn extract(add(splat, splat)) back into a scalar add.
nonisolated(unsafe) var sa = SIMD4<Int32>(repeating: 0)
nonisolated(unsafe) var sb = SIMD4<Int32>(repeating: 0)
nonisolated(unsafe) var sc = SIMD4<Int32>(repeating: 0)

@_expose(wasm, "simd_add") @_cdecl("simd_add")
func simdAdd(_ a: Int32, _ b: Int32) -> Int32 {
    sa = SIMD4(repeating: a)
    sb = SIMD4(repeating: b)
    let r = sa &+ sb
    sc = r
    return r[0]
}

@_expose(wasm, "simd_shuffle") @_cdecl("simd_shuffle")
func simdShuffle(_ a: Int32, _ b: Int32) -> Int32 {
    sa = SIMD4(repeating: a)
    sb = SIMD4(repeating: b)
    let r = SIMD4<Int32>(sb[0], sa[1], sb[2], sa[3])   // lanes 4,1,6,3 of the concatenation
    sc = r
    return r[0]
}
