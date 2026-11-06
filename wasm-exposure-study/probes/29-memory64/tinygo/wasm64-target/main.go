package main

//go:wasmexport touch
func touch() int32 { return 42 }

func main() {}
