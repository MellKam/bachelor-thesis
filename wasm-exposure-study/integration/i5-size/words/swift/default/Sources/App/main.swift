// `words`, floor ABI: export memory, alloc(len) -> ptr, analyse(ptr, len) -> ptr to { words, bytes, longest_ptr, longest_len }.
nonisolated(unsafe) let heap = UnsafeMutablePointer<UInt8>.allocate(capacity: 1 << 20)
nonisolated(unsafe) let record = UnsafeMutablePointer<UInt32>.allocate(capacity: 4)
nonisolated(unsafe) var top = 0

@_expose(wasm, "alloc")
@_cdecl("alloc")
func alloc(_ len: Int) -> UnsafeMutablePointer<UInt8> {
    let p = heap + top
    top += (len + 7) & ~7
    return p
}

func isWs(_ c: UInt8) -> Bool { c == 32 || c == 9 || c == 10 || c == 13 }

@_expose(wasm, "analyse")
@_cdecl("analyse")
func analyse(_ ptr: UnsafePointer<UInt8>, _ len: Int) -> UnsafeMutablePointer<UInt32> {
    var words: UInt32 = 0
    var best = 0
    var bestAt = 0
    var i = 0
    while i < len {
        while i < len && isWs(ptr[i]) { i += 1 }
        let start = i
        while i < len && !isWs(ptr[i]) { i += 1 }
        if i > start {
            words += 1
            if i - start > best { best = i - start; bestAt = start }
        }
    }
    top = 0
    record[0] = words
    record[1] = UInt32(len)
    record[2] = UInt32(UInt(bitPattern: ptr + bestAt))
    record[3] = UInt32(best)
    return record
}
