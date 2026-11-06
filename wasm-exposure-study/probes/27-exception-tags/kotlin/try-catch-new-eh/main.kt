@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

class Boom(val v: Int) : Throwable()

fun boom(x: Int): Int {
    throw Boom(x)
}

@WasmExport
fun roundtrip(x: Int): Int {
    return try {
        boom(x)
    } catch (e: Boom) {
        e.v
    }
}

fun main() {}
