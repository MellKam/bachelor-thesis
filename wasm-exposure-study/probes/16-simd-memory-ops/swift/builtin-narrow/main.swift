// As `simd-type`, except the saturating narrow is the LLVM intrinsic reached through the Builtin module
// (llvm.wasm.narrow.signed.v16i8.v8i16): the clamp-and-truncate written with SIMD operators is not recognised.
import Builtin

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
    let r = Builtin.int_wasm_narrow_signed_Vec16xInt8_Vec8xInt16(
        unsafeBitCast(a, to: Builtin.Vec8xInt16.self), unsafeBitCast(b, to: Builtin.Vec8xInt16.self))
    q.storeBytes(of: unsafeBitCast(r, to: SIMD16<Int8>.self), toByteOffset: 32, as: SIMD16<Int8>.self)
    return Int32(q.load(fromByteOffset: 39, as: UInt8.self))
}
