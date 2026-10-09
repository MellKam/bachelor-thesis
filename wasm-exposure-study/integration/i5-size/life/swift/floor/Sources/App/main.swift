// `life` capstone contract: import host.random() -> i32; export memory, init, step, cells_ptr, width, height.
let W = 64
let H = 64
let N = 64 * 64

// the C symbol must not be `random`: it would bind to the C library's own random() instead of the host import
@_extern(wasm, module: "host", name: "random")
@_extern(c, "host_random")
func hostRandom() -> Int32

nonisolated(unsafe) let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: 2 * 64 * 64)
nonisolated(unsafe) var cur = 0

@_expose(wasm, "init")
@_cdecl("init_grid")
func initGrid() {
    for i in 0..<N { buf[i] = UInt8(hostRandom() & 1) }
    cur = 0
}

@_expose(wasm, "step")
@_cdecl("step")
func step() {
    let c = buf + cur * N
    let nx = buf + (1 - cur) * N
    for y in 0..<H {
        for x in 0..<W {
            var n = 0
            for dy in 0..<3 {
                for dx in 0..<3 {
                    if !(dy == 1 && dx == 1) { n += Int(c[((y + H - 1 + dy) % H) * W + (x + W - 1 + dx) % W]) }
                }
            }
            let alive = c[y * W + x] != 0
            nx[y * W + x] = (n == 3 || (alive && n == 2)) ? 1 : 0
        }
    }
    cur = 1 - cur
}

@_expose(wasm, "cells_ptr")
@_cdecl("cells_ptr")
func cellsPtr() -> Int32 { Int32(truncatingIfNeeded: Int(bitPattern: buf + cur * N)) }

@_expose(wasm, "width")
@_cdecl("width")
func width() -> Int32 { Int32(W) }

@_expose(wasm, "height")
@_cdecl("height")
func height() -> Int32 { Int32(H) }
