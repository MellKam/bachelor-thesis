@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

class Boom(val v: Int) : Throwable()

@WasmExport
fun rethrow_test(x: Int): Int {
    return try {
        try {
            throw Boom(x)
        } catch (e: Boom) {
            throw e // throw the caught exception again
        }
    } catch (e: Boom) {
        e.v
    }
}

fun main() {}
