@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

import kotlin.math.*

@WasmExport fun f_sqrt(x: Double): Double = sqrt(x)
@WasmExport fun f_min(x: Double, y: Double): Double = min(x, y)
@WasmExport fun f_max(x: Double, y: Double): Double = max(x, y)
@WasmExport fun f_ceil(x: Double): Double = ceil(x)
@WasmExport fun f_floor(x: Double): Double = floor(x)
@WasmExport fun f_trunc(x: Double): Double = truncate(x)
@WasmExport fun f_nearest(x: Double): Double = round(x)
@WasmExport fun f_copysign(x: Double, y: Double): Double = x.withSign(y)
@WasmExport fun f_abs(x: Double): Double = abs(x)

fun main() {}
