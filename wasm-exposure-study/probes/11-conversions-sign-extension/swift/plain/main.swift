// Int32(x) traps on NaN and out-of-range values, so the saturating conversion is written out by hand.
@_expose(wasm, "sat_trunc") @_cdecl("sat_trunc")
func sat_trunc(_ x: Double) -> Int32 {
    if x.isNaN { return 0 }
    if x >= 2147483647.0 { return Int32.max }
    if x <= -2147483648.0 { return Int32.min }
    return Int32(x)
}
@_expose(wasm, "ext8") @_cdecl("ext8") func ext8(_ x: Int32) -> Int32 { Int32(Int8(truncatingIfNeeded: x)) }
@_expose(wasm, "ext16") @_cdecl("ext16") func ext16(_ x: Int32) -> Int32 { Int32(Int16(truncatingIfNeeded: x)) }
