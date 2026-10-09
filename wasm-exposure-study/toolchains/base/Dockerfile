# Shared base image for wasm-exposure-study: Debian + the inspection tools every language uses.
# Only tools live here; each compiler is pinned in its own toolchains/<lang>/Dockerfile.
# Pins looked up from official channels on 2026-10-02.

# debian:trixie-slim, linux/amd64, pulled 2026-10-02
FROM debian@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl xz-utils libatomic1 \
 && rm -rf /var/lib/apt/lists/*

# ---------- Inspection tools ----------
# Node: latest stable release (v26.10.0, 2026-09-21), chosen over LTS for newest V8 Wasm feature support
ARG NODE_VERSION=26.10.0
ARG NODE_SHA256=ca70e9e349de048b9522abb3adc05b3bd6f43c5ffd3ec57916c7da292f59f022
# WABT 1.0.42 (2026-09-15); digest = sha256 of the GitHub release asset
ARG WABT_VERSION=1.0.42
ARG WABT_SHA256=84895407a6bbb80e918f33b16b2fb2206021c150b6bc9ff6f761263a745ab131
# wasm-tools 1.261.0 (2026-10-02): the Bytecode Alliance's parser/printer/validator. WABT 1.0.42 cannot read Wasm GC modules
# (Kotlin/Wasm, MoonBit wasm-gc), so the checker uses `wasm-tools print` to read instructions. Looked up 2026-10-08.
ARG WASM_TOOLS_VERSION=1.261.0
ARG WASM_TOOLS_SHA256=ad62b2176037e93e1348cb65d6212d128ca9f097b63d155569f25215818ff7b1
# Wasmtime v49.0.1 (2026-09-24)
ARG WASMTIME_VERSION=49.0.1
ARG WASMTIME_SHA256=c71f7e0d30a92e418f0d17db7c6d8f6664c1ad764340a1278678f4209deab534
RUN set -eux; cd /tmp; \
    curl -sSfO "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz"; \
    echo "${NODE_SHA256}  node-v${NODE_VERSION}-linux-x64.tar.xz" | sha256sum -c -; \
    mkdir -p /opt/node && tar -xJf node-v${NODE_VERSION}-linux-x64.tar.xz -C /opt/node --strip-components=1; \
    curl -sSfLO "https://github.com/WebAssembly/wabt/releases/download/${WABT_VERSION}/wabt-${WABT_VERSION}-linux-x64.tar.gz"; \
    echo "${WABT_SHA256}  wabt-${WABT_VERSION}-linux-x64.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/wabt && tar -xzf wabt-${WABT_VERSION}-linux-x64.tar.gz -C /opt/wabt --strip-components=1; \
    curl -sSfLO "https://github.com/bytecodealliance/wasmtime/releases/download/v${WASMTIME_VERSION}/wasmtime-v${WASMTIME_VERSION}-x86_64-linux.tar.xz"; \
    echo "${WASMTIME_SHA256}  wasmtime-v${WASMTIME_VERSION}-x86_64-linux.tar.xz" | sha256sum -c -; \
    mkdir -p /opt/wasmtime && tar -xJf wasmtime-v${WASMTIME_VERSION}-x86_64-linux.tar.xz -C /opt/wasmtime --strip-components=1; \
    curl -sSfLO "https://github.com/bytecodealliance/wasm-tools/releases/download/v${WASM_TOOLS_VERSION}/wasm-tools-${WASM_TOOLS_VERSION}-x86_64-linux.tar.gz"; \
    echo "${WASM_TOOLS_SHA256}  wasm-tools-${WASM_TOOLS_VERSION}-x86_64-linux.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/wasm-tools && tar -xzf wasm-tools-${WASM_TOOLS_VERSION}-x86_64-linux.tar.gz -C /opt/wasm-tools --strip-components=1; \
    rm -f /tmp/*.tar.*
# wit-bindgen 0.62.0 (Bytecode Alliance): guest bindings generator for the Component Model (C, MoonBit, ... backends); digest from the
# GitHub release asset. Used by the integration criteria (INTEGRATION.md), not by the feature probes. Looked up 2026-10-09.
ARG WIT_BINDGEN_VERSION=0.62.0
ARG WIT_BINDGEN_SHA256=3e81cc6523729f7532b4aa7968648a04abf0c711b7d1677150e9121f4e6458fe
RUN set -eux; cd /tmp; \
    curl -sSfLO "https://github.com/bytecodealliance/wit-bindgen/releases/download/v${WIT_BINDGEN_VERSION}/wit-bindgen-${WIT_BINDGEN_VERSION}-x86_64-linux.tar.gz"; \
    echo "${WIT_BINDGEN_SHA256}  wit-bindgen-${WIT_BINDGEN_VERSION}-x86_64-linux.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/wit-bindgen && tar -xzf wit-bindgen-${WIT_BINDGEN_VERSION}-x86_64-linux.tar.gz -C /opt/wit-bindgen --strip-components=1; \
    rm -f /tmp/*.tar.*
# The WASI preview-1 adapter shipped with Wasmtime v49.0.1 (reactor flavour): lets `wasm-tools component new --adapt` wrap a core module
# that imports wasi_snapshot_preview1 (Kotlin, Swift, ...) as a component. Used by the integration criteria only.
ARG WASI_ADAPTER_SHA256=efb5f04f1cc9860ff1505b193545f8eed375993d34199e247723e15958fe682d
RUN set -eux; mkdir -p /opt/wasi-adapter; \
    curl -sSfL -o /opt/wasi-adapter/wasi_snapshot_preview1.reactor.wasm "https://github.com/bytecodealliance/wasmtime/releases/download/v${WASMTIME_VERSION}/wasi_snapshot_preview1.reactor.wasm"; \
    echo "${WASI_ADAPTER_SHA256}  /opt/wasi-adapter/wasi_snapshot_preview1.reactor.wasm" | sha256sum -c -
# Binaryen version_133 (wasm-opt), for the size criterion (-Oz). Digest = sha256 of the GitHub release asset. Looked up 2026-10-09.
ARG BINARYEN_VERSION=version_133
ARG BINARYEN_SHA256=2dc9c7813f5375db93d96ead4b78222fcc3e2677bbb832297af4797782a37489
RUN set -eux; cd /tmp; \
    curl -sSfLO "https://github.com/WebAssembly/binaryen/releases/download/${BINARYEN_VERSION}/binaryen-${BINARYEN_VERSION}-x86_64-linux.tar.gz"; \
    echo "${BINARYEN_SHA256}  binaryen-${BINARYEN_VERSION}-x86_64-linux.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/binaryen && tar -xzf binaryen-${BINARYEN_VERSION}-x86_64-linux.tar.gz -C /opt/binaryen --strip-components=1; \
    rm -f /tmp/*.tar.*
# jco 1.37.0 (Bytecode Alliance): turns a component into a JS module + core modules (`jco transpile`), for the JS-bindings criterion.
RUN export PATH=/opt/node/bin:$PATH && mkdir -p /opt/jco && cd /opt/jco && npm install --ignore-scripts --no-audit --no-fund @bytecodealliance/jco@1.37.0 @bytecodealliance/preview2-shim@0.28.0 >/dev/null 2>&1 && /opt/jco/node_modules/.bin/jco --version
# Binaryen is NOT on PATH: clang's wasm driver runs `wasm-opt` after linking whenever it finds one, which would silently change every C build.
# The size criterion calls it through WASM_OPT. Likewise only the `jco` launcher is exposed (jco's .bin directory also holds a wasm-opt shim).
RUN mkdir -p /opt/jco-bin && ln -s /opt/jco/node_modules/.bin/jco /opt/jco-bin/jco
ENV WASM_OPT=/opt/binaryen/bin/wasm-opt
ENV PATH=/opt/node/bin:/opt/wabt/bin:/opt/wasmtime:/opt/wasm-tools:/opt/wit-bindgen:/opt/jco-bin:$PATH

WORKDIR /study
