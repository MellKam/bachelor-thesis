// Vectors come from and go to linear memory, so the optimiser cannot fold them into scalar code.
func ptr(_ p: UInt32) -> UnsafeMutableRawPointer { UnsafeMutableRawPointer(bitPattern: UInt(p))! }

@_expose(wasm, "v_copy") @_cdecl("v_copy")
func vCopy(_ p: UInt32) -> Int32 {
    let q = ptr(p)
    q.storeBytes(of: q.loadUnaligned(as: SIMD16<UInt8>.self), toByteOffset: 16, as: SIMD16<UInt8>.self)
    return Int32(q.load(fromByteOffset: 16, as: UInt8.self))
}

@_expose(wasm, "v_select") @_cdecl("v_select")
func vSelect(_ p: UInt32) -> Int32 {
    let q = ptr(p)
    let a = q.loadUnaligned(as: SIMD4<UInt32>.self)
    let b = q.loadUnaligned(fromByteOffset: 16, as: SIMD4<UInt32>.self)
    let m = q.loadUnaligned(fromByteOffset: 32, as: SIMD4<UInt32>.self)
    let r = (a & m) | (b & ~m)
    q.storeBytes(of: r, toByteOffset: 48, as: SIMD4<UInt32>.self)
    return Int32(bitPattern: r[0])
}

@_expose(wasm, "v_narrow") @_cdecl("v_narrow")
func vNarrow(_ p: UInt32) -> Int32 {
    let q = ptr(p)
    let a = q.loadUnaligned(as: SIMD8<Int16>.self)
    let b = q.loadUnaligned(fromByteOffset: 16, as: SIMD8<Int16>.self)
    let lo = SIMD8<Int8>(clamping: a)
    let hi = SIMD8<Int8>(clamping: b)
    let r = SIMD16<Int8>(lowHalf: lo, highHalf: hi)
    q.storeBytes(of: r, toByteOffset: 32, as: SIMD16<Int8>.self)
    return Int32(q.load(fromByteOffset: 39, as: UInt8.self))
}
