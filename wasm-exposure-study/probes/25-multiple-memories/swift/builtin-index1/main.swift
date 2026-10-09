// The only way to name a memory other than 0 is an LLVM intrinsic's memory-index immediate. The linker still produces one memory.
import Builtin

@_expose(wasm, "copy_test") @_cdecl("copy_test")
func copyTest() -> Int32 { Int32(Builtin.int_wasm_memory_size_Int32(Int32(1)._value)) }
