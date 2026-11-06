@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

fun a(n: Int, acc: Int): Int = if (n == 0) acc else b(n - 1, acc + 1)
fun b(n: Int, acc: Int): Int = if (n == 0) acc else a(n - 1, acc + 1)

@WasmExport
fun count(n: Int, acc: Int): Int = a(n, acc)

fun main() {}
