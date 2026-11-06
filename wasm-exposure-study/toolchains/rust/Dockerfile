# Rust toolchain for wasm-exposure-study. Starts from the shared base image
# (Debian + Node + WABT + Wasmtime, see toolchains/base/Dockerfile); build it with `make rust-image`.
# Pins looked up from official channels on 2026-10-02.
FROM wasm-exposure-base

# A host C toolchain: `-Zbuild-std` (needed for the tier-3 wasm64 target and for panic=unwind) compiles build scripts that must be
# linked for the host. It plays no part in the Wasm output. Debian packages, taken at build time.
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev && rm -rf /var/lib/apt/lists/*

# Rust stable channel manifest dated 2026-10-01
ARG RUST_VERSION=1.99.0
ARG RUST_COMMIT=b940084d7eb6a299eb4bfeb8e34901bc051e7ac4
# sha256 of https://static.rust-lang.org/dist/channel-rust-1.99.0.toml
ARG RUST_MANIFEST_SHA256=ce6dddc886364f8d786514771212cebe9b731ba82d6b859951c6b0ccc516b6a2
# rustup-init for x86_64-unknown-linux-gnu, from static.rust-lang.org/rustup/archive/<version>/
ARG RUSTUP_VERSION=1.29.1
ARG RUSTUP_INIT_SHA256=dda7234360b7f578ca8b0ddcb80145646fa61a67c1720a5abc7051b35c9fcb71

ENV RUSTUP_HOME=/opt/rust/rustup CARGO_HOME=/opt/rust/cargo PATH=/opt/rust/cargo/bin:$PATH
RUN set -eux; \
    curl -sSfo /tmp/rustup-init \
      "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init"; \
    echo "${RUSTUP_INIT_SHA256}  /tmp/rustup-init" | sha256sum -c -; \
    curl -sSfo /tmp/manifest.toml "https://static.rust-lang.org/dist/channel-rust-${RUST_VERSION}.toml"; \
    echo "${RUST_MANIFEST_SHA256}  /tmp/manifest.toml" | sha256sum -c -; \
    chmod +x /tmp/rustup-init; \
    /tmp/rustup-init -y --no-modify-path --profile minimal --default-toolchain "${RUST_VERSION}" \
      -t wasm32-unknown-unknown -t wasm32-wasip1 -t wasm32-wasip2; \
    rm /tmp/rustup-init /tmp/manifest.toml; \
    rustc -vV | grep -q "commit-hash: ${RUST_COMMIT}"

# Pinned nightly, used ONLY for probe variants that need an unstable feature (e.g. `global_asm!` on wasm32,
# `#![feature(asm_experimental_arch)]`, or `-Zbuild-std` for the tier-3 `wasm64-unknown-unknown` target, hence `rust-src`). Results from it are always flagged as requiring nightly. Not the default toolchain.
# Manifest looked up 2026-10-02: https://static.rust-lang.org/dist/2026-10-02/channel-rust-nightly.toml
ARG RUST_NIGHTLY=nightly-2026-10-02
ARG RUST_NIGHTLY_COMMIT=c36f14571
ARG RUST_NIGHTLY_MANIFEST_SHA256=50abfdf8df57de84ff7b3188b6cad2a9681a4165518712c9e504948bf896e2b3
RUN set -eux; \
    curl -sSfo /tmp/nightly.toml "https://static.rust-lang.org/dist/2026-10-02/channel-rust-nightly.toml"; \
    echo "${RUST_NIGHTLY_MANIFEST_SHA256}  /tmp/nightly.toml" | sha256sum -c -; \
    rustup toolchain install "${RUST_NIGHTLY}" --profile minimal -t wasm32-unknown-unknown -c rust-src; \
    rm /tmp/nightly.toml; \
    rustc +"${RUST_NIGHTLY}" -vV | grep -q "commit-hash: ${RUST_NIGHTLY_COMMIT}"; \
    rustc -vV | grep -q "release: ${RUST_VERSION}"

WORKDIR /study

# wasm-bindgen-cli 0.2.129 (prebuilt musl release; digest = sha256 of the GitHub release asset, looked up 2026-10-09): generates the JS glue
# for the integration criteria (INTEGRATION.md, I3). The `wasm-bindgen` crate in a project must have exactly this version.
ARG WASM_BINDGEN_VERSION=0.2.129
ARG WASM_BINDGEN_SHA256=82d12bb940e2d4e72e0d5605387fc1b8ca179044e012b620f0ce4e7440e8320e
RUN set -eux; cd /tmp; \
    curl -sSfLO "https://github.com/wasm-bindgen/wasm-bindgen/releases/download/${WASM_BINDGEN_VERSION}/wasm-bindgen-${WASM_BINDGEN_VERSION}-x86_64-unknown-linux-musl.tar.gz"; \
    echo "${WASM_BINDGEN_SHA256}  wasm-bindgen-${WASM_BINDGEN_VERSION}-x86_64-unknown-linux-musl.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/wasm-bindgen && tar -xzf wasm-bindgen-${WASM_BINDGEN_VERSION}-x86_64-unknown-linux-musl.tar.gz -C /opt/wasm-bindgen --strip-components=1; \
    rm -f /tmp/*.tar.*
ENV PATH=/opt/wasm-bindgen:$PATH
