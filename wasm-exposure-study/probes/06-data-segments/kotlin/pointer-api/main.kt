@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

import kotlin.wasm.unsafe.Pointer

val data = byteArrayOf('W'.code.toByte(), 'A'.code.toByte(), 'S'.code.toByte(), 'M'.code.toByte())

@WasmExport
fun first(): Int = data[0].toInt()

@WasmExport
fun peek(addr: Int): Int = Pointer(addr.toUInt()).loadByte().toInt() and 0xFF

fun main() {}
