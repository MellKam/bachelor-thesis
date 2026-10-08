package main

import "unsafe"

var data = [4]byte{'W', 'A', 'S', 'M'}

//go:wasmexport load
func load(dst uint32) {
	for i := range data {
		*(*byte)(unsafe.Pointer(uintptr(dst) + uintptr(i))) = data[i]
	}
}

//go:wasmexport peek
func peek(addr uint32) int32 { return int32(*(*uint8)(unsafe.Pointer(uintptr(addr)))) }

func main() {}
