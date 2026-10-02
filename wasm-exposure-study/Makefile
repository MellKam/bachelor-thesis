# The shared base holds only inspection tools; each language has its own explicit targets.

.PHONY: base-image rust-image rust-shell rust-version zig-image zig-shell zig-version assemblyscript-image assemblyscript-shell assemblyscript-version grain-image grain-shell grain-version moonbit-image moonbit-shell moonbit-version
base-image:
	docker build --platform linux/amd64 -t wasm-exposure-base toolchains/base

rust-image: base-image
	docker build --platform linux/amd64 -t wasm-exposure-rust toolchains/rust

rust-shell: rust-image
	docker run --rm -it -v "$(CURDIR)":/study wasm-exposure-rust bash

rust-version: rust-image
	docker run --rm wasm-exposure-rust bash -c 'rustc -vV; cargo --version; rustup target list --installed; node --version; wasm-objdump --version; wasmtime --version'

zig-image: base-image
	docker build --platform linux/amd64 -t wasm-exposure-zig toolchains/zig

zig-shell: zig-image
	docker run --rm -it -v "$(CURDIR)":/study wasm-exposure-zig bash

zig-version: zig-image
	docker run --rm wasm-exposure-zig bash -c 'zig version; zig targets | grep -c wasm; node --version; wasm-objdump --version; wasmtime --version'

assemblyscript-image: base-image
	docker build --platform linux/amd64 -t wasm-exposure-assemblyscript toolchains/assemblyscript

assemblyscript-shell: assemblyscript-image
	docker run --rm -it -v "$(CURDIR)":/study wasm-exposure-assemblyscript bash

assemblyscript-version: assemblyscript-image
	docker run --rm wasm-exposure-assemblyscript bash -c 'asc --version; npm ls --all 2>/dev/null | head; node --version; wasm-objdump --version'

grain-image: base-image
	docker build --platform linux/amd64 -t wasm-exposure-grain toolchains/grain

grain-shell: grain-image
	docker run --rm -it -v "$(CURDIR)":/study wasm-exposure-grain bash

grain-version: grain-image
	docker run --rm wasm-exposure-grain bash -c 'grain --version; node --version; wasm-objdump --version'

moonbit-image: base-image
	docker build --platform linux/amd64 -t wasm-exposure-moonbit toolchains/moonbit

moonbit-shell: moonbit-image
	docker run --rm -it -v "$(CURDIR)":/study wasm-exposure-moonbit bash

moonbit-version: moonbit-image
	docker run --rm wasm-exposure-moonbit bash -c 'moon version --all; node --version; wasm-objdump --version'
