package main

var buf [512]byte
var barrier byte

//go:wasmexport bulk_test
func bulkTest(n int32) int32 {
	// clear() on a slice is Go's memset; copy() is its memmove.
	region := buf[:n]
	for i := range region {
		region[i] = barrier + 5
	}
	copy(buf[256:256+n], region)
	clear(region)
	var s int32
	for _, b := range buf[256 : 256+n] {
		s += int32(b)
	}
	return s
}

func main() {}
