package main

//go:wasmimport host base
func base() int32

var counter int32

//go:wasmexport bump
func bump() int32 {
	counter = base() + 1
	return counter
}

func main() {}
