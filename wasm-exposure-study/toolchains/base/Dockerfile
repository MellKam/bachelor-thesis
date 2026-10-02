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
    rm -f /tmp/*.tar.*
ENV PATH=/opt/node/bin:/opt/wabt/bin:/opt/wasmtime:$PATH

WORKDIR /study
