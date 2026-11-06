@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport

open class Animal(val a: Int)
class Dog(a: Int, val extra: Int) : Animal(a)

var animal: Animal = Animal(0)
var bytes = ByteArray(4)
var boxed: Any = 0

@WasmExport
fun gc_extra(): Int {
    animal = Dog(1, 3)
    bytes[0] = 200.toByte()
    boxed = 7
    val d = animal as Dog
    return d.extra + (boxed as Int) + (bytes[0].toInt() and 0xff)
}

fun main() {}
