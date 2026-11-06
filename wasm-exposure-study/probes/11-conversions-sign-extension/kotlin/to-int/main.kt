@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

@WasmExport fun sat_trunc(x: Double): Int = x.toInt()
@WasmExport fun ext8(x: Int): Int = x.toByte().toInt()
@WasmExport fun ext16(x: Int): Int = x.toShort().toInt()

fun main() {}
