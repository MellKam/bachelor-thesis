@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

fun double(x: Int): Int = x * 2

var f: (Int) -> Int = ::double

@WasmExport
fun apply(x: Int): Int = f(x)

fun main() {}
