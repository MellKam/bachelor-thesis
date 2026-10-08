# C toolchain for wasm-exposure-study. Starts from the shared base image
# (Debian + Node + WABT + Wasmtime, see toolchains/base/Dockerfile); build it with `make c-image`.
# Pins looked up from the GitHub releases API on 2026-10-08.
FROM wasm-exposure-base

# wasi-sdk 34 (2026-08-25): upstream clang + wasm-ld (LLVM lld) + wasi-libc + compiler-rt, the standard way to compile C to
# Wasm. Chosen over the official LLVM tarball (about 2 GB) for size. The probes build freestanding
# (`--target=wasm32-unknown-unknown -nostdlib`) like the Rust and Zig raw builds; the bundled WASI libc is there for
# `--target=wasm32-wasip1` builds. Emscripten is deliberately not installed: it is an ecosystem layer, not the raw route.
ARG WASI_SDK_VERSION=34.0
# sha256 of the release asset; matches the digest GitHub publishes for it
ARG WASI_SDK_SHA256=b761e3a0721dbae9c09a0059e5fdb2bf917d1b4a8a7b430fb3b5aafb0984b2c4

RUN set -eux; cd /tmp; \
    curl -sSfLO "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_SDK_VERSION%.*}/wasi-sdk-${WASI_SDK_VERSION}-x86_64-linux.tar.gz"; \
    echo "${WASI_SDK_SHA256}  wasi-sdk-${WASI_SDK_VERSION}-x86_64-linux.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/wasi-sdk && tar -xzf wasi-sdk-${WASI_SDK_VERSION}-x86_64-linux.tar.gz -C /opt/wasi-sdk --strip-components=1; \
    rm -f /tmp/*.tar.gz
ENV WASI_SDK_PATH=/opt/wasi-sdk PATH=/opt/wasi-sdk/bin:$PATH
RUN clang --version | head -1 && wasm-ld --version

# Note: clang defaults to `wasm32-unknown-wasip1` here; freestanding builds must pass `--target=wasm32-unknown-unknown` explicitly.
# Verified in this image on 2026-10-08, e.g.:
#   clang --target=wasm32-unknown-unknown -O2 -nostdlib -Wl,--no-entry -Wl,--initial-memory=65536 -Wl,--export-memory a.c -o a.wasm

WORKDIR /study
