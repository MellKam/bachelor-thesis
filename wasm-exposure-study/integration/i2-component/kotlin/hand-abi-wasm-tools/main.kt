@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.unsafe.Pointer
import kotlin.wasm.unsafe.withScopedMemoryAllocator

// The canonical ABI written by hand (Kotlin/Wasm has no component support). Linear memory exists only through the unsafe API: one block
// is taken once and used as a bump heap; the record is its first 16 bytes.
const val HEAP_SIZE = 1 shl 20
var heapBase = 0
var heapTop = 16

fun ensureHeap() {
    if (heapBase == 0) withScopedMemoryAllocator { heapBase = it.allocate(HEAP_SIZE).address.toInt() }
}

@WasmExport("cabi_realloc")
fun cabiRealloc(oldPtr: Int, oldSize: Int, align: Int, newSize: Int): Int {
    ensureHeap()
    val start = (heapTop + align - 1) and (align - 1).inv()
    if (start + newSize > HEAP_SIZE) return 0
    heapTop = start + newSize
    return heapBase + start
}

fun isWs(c: Int) = c == 32 || c == 9 || c == 10 || c == 13

@WasmExport("study:words/words@0.1.0#analyse")
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
    heapTop = 16
    return heapBase
}

fun main() {}
