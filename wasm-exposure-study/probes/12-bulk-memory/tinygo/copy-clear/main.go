package main

import "unsafe"

var buf [512]byte

//go:wasmexport bulk_test
func bulkTest(n int32) int32 {
	p := unsafe.Slice(&buf[0], 512)
	for i := range p[:n] {
		p[i] = 5
	}
	copy(p[256:256+n], p[:n])
	var s int32
	for _, b := range p[256 : 256+n] {
		s += int32(*(*uint8)(unsafe.Pointer(&b)))
	}
	return s
}

func main() {}
