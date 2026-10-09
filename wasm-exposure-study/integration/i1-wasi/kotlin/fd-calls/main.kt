@file:OptIn(kotlin.wasm.ExperimentalWasmInterop::class, kotlin.wasm.unsafe.UnsafeWasmMemoryApi::class)

import kotlin.wasm.WasmImport
import kotlin.wasm.unsafe.withScopedMemoryAllocator

@WasmImport("wasi_snapshot_preview1", "fd_read")
external fun fdRead(fd: Int, iovs: Int, iovsLen: Int, nread: Int): Int

@WasmImport("wasi_snapshot_preview1", "fd_write")
external fun fdWrite(fd: Int, iovs: Int, iovsLen: Int, nwritten: Int): Int

fun main() {
    withScopedMemoryAllocator { a ->
        val iov = a.allocate(8)
        val num = a.allocate(4)
        val buf = a.allocate(4096)
        while (true) {
            iov.storeInt(buf.address.toInt())
            (iov + 4).storeInt(4096)
            if (fdRead(0, iov.address.toInt(), 1, num.address.toInt()) != 0) break
            val n = num.loadInt()
            if (n == 0) break
            (iov + 4).storeInt(n)
            if (fdWrite(1, iov.address.toInt(), 1, num.address.toInt()) != 0) break
        }
    }
}
