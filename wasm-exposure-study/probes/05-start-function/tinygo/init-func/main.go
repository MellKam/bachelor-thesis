package main

var g int32

func init() { g = 7 }

//go:wasmexport get
func get() int32 { return g }

func main() {}
