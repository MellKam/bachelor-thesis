# The shared base holds only inspection tools; each language has its own explicit targets.

.PHONY: integration-i6 integration-rating integration-matrix integration-rust integration-zig integration-c integration-moonbit integration-moonbit-gc integration-assemblyscript integration-tinygo integration-kotlin integration-swift matrix rating recheck summary probe-rust probe-zig probe-c probe-moonbit probe-moonbit-gc probe-assemblyscript probe-tinygo probe-kotlin probe-swift check-references base-image rust-image rust-shell rust-version zig-image zig-shell zig-version assemblyscript-image assemblyscript-shell assemblyscript-version moonbit-image moonbit-shell moonbit-version tinygo-image tinygo-shell tinygo-version kotlin-image kotlin-shell kotlin-version c-image c-shell c-version swift-image swift-shell swift-version
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

moonbit-image: base-image
	docker build --platform linux/amd64 -t wasm-exposure-moonbit toolchains/moonbit

moonbit-shell: moonbit-image
	docker run --rm -it -v "$(CURDIR)":/study wasm-exposure-moonbit bash

moonbit-version: moonbit-image
	docker run --rm wasm-exposure-moonbit bash -c 'moon version --all; node --version; wasm-objdump --version'

tinygo-image: base-image
	docker build --platform linux/amd64 -t wasm-exposure-tinygo toolchains/tinygo

tinygo-shell: tinygo-image
	docker run --rm -it -v "$(CURDIR)":/study wasm-exposure-tinygo bash

tinygo-version: tinygo-image
	docker run --rm wasm-exposure-tinygo bash -c 'tinygo version; go version; node --version; wasm-objdump --version'

kotlin-image: base-image
	docker build --platform linux/amd64 -t wasm-exposure-kotlin toolchains/kotlin

kotlin-shell: kotlin-image
	docker run --rm -it -v "$(CURDIR)":/study wasm-exposure-kotlin bash

kotlin-version: kotlin-image
	docker run --rm wasm-exposure-kotlin bash -c 'kotlinc-wasm -version; java -version; node --version; wasm-objdump --version'

c-image: base-image
	docker build --platform linux/amd64 -t wasm-exposure-c toolchains/c

c-shell: c-image
	docker run --rm -it -v "$(CURDIR)":/study wasm-exposure-c bash

c-version: c-image
	docker run --rm wasm-exposure-c bash -c 'clang --version; wasm-ld --version; node --version; wasm-objdump --version'

swift-image: base-image
	docker build --platform linux/amd64 -t wasm-exposure-swift toolchains/swift

swift-shell: swift-image
	docker run --rm -it -v "$(CURDIR)":/study wasm-exposure-swift bash

swift-version: swift-image
	docker run --rm wasm-exposure-swift bash -c 'swift --version; swift sdk list; wasm-ld --version; node --version; wasm-objdump --version'

# ---- feature probes: `make probe-<lang> [FEATURES="01 02"]`, `make check-references`
probe-rust: rust-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-rust sh probes/run.sh rust $(FEATURES)
probe-zig: zig-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-zig sh probes/run.sh zig $(FEATURES)
probe-c: c-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-c sh probes/run.sh c $(FEATURES)
probe-moonbit: moonbit-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-moonbit sh probes/run.sh moonbit $(FEATURES)
probe-moonbit-gc: moonbit-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-moonbit sh probes/run.sh moonbit-gc $(FEATURES)
probe-assemblyscript: assemblyscript-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-assemblyscript sh probes/run.sh assemblyscript $(FEATURES)
probe-tinygo: tinygo-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-tinygo sh probes/run.sh tinygo $(FEATURES)
probe-kotlin: kotlin-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-kotlin sh probes/run.sh kotlin $(FEATURES)
probe-swift: swift-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-swift sh probes/run.sh swift $(FEATURES)

# ---- integration criteria (INTEGRATION.md): `make integration-<lang> [CRITERIA="I1"]`
integration-rust: rust-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-rust sh integration/run.sh rust $(CRITERIA)
integration-zig: zig-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-zig sh integration/run.sh zig $(CRITERIA)
integration-c: c-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-c sh integration/run.sh c $(CRITERIA)
integration-moonbit: moonbit-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-moonbit sh integration/run.sh moonbit $(CRITERIA)
integration-moonbit-gc: moonbit-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-moonbit sh integration/run.sh moonbit-gc $(CRITERIA)
integration-assemblyscript: assemblyscript-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-assemblyscript sh integration/run.sh assemblyscript $(CRITERIA)
integration-tinygo: tinygo-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-tinygo sh integration/run.sh tinygo $(CRITERIA)
integration-kotlin: kotlin-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-kotlin sh integration/run.sh kotlin $(CRITERIA)
integration-swift: swift-image
	docker run --rm -v "$(CURDIR)":/study wasm-exposure-swift sh integration/run.sh swift $(CRITERIA)

check-references: base-image
	docker run --rm --user $(shell id -u):$(shell id -g) -v "$(CURDIR)":/study -w /study wasm-exposure-base node check/validate-references.mjs

# ---- results: `make summary` (one line per variant), `make recheck` (re-run the checker on built binaries), `make matrix` (render results/matrix.md from results/coding.json), `make rating` (results/rating/rating.md from the same file)
summary: base-image
	docker run --rm --user $(shell id -u):$(shell id -g) -v "$(CURDIR)":/study -w /study wasm-exposure-base node check/summarise.mjs $(LANGS)

recheck: base-image
	docker run --rm --user $(shell id -u):$(shell id -g) -v "$(CURDIR)":/study -w /study wasm-exposure-base node check/recheck.mjs $(LANGS)

matrix: base-image
	docker run --rm --user $(shell id -u):$(shell id -g) -v "$(CURDIR)":/study -w /study wasm-exposure-base node check/matrix.mjs

rating: base-image
	docker run --rm --user $(shell id -u):$(shell id -g) -v "$(CURDIR)":/study -w /study wasm-exposure-base node check/rating.mjs

integration-matrix: base-image
	docker run --rm --user $(shell id -u):$(shell id -g) -v "$(CURDIR)":/study -w /study wasm-exposure-base node check/integration-report.mjs

integration-rating: integration-matrix
	docker run --rm --user $(shell id -u):$(shell id -g) -v "$(CURDIR)":/study -w /study wasm-exposure-base node check/integration-rating.mjs

# I6: toolchain footprint and cold build time of the words floor build, measured inside each image (reported, not scored)
integration-i6:
	@for l in rust zig c moonbit assemblyscript tinygo kotlin swift; do \
	  docker run --rm -v "$(CURDIR)":/study wasm-exposure-$$l sh integration/measure-i6.sh $$l; \
	done
