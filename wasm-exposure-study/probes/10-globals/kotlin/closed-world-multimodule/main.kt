@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

@WasmImport("host", "base")
external fun base(): Int

var counter: Int = 0

@WasmExport
fun bump(): Int {
    counter = base() + 1
    return counter
}

fun main() {}
