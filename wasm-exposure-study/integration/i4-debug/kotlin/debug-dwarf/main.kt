@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmExport
import kotlin.wasm.WasmImport
import kotlin.wasm.unsafe.Pointer
import kotlin.wasm.unsafe.withScopedMemoryAllocator

// `life` capstone contract. The grids are one block of linear memory taken through the unsafe API.
const val W = 64
const val H = 64
const val N = W * H

@WasmImport("host", "random")
external fun random(): Int

var base = 0
var cur = 0

fun ensure() {
    if (base == 0) withScopedMemoryAllocator { base = it.allocate(2 * N).address.toInt() }
}

@WasmExport("init")
fun initGrid() {
    ensure()
    for (i in 0 until N) Pointer((base + i).toUInt()).storeByte((random() and 1).toByte())
    cur = 0
}

@WasmExport("step")
fun step() {
    ensure()
    val c = base + cur * N
    val nx = base + (1 - cur) * N
    for (y in 0 until H) for (x in 0 until W) {
        var n = 0
        for (dy in 0 until 3) for (dx in 0 until 3) {
            if (!(dy == 1 && dx == 1)) n += Pointer((c + ((y + H - 1 + dy) % H) * W + (x + W - 1 + dx) % W).toUInt()).loadByte().toInt()
        }
        val alive = Pointer((c + y * W + x).toUInt()).loadByte().toInt() != 0
        Pointer((nx + y * W + x).toUInt()).storeByte(if (n == 3 || (alive && n == 2)) 1 else 0)
    }
    cur = 1 - cur
}

@WasmExport("cells_ptr")
fun cellsPtr(): Int { ensure(); return base + cur * N }

@WasmExport("width")
fun width(): Int = W

@WasmExport("height")
fun height(): Int = H

fun main() {}

@WasmExport("crash_here")
fun crashHere() {
    error("trap")
}
