@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

fun double(x: Int): Int = x * 2
fun plus100(x: Int): Int = x + 100

val slots: Array<(Int) -> Int> = arrayOf(::double, ::plus100)

@WasmExport
fun call_slot(slot: Int, x: Int): Int = slots[slot and 1](x)

fun main() {}
