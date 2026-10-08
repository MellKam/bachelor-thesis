@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

fun seven(): Int = 7

var g: Int = seven()

@WasmExport
fun get(): Int = g

fun main() {}
