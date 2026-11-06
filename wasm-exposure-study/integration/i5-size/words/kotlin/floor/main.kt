@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.unsafe.Pointer
import kotlin.wasm.unsafe.withScopedMemoryAllocator

// `words`, floor ABI. Kotlin/Wasm has linear memory only through the unsafe API: one block is taken once and used as the bump heap.
const val HEAP_SIZE = 1 shl 20
var heapBase = 0
var top = 16

fun ensureHeap() {
    if (heapBase == 0) withScopedMemoryAllocator { heapBase = it.allocate(HEAP_SIZE).address.toInt() }
}

@WasmExport("alloc")
fun alloc(len: Int): Int {
    ensureHeap()
    val p = heapBase + top
    top += (len + 7) and 7.inv()
    return p
}

fun isWs(c: Int) = c == 32 || c == 9 || c == 10 || c == 13

@WasmExport("analyse")
fun analyse(ptr: Int, len: Int): Int {
    ensureHeap()
    var words = 0
    var best = 0
    var bestAt = 0
    var i = 0
    while (i < len) {
        while (i < len && isWs(Pointer((ptr + i).toUInt()).loadByte().toInt())) i++
        val start = i
        while (i < len && !isWs(Pointer((ptr + i).toUInt()).loadByte().toInt())) i++
        if (i > start) {
            words++
            if (i - start > best) { best = i - start; bestAt = start }
        }
    }
    val rec = Pointer(heapBase.toUInt())
    rec.storeInt(words)
    (rec + 4).storeInt(len)
    (rec + 8).storeInt(ptr + bestAt)
    (rec + 12).storeInt(best)
    top = 16
    return heapBase
}

fun main() {}
