@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)
// kotlin.wasm.internal.unlikely is `internal` to the standard library; the compiler's own test (wasm-annotations/branchHint.kt)
// calls it after suppressing the visibility errors, which is also possible from user code.
@file:Suppress("INVISIBLE_MEMBER", "INVISIBLE_REFERENCE")

import kotlin.wasm.WasmExport
import kotlin.wasm.internal.*

@WasmExport
fun classify(x: Int): Int {
    if (unlikely(x < 0)) {
        return -1
    }
    return x * 2
}

fun main() {}
