nonisolated(unsafe) var buf = InlineArray<512, UInt8>(repeating: 0)

@_expose(wasm, "bulk_test")
@_cdecl("bulk_test")
func bulkTest(_ n: UInt32) -> UInt32 {
    withUnsafeMutablePointer(to: &buf) { arr in
        let p = UnsafeMutableRawPointer(arr)
        p.initializeMemory(as: UInt8.self, repeating: 5, count: Int(n))
        // keep the optimiser from turning copy-of-fill into a second fill
        let q = UnsafeMutableRawPointer(bitPattern: Int(bitPattern: p) ^ Int(truncatingIfNeeded: n >> 31))!
        (q + 256).copyMemory(from: q, byteCount: Int(n))
        var s: UInt32 = 0
        let r = p.assumingMemoryBound(to: UInt8.self)
        for i in 0..<Int(n) { s &+= UInt32(r[256 + i]) }
        return s
    }
}
