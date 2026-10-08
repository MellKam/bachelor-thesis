package main

//go:section meta
var meta = [5]byte{'h', 'e', 'l', 'l', 'o'}

//go:wasmexport nop
func nop() { _ = meta }

func main() {}
