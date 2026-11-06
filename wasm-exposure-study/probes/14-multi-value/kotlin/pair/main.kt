@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

@WasmExport
fun divmod(a: Int, b: Int): Pair<Int, Int> = Pair(a / b, a % b)

fun main() {}
