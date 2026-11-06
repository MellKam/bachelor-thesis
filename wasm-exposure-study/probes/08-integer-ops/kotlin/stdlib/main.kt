@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

@WasmExport fun i_add(a: Int, b: Int): Int = a + b
@WasmExport fun i_sub(a: Int, b: Int): Int = a - b
@WasmExport fun i_mul(a: Int, b: Int): Int = a * b
@WasmExport fun i_div(a: Int, b: Int): Int = a / b
@WasmExport fun i_rem(a: Int, b: Int): Int = a % b
@WasmExport fun i_clz(a: Int): Int = a.countLeadingZeroBits()
@WasmExport fun i_ctz(a: Int): Int = a.countTrailingZeroBits()
@WasmExport fun i_popcnt(a: Int): Int = a.countOneBits()
@WasmExport fun i_rotl(a: Int, n: Int): Int = a.rotateLeft(n)
@WasmExport fun i_rotr(a: Int, n: Int): Int = a.rotateRight(n)

fun main() {}
