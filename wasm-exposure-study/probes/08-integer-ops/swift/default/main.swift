@_expose(wasm, "i_add") @_cdecl("i_add") func i_add(_ a: Int32, _ b: Int32) -> Int32 { a &+ b }
@_expose(wasm, "i_sub") @_cdecl("i_sub") func i_sub(_ a: Int32, _ b: Int32) -> Int32 { a &- b }
@_expose(wasm, "i_mul") @_cdecl("i_mul") func i_mul(_ a: Int32, _ b: Int32) -> Int32 { a &* b }
@_expose(wasm, "i_div") @_cdecl("i_div") func i_div(_ a: Int32, _ b: Int32) -> Int32 { a / b }
@_expose(wasm, "i_rem") @_cdecl("i_rem") func i_rem(_ a: Int32, _ b: Int32) -> Int32 { a % b }
@_expose(wasm, "i_clz") @_cdecl("i_clz") func i_clz(_ a: Int32) -> Int32 { Int32(a.leadingZeroBitCount) }
@_expose(wasm, "i_ctz") @_cdecl("i_ctz") func i_ctz(_ a: Int32) -> Int32 { Int32(a.trailingZeroBitCount) }
@_expose(wasm, "i_popcnt") @_cdecl("i_popcnt") func i_popcnt(_ a: Int32) -> Int32 { Int32(a.nonzeroBitCount) }
// Swift has no rotate operation: the masking shifts &<< and &>> are written so that LLVM recognises a rotation.
@_expose(wasm, "i_rotl") @_cdecl("i_rotl")
func i_rotl(_ a: Int32, _ n: Int32) -> Int32 {
    let x = UInt32(bitPattern: a), k = UInt32(bitPattern: n)
    return Int32(bitPattern: (x &<< k) | (x &>> (0 &- k)))
}
@_expose(wasm, "i_rotr") @_cdecl("i_rotr")
func i_rotr(_ a: Int32, _ n: Int32) -> Int32 {
    let x = UInt32(bitPattern: a), k = UInt32(bitPattern: n)
    return Int32(bitPattern: (x &>> k) | (x &<< (0 &- k)))
}
