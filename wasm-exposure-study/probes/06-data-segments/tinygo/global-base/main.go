package main

import "unsafe"

// The linker decides where this goes.
var data = [4]byte{'W', 'A', 'S', 'M'}

//go:wasmexport data_addr
func dataAddr() uint32 { return uint32(uintptr(unsafe.Pointer(&data[0]))) }

//go:wasmexport peek
func peek(addr uint32) int32 { return int32(*(*uint8)(unsafe.Pointer(uintptr(addr)))) }

func main() {}
