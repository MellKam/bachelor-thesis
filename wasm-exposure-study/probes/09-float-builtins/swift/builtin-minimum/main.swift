// Swift has no NaN-propagating min/max (Double.minimum is IEEE minNum, which LLVM expands into a longer sequence).
// The Builtin module exposes LLVM's own intrinsics by name; this is how the stdlib itself is written.
import Builtin

@_expose(wasm, "f_sqrt") @_cdecl("f_sqrt") func f_sqrt(_ x: Double) -> Double { x.squareRoot() }
@_expose(wasm, "f_min") @_cdecl("f_min") func f_min(_ x: Double, _ y: Double) -> Double { Double(Builtin.int_minimum_FPIEEE64(x._value, y._value)) }
@_expose(wasm, "f_max") @_cdecl("f_max") func f_max(_ x: Double, _ y: Double) -> Double { Double(Builtin.int_maximum_FPIEEE64(x._value, y._value)) }
@_expose(wasm, "f_ceil") @_cdecl("f_ceil") func f_ceil(_ x: Double) -> Double { x.rounded(.up) }
@_expose(wasm, "f_floor") @_cdecl("f_floor") func f_floor(_ x: Double) -> Double { x.rounded(.down) }
@_expose(wasm, "f_trunc") @_cdecl("f_trunc") func f_trunc(_ x: Double) -> Double { x.rounded(.towardZero) }
@_expose(wasm, "f_nearest") @_cdecl("f_nearest") func f_nearest(_ x: Double) -> Double { x.rounded(.toNearestOrEven) }
@_expose(wasm, "f_copysign") @_cdecl("f_copysign") func f_copysign(_ x: Double, _ y: Double) -> Double { Double(signOf: y, magnitudeOf: x) }
@_expose(wasm, "f_abs") @_cdecl("f_abs") func f_abs(_ x: Double) -> Double { x.magnitude }
