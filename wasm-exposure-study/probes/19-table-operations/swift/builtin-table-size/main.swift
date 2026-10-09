// No Swift construct names a table. The only way in is an LLVM intrinsic that takes a table symbol; the compiler crashes
// (signal 11) while looking `int_wasm_table_size` up in the Builtin module.
import Builtin

@_expose(wasm, "table_ops") @_cdecl("table_ops")
func tableOps(_ n: Int32) -> Int32 {
    Int32(Builtin.int_wasm_table_size(UnsafeMutableRawPointer(bitPattern: 16)!._rawValue))
}
