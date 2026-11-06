@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

@WasmExport
fun bulk_test(n: Int): Int {
    val a = ByteArray(512)
    a.fill(5.toByte(), 0, n)
    a.copyInto(a, 256, 0, n)
    var s = 0
    for (i in 0 until n) s += a[256 + i].toInt()
    return s
}

fun main() {}
