package main

import "unsafe"

// 16-byte block operations written as plain byte loops; with `-llvm-features=+simd128` LLVM may turn them into v128 loads and stores.
// Nothing in the source asks for a vector instruction, and Go has no bitselect or narrowing operation to ask for.

//go:wasmexport v_copy
func vCopy(p int32) {
	src := (*[16]byte)(unsafe.Pointer(uintptr(p)))
	dst := (*[16]byte)(unsafe.Pointer(uintptr(p) + 16))
	for i := range src {
		dst[i] = src[i]
	}
}

//go:wasmexport v_select
func vSelect(p int32) int32 {
	a := (*[16]byte)(unsafe.Pointer(uintptr(p)))
	b := (*[16]byte)(unsafe.Pointer(uintptr(p) + 16))
	m := (*[16]byte)(unsafe.Pointer(uintptr(p) + 32))
	var out [16]byte
	for i := range out {
		out[i] = (a[i] & m[i]) | (b[i] &^ m[i])
	}
	return int32(out[0])
}

//go:wasmexport v_narrow
func vNarrow(p int32) int32 {
	s := (*[8]int16)(unsafe.Pointer(uintptr(p)))
	var out [8]int8
	for i := range s {
		v := s[i]
		if v > 127 {
			v = 127
		} else if v < -128 {
			v = -128
		}
		out[i] = int8(v)
	}
	return int32(out[0])
}

func main() {}
