@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

// Kotlin/Wasm keeps string literals in data segments of its own; the program cannot name or request one, and has no linear
// memory to copy it into. The exports exist so the checker can look at the module.
val text = "WASM"

@WasmExport
fun load(dst: Int) {
    text.length
}

@WasmExport
fun peek(addr: Int): Int = text[addr and 3].code

fun main() {}
