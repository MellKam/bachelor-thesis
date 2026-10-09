package main

// `life` capstone contract: import host.random() -> i32; export memory, init, step, cells_ptr, width, height.
const W, H, N = 64, 64, 64 * 64

//go:wasmimport host random
func random() int32

var buf [2 * N]uint8
var cur int

//go:wasmexport init
func initGrid() {
	for i := 0; i < N; i++ {
		buf[i] = uint8(random() & 1)
	}
	cur = 0
}

//go:wasmexport step
func step() {
	c, nx := cur*N, (1-cur)*N
	for y := 0; y < H; y++ {
		for x := 0; x < W; x++ {
			n := uint8(0)
			for dy := 0; dy < 3; dy++ {
				for dx := 0; dx < 3; dx++ {
					if !(dy == 1 && dx == 1) {
						n += buf[c+((y+H-1+dy)%H)*W+(x+W-1+dx)%W]
					}
				}
			}
			alive := buf[c+y*W+x] != 0
			if n == 3 || (alive && n == 2) {
				buf[nx+y*W+x] = 1
			} else {
				buf[nx+y*W+x] = 0
			}
		}
	}
	cur = 1 - cur
}

//go:wasmexport cells_ptr
func cellsPtr() *uint8 { return &buf[cur*N] }

//go:wasmexport width
func width() int32 { return W }

//go:wasmexport height
func height() int32 { return H }

func main() {}
