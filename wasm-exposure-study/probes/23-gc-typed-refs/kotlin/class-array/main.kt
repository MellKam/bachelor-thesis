@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

class Pair2(val a: Int, val b: Int)

var cell: Pair2 = Pair2(0, 0)
var store: IntArray = IntArray(4)

@WasmExport
fun gc_test(): Int {
    cell = Pair2(2, 3)
    store[0] = 10
    return cell.a + cell.b + store[0]
}

fun main() {}
