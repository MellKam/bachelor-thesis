@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

@WasmImport("host", "log")
external fun hostLog(x: Int)

@WasmExport
fun run() {
    hostLog(42)
}

fun main() {}
