package main

//go:noinline
func a(n, acc int32) int32 {
	if n == 0 {
		return acc
	}
	return b(n-1, acc+1)
}

//go:noinline
func b(n, acc int32) int32 {
	if n == 0 {
		return acc
	}
	return a(n-1, acc+1)
}

//go:wasmexport count
func count(n, acc int32) int32 { return a(n, acc) }

func main() {}
