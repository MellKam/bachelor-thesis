package main

import "unsafe"

// `words`, floor ABI: export memory, alloc(len) -> ptr, analyse(ptr, len) -> ptr to { words, bytes, longest_ptr, longest_len }.
var heap [1 << 20]byte
var top int
var record [4]uint32

//go:wasmexport alloc
func alloc(n uint32) *byte {
	p := &heap[top]
	top += (int(n) + 7) &^ 7
	return p
}

func isWS(c byte) bool { return c == ' ' || c == '\t' || c == '\n' || c == '\r' }

//go:wasmexport analyse
func analyse(ptr *byte, n uint32) *uint32 {
	s := unsafe.Slice(ptr, n)
	var words uint32
	best, bestAt, i := 0, 0, 0
	for i < len(s) {
		for i < len(s) && isWS(s[i]) {
			i++
		}
		start := i
		for i < len(s) && !isWS(s[i]) {
			i++
		}
		if i > start {
			words++
			if i-start > best {
				best, bestAt = i-start, start
			}
		}
	}
	top = 0
	record = [4]uint32{words, n, uint32(uintptr(unsafe.Pointer(ptr))) + uint32(bestAt), uint32(best)}
	return &record[0]
}

func main() {}
