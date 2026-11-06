// externref has no Swift type. The only candidate is the LLVM intrinsic that produces one; the compiler crashes on it.
import Builtin

@_expose(wasm, "identity") @_cdecl("identity")
func identity(_ x: Int32) -> Int32 { _ = Builtin.int_wasm_ref_null_extern(); return x }
